"""
Read-side soft-delete guard for `food_logs`.

A deleted meal is never removed from Postgres — `DELETE /food-logs/{id}` stamps
`deleted_at` (migration 255) so the row survives for undo/audit. That makes
EVERY read responsible for saying `.is_("deleted_at", "null")`, and a read that
forgets silently counts meals the user already threw away.

A 2026-07 sweep found 36 of 74 `food_logs` reads missing that filter: deleted
meals were still inflating the health/nutrition scores, the logging streak, the
weekly progress email, push nudges, wrapped and XP — every surface downstream
of a food read. Patching 36 call sites fixes today's leaks and none of next
month's, so the filter is applied at the singleton PostgREST client's
`.table("food_logs")` builder (`SupabaseManager.client`) — the chokepoint every
runtime `.select()` builder is constructed from, so one install covers all of
that client's read sites instead of 36 individual patches.

KNOWN BOUNDARY — this guard only intercepts PostgREST query BUILDERS on this
client. It is NOT literally "every read of the table". It does NOT cover:
  * `db.client.rpc(...)` calls (60+ sites) — a stored-function call is opaque to
    the builder, so any SQL function that reads food_logs must carry its own
    `deleted_at IS NULL` predicate; the guard cannot reach inside it.
  * clients built independently in `scripts/` via `create_client(...)`, which
    never pass through this install.
So "every read" means every read routed through this client's `.table()` /
`.from_()` builder — the audit gate (below) covers the two remaining escape
hatches for that surface.

What the guard touches:
  * `.select()` on a guarded table  → `deleted_at is null` appended.
  * insert / update / upsert / delete, and every other table → untouched.
    Writes MUST still reach soft-deleted rows — that is how a delete happens,
    and how the idempotent re-delete flips a row back.

Opt-out, for the reads that legitimately need the deleted rows (a tombstone
read — e.g. the idempotent DELETE answering "was this already soft-deleted?",
or the bulk-import dedupe pre-filter that must see soft-deleted keys because the
unique index it protects has no `deleted_at` predicate):
  * PREFERRED — call `.include_soft_deleted()` before `.select(...)`. It states
    intent explicitly and greppably, independent of which columns the
    projection happens to mention.
  * LEGACY — name the soft-delete column as a TOP-LEVEL projection column
    (`select("id, user_id, deleted_at")`). Matched PRECISELY: a column that
    merely contains the string (`undeleted_at`) or a child table's column nested
    in an embedded resource (`food_log_edits(deleted_at)`) does NOT opt out.

Regression gate: `python scripts/audit_food_log_soft_delete.py --check`.
"""
from typing import Any, Dict

from core.logger import get_logger

logger = get_logger(__name__)

# table name -> soft-delete timestamp column. Only tables listed here are
# guarded; add a table here the moment it grows a soft-delete column, so its
# reads are correct from the first one instead of the fortieth.
SOFT_DELETED_TABLES: Dict[str, str] = {
    "food_logs": "deleted_at",
}

# Marker so a second install (test setup, re-entered singleton) doesn't wrap
# the wrapper — double wrapping would append the filter twice.
_GUARD_INSTALLED_FLAG = "_zealova_soft_delete_guard_installed"


class SoftDeleteAwareTable:
    """Proxy over postgrest's `SyncRequestBuilder` for a soft-deleted table.

    Only `select()` is intercepted, and only to append the tombstone filter
    immediately — while the builder is still fresh, so a caller's later
    `.not_.is_(...)` negation can never be consumed by our filter. Everything
    the proxy returns from `select()` is the real postgrest builder, so the
    rest of the chain (`.eq()`, `.order()`, `.maybe_single()`, `.execute()`)
    behaves exactly as it does today.
    """

    __slots__ = ("_builder", "_column", "_include_deleted")

    def __init__(self, builder: Any, column: str, include_deleted: bool = False) -> None:
        self._builder = builder
        self._column = column
        self._include_deleted = include_deleted

    def include_soft_deleted(self) -> "SoftDeleteAwareTable":
        """EXPLICIT opt-out: the next `.select(...)` will NOT get the tombstone
        filter. Use only for a deliberate tombstone read (e.g. the bulk-import
        dedupe pre-filter, which must see soft-deleted idempotency keys because
        the unique index it guards has no `deleted_at` predicate — hiding those
        keys turns a re-import of a deleted meal into a unique violation instead
        of a no-op). Preferred over naming the column in the projection because
        it declares intent without depending on the column list.
        """
        return SoftDeleteAwareTable(self._builder, self._column, include_deleted=True)

    def select(self, *columns: str, **kwargs: Any) -> Any:
        query = self._builder.select(*columns, **kwargs)
        if self._include_deleted or self._names_column(columns):
            # Caller opted out explicitly (include_soft_deleted) or named the
            # soft-delete column as a top-level projection column → it is
            # soft-delete-aware (filters itself, or deliberately wants the
            # deleted rows). Adding our filter here would break tombstone reads
            # such as the idempotent-delete lookup and the import dedupe.
            return query
        return query.is_(self._column, "null")

    def _names_column(self, columns: tuple) -> bool:
        """True only when `self._column` is a TOP-LEVEL projection column of THIS
        table — not a substring (`undeleted_at`) and not a child column nested in
        an embedded resource (`food_log_edits(deleted_at)` selects a CHILD
        table's tombstone). Splitting at paren depth 0 keeps the legacy
        name-the-column opt-out working (idempotent DELETE:
        `select("id, user_id, deleted_at")`) while closing the substring hole the
        old `self._column in str(c)` test left open.
        """
        joined = ",".join(str(c) for c in columns)
        depth = 0
        start = 0
        tokens = []
        for i, ch in enumerate(joined):
            if ch == "(":
                depth += 1
            elif ch == ")":
                depth -= 1
            elif ch == "," and depth == 0:
                tokens.append(joined[start:i])
                start = i + 1
        tokens.append(joined[start:])
        for tok in tokens:
            bare = tok.split("(", 1)[0]     # drop an embedded resource's children
            bare = bare.split("::", 1)[0]   # drop a ::cast suffix
            bare = bare.rsplit(":", 1)[-1]  # unwrap an alias:column rename
            if bare.strip() == self._column:
                return True
        return False

    def __getattr__(self, name: str) -> Any:
        # insert / update / upsert / delete and every other attribute pass
        # straight through: the guard is a READ concern. object.__getattribute__
        # (not self._builder) so a half-constructed proxy raises AttributeError
        # instead of recursing forever.
        return getattr(object.__getattribute__(self, "_builder"), name)


def install_soft_delete_guard(client: Any) -> Any:
    """Route `client.table(...)` / `client.from_(...)` through the guard.

    Instance-level rebinding (not a subclass) because supabase-py hands back a
    concrete `Client` from `create_client()`; this is the same technique the
    manager already uses to pin the service-role headers on that client.
    Idempotent — installing twice is a no-op.
    """
    if getattr(client, _GUARD_INSTALLED_FLAG, False):
        return client

    original_from = client.from_

    def _guarded_from(table_name: str) -> Any:
        builder = original_from(table_name)
        column = SOFT_DELETED_TABLES.get(table_name)
        if column is None:
            return builder
        return SoftDeleteAwareTable(builder, column)

    client.from_ = _guarded_from
    client.table = _guarded_from
    setattr(client, _GUARD_INSTALLED_FLAG, True)
    logger.info(
        "🛡️ [DB] soft-delete read guard installed for: %s",
        ", ".join(f"{t}.{c}" for t, c in sorted(SOFT_DELETED_TABLES.items())),
    )
    return client

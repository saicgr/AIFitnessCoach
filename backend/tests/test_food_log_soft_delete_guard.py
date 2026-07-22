"""
Regression tests for the `food_logs` soft-delete read guard.

A soft-deleted meal (`food_logs.deleted_at IS NOT NULL`) must never reach a
read path — it used to keep counting toward the nutrition/health scores, the
logging streak, the weekly progress email, push nudges, wrapped and XP.
The guard (core/db/soft_delete.py) is installed on the singleton PostgREST
client, so these tests pin the behaviour every one of those surfaces relies on.

No network: postgrest builds the request lazily, so we assert on the query
params of an un-executed builder.
"""
import pytest
from postgrest._sync.client import SyncPostgrestClient

from core.db.soft_delete import SoftDeleteAwareTable, install_soft_delete_guard


class _FakeSupabaseClient:
    """Stands in for supabase-py's `Client` — only `from_`/`table` matter."""

    def __init__(self):
        self._postgrest = SyncPostgrestClient("https://example.supabase.co/rest/v1")

    def from_(self, table_name: str):
        return self._postgrest.from_(table_name)

    def table(self, table_name: str):
        return self.from_(table_name)


@pytest.fixture
def client():
    return install_soft_delete_guard(_FakeSupabaseClient())


def _params(query) -> str:
    return str(query.request.params)


def test_select_gets_the_tombstone_filter(client):
    q = client.table("food_logs").select("*").eq("user_id", "u1")
    assert "deleted_at=is.null" in _params(q)


def test_star_select_with_count_is_guarded(client):
    """The streak/XP style `select("id", count="exact")` probes leaked too."""
    q = client.table("food_logs").select("id", count="exact").eq("user_id", "u1")
    assert "deleted_at=is.null" in _params(q)


def test_from_underscore_is_guarded_too(client):
    q = client.from_("food_logs").select("total_calories")
    assert "deleted_at=is.null" in _params(q)


def test_caller_naming_deleted_at_is_left_alone(client):
    """The idempotent DELETE needs the tombstones — it asks for the column."""
    q = client.table("food_logs").select("id, user_id, deleted_at").eq("id", "x")
    assert "deleted_at=is." not in _params(q)


def test_existing_explicit_filter_still_wins(client):
    """Already-correct reads keep working (the duplicate predicate ANDs)."""
    q = (
        client.table("food_logs")
        .select("logged_at")
        .eq("user_id", "u1")
        .is_("deleted_at", "null")
    )
    assert _params(q).count("deleted_at=is.null") == 2


def test_negation_of_another_column_is_not_stolen(client):
    """`.not_.is_(...)` must apply to the caller's column, not ours."""
    q = (
        client.table("food_logs")
        .select("image_url")
        .not_.is_("image_url", "null")
    )
    p = _params(q)
    assert "image_url=not.is.null" in p
    assert "deleted_at=is.null" in p


def test_writes_are_untouched(client):
    """A soft delete has to be able to write the tombstone it just filtered."""
    q = client.table("food_logs").update({"deleted_at": "now"}).eq("id", "x")
    assert "deleted_at=is.null" not in _params(q)

    ins = client.table("food_logs").insert({"user_id": "u1"})
    assert "deleted_at=is.null" not in _params(ins)


def test_other_tables_are_not_wrapped(client):
    q = client.table("workouts").select("*")
    assert "deleted_at" not in _params(q)
    assert not isinstance(client.table("workouts"), SoftDeleteAwareTable)


def test_install_is_idempotent(client):
    install_soft_delete_guard(client)
    install_soft_delete_guard(client)
    q = client.table("food_logs").select("*")
    assert _params(q).count("deleted_at=is.null") == 1

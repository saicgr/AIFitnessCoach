"""Shared fixtures for workout-import integration tests.

Integration tests mock the Supabase client + ChromaDB so they can run
without live credentials but still exercise the full pipeline code paths
(detect → dispatch → resolve → upsert → index).
"""
from __future__ import annotations

import os
from typing import Any
from unittest.mock import MagicMock
from uuid import uuid4

import pytest


@pytest.fixture
def fake_user_id():
    return uuid4()


class _FakeTable:
    """In-memory stand-in for Supabase's table builder. Captures every
    insert/upsert in `._insertions` so tests can assert on the payloads."""

    def __init__(self, store: dict):
        self._store = store
        self._last_op: str | None = None
        self._last_payload: Any = None
        self._last_conflict: str | None = None
        self._last_filters: list = []

    def insert(self, rows, **kwargs):
        self._last_op = "insert"
        self._last_payload = rows if isinstance(rows, list) else [rows]
        self._store.setdefault("inserts", []).extend(self._last_payload)
        return self

    def upsert(self, rows, on_conflict: str | None = None,
               ignore_duplicates: bool = False, **kwargs):
        self._last_op = "upsert"
        self._last_payload = rows if isinstance(rows, list) else [rows]
        self._last_conflict = on_conflict
        # Simulate ignore_duplicates by skipping rows whose hash we've seen.
        hash_key = "source_row_hash"
        seen = {h for r in self._store.get("upserts", []) for h in [r.get(hash_key)] if h}
        new_rows = [r for r in self._last_payload if r.get(hash_key) not in seen]
        self._store.setdefault("upserts", []).extend(new_rows)
        self._store["_last_upsert_new_count"] = len(new_rows)
        return self

    def select(self, *args, **kwargs):
        self._last_op = "select"
        return self

    def eq(self, col, val):
        self._last_filters.append(("eq", col, val))
        return self

    def ilike(self, col, val):
        self._last_filters.append(("ilike", col, val))
        return self

    def order(self, *args, **kwargs):
        return self

    def range(self, start, end):
        return self

    def limit(self, n):
        return self

    def update(self, patch):
        self._last_op = "update"
        self._last_payload = patch
        return self

    def delete(self):
        self._last_op = "delete"
        return self

    def execute(self):
        # For upserts: data = the rows actually inserted this call.
        if self._last_op == "upsert":
            n = self._store.get("_last_upsert_new_count", 0)
            data = self._last_payload[:n] if isinstance(self._last_payload, list) else [self._last_payload]
        elif self._last_op == "insert":
            data = self._last_payload
        else:
            data = self._store.get("select_result", [])
        return MagicMock(data=data)


class _FakeClient:
    def __init__(self):
        self._stores: dict[str, dict] = {}

    def table(self, name: str):
        store = self._stores.setdefault(name, {})
        return _FakeTable(store)


class _FakeDB:
    def __init__(self):
        self.client = _FakeClient()


@pytest.fixture
def fake_db(monkeypatch):
    db = _FakeDB()
    # Patch both common access paths so adapter + orchestrator code both see it.
    from core.db import facade as _facade
    monkeypatch.setattr(_facade, "get_supabase_db", lambda: db)
    import services.workout_import.service as _svc
    monkeypatch.setattr(_svc, "get_supabase_db", lambda: db)
    return db


@pytest.fixture
def fake_chroma(monkeypatch):
    """Patch the Chroma client so rag_indexer no-ops."""
    class _FakeCollection:
        def __init__(self):
            self._ids = []
            self._docs = []
            self._metas = []

        def add(self, ids, documents, metadatas, **kw):
            self._ids.extend(ids); self._docs.extend(documents); self._metas.extend(metadatas)

        def delete(self, ids=None, **kw):
            if ids is None:
                return
            for i in list(ids):
                if i in self._ids:
                    idx = self._ids.index(i)
                    del self._ids[idx]; del self._docs[idx]; del self._metas[idx]

        def update(self, ids, metadatas, **kw):
            for i, m in zip(ids, metadatas):
                if i in self._ids:
                    self._metas[self._ids.index(i)] = m

        def get(self, where=None, include=None, **kw):
            # Very simple where-matching — supports {"$and": [{k: v}, ...]} and flat.
            def matches(meta):
                if not where:
                    return True
                if "$and" in where:
                    return all(meta.get(list(c)[0]) == list(c.values())[0] for c in where["$and"])
                return all(meta.get(k) == v for k, v in where.items())
            ids, metas = [], []
            for i, m in zip(self._ids, self._metas):
                if matches(m):
                    ids.append(i); metas.append(m)
            return {"ids": ids, "metadatas": metas}

        def count(self):
            return len(self._ids)

    class _FakeChromaClient:
        def __init__(self):
            self.exercise_hist = _FakeCollection()
            self.cardio_hist = _FakeCollection()

        def get_user_exercise_history_collection(self):
            return self.exercise_hist

        def get_user_cardio_history_collection(self):
            return self.cardio_hist

    client = _FakeChromaClient()
    import services.workout_import.rag_indexer as _idx
    monkeypatch.setattr(_idx, "get_chroma_cloud_client", lambda: client)
    return client


@pytest.fixture
def fixtures_dir():
    return os.path.join(
        os.path.dirname(__file__), "..", "fixtures", "workout_imports"
    )

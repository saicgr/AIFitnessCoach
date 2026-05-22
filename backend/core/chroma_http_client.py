"""
Thin synchronous HTTP client for Chroma Cloud REST API v2.
Replaces the heavy chromadb Python package (~150MB) with direct HTTP calls via httpx.
"""
import asyncio
import logging
import time
import httpx
from typing import List, Dict, Optional, Any, Tuple

logger = logging.getLogger(__name__)

# Max age (seconds) of a cached name->collection mapping. Without this, a
# collection that is renamed or dropped-and-recreated upstream keeps resolving
# to a stale collection id for the lifetime of the worker. 5 minutes bounds
# that staleness while still collapsing the vast majority of repeated lookups.
_COLLECTION_CACHE_TTL = 300


class ChromaHTTPCollection:
    """Lightweight proxy for a single Chroma collection.

    Exposes the same synchronous interface that the chromadb SDK Collection
    provides (add, query, get, delete, count) so that all consumer services
    continue to work without modification.
    """

    def __init__(self, collection_id: str, name: str, client: "ChromaHTTPClient"):
        self.id = collection_id
        self.name = name
        self._client = client

    # ── helpers ───────────────────────────────────────────────────────────

    def _url(self, action: str) -> str:
        return f"{self._client._base}/{self.id}/{action}"

    def _post(self, action: str, body: Dict) -> Any:
        resp = self._client._http.post(self._url(action), json=body)
        resp.raise_for_status()
        return resp.json()

    # ── public API (synchronous, matches chromadb SDK) ────────────────────

    def add(
        self,
        ids: List[str],
        documents: Optional[List[str]] = None,
        metadatas: Optional[List[Dict]] = None,
        embeddings: Optional[List[List[float]]] = None,
    ) -> None:
        body: Dict[str, Any] = {"ids": ids}
        if documents is not None:
            body["documents"] = documents
        if metadatas is not None:
            body["metadatas"] = metadatas
        if embeddings is not None:
            body["embeddings"] = embeddings
        self._post("add", body)

    def query(
        self,
        query_texts: Optional[List[str]] = None,
        query_embeddings: Optional[List[List[float]]] = None,
        n_results: int = 10,
        where: Optional[Dict] = None,
        include: Optional[List[str]] = None,
    ) -> Dict[str, Any]:
        body: Dict[str, Any] = {"n_results": n_results}
        if query_texts is not None:
            body["query_texts"] = query_texts
        if query_embeddings is not None:
            body["query_embeddings"] = query_embeddings
        if where is not None:
            body["where"] = where
        if include is not None:
            body["include"] = include
        return self._post("query", body)

    def get(
        self,
        ids: Optional[List[str]] = None,
        where: Optional[Dict] = None,
        limit: Optional[int] = None,
        include: Optional[List[str]] = None,
    ) -> Dict[str, Any]:
        body: Dict[str, Any] = {}
        if ids is not None:
            body["ids"] = ids
        if where is not None:
            body["where"] = where
        if limit is not None:
            body["limit"] = limit
        if include is not None:
            body["include"] = include
        return self._post("get", body)

    def delete(self, ids: List[str]) -> None:
        self._post("delete", {"ids": ids})

    def count(self) -> int:
        """Get the number of documents in this collection.

        Resilient implementation: tries GET /count, falls back to POST /count,
        falls back to len(get(limit=1)) as an existence check.
        Returns -1 if all methods fail (callers should handle gracefully).
        """
        url = self._url("count")

        # Attempt 1: GET (Chroma Cloud API v2 current)
        try:
            resp = self._client._http.get(url)
            if resp.status_code == 200:
                return resp.json()
        except Exception as e:
            logger.debug(f"Chroma count GET failed: {e}")

        # Attempt 2: POST (Chroma Cloud API v2 legacy)
        try:
            resp = self._client._http.post(url, json={})
            if resp.status_code == 200:
                return resp.json()
        except Exception as e:
            logger.debug(f"Chroma count POST failed: {e}")

        # Attempt 3: Probe via get() with limit=1 to check non-empty
        try:
            result = self.get(limit=1, include=["documents"])
            ids = result.get("ids", [])
            # Can't get exact count, but can tell if non-empty
            return len(ids) if ids else 0
        except Exception as e:
            logger.debug(f"Chroma count probe failed: {e}")

        return -1

    def upsert(
        self,
        ids: List[str],
        documents: Optional[List[str]] = None,
        metadatas: Optional[List[Dict]] = None,
        embeddings: Optional[List[List[float]]] = None,
    ) -> None:
        """Upsert = delete-then-add. Chroma Cloud v2 'add' is already an
        upsert by id, so this just forwards to add()."""
        self.add(ids=ids, documents=documents, metadatas=metadatas, embeddings=embeddings)

    # ── async variants ────────────────────────────────────────────────────
    # The methods above are blocking httpx calls. Invoked from an `async def`
    # request handler they MUST run off the event loop, or a slow Chroma
    # round-trip freezes the whole worker (the 2026-05-16 incident). Always
    # prefer these `a*` variants from async code.

    async def aadd(self, *args, **kwargs) -> None:
        return await asyncio.to_thread(self.add, *args, **kwargs)

    async def aquery(self, *args, **kwargs) -> Dict[str, Any]:
        return await asyncio.to_thread(self.query, *args, **kwargs)

    async def aget(self, *args, **kwargs) -> Dict[str, Any]:
        return await asyncio.to_thread(self.get, *args, **kwargs)

    async def adelete(self, *args, **kwargs) -> None:
        return await asyncio.to_thread(self.delete, *args, **kwargs)

    async def aupsert(self, *args, **kwargs) -> None:
        return await asyncio.to_thread(self.upsert, *args, **kwargs)

    async def acount(self) -> int:
        return await asyncio.to_thread(self.count)


class ChromaHTTPClient:
    """Synchronous Chroma Cloud REST API v2 client using httpx.

    Drop-in replacement for ``chromadb.CloudClient`` that only weighs
    a few KB instead of ~150 MB.
    """

    def __init__(self, tenant: str, database: str, api_key: str, host: str = "api.trychroma.com"):
        self._tenant = tenant
        self._database = database
        self._base = (
            f"https://{host}/api/v2/tenants/{tenant}/databases/{database}/collections"
        )
        self._http = httpx.Client(
            headers={
                "Authorization": f"Bearer {api_key}",
                "X-Chroma-Token": api_key,
                "Content-Type": "application/json",
            },
            timeout=30.0,
        )
        # Cache collection name -> (cached_at, ChromaHTTPCollection) to avoid
        # repeated lookups. Entries expire after _COLLECTION_CACHE_TTL so a
        # renamed/recreated collection is not resolved to a stale id forever.
        self._collection_cache: Dict[str, Tuple[float, ChromaHTTPCollection]] = {}

    # ── collection management ─────────────────────────────────────────────

    def _cache_get(self, name: str) -> Optional["ChromaHTTPCollection"]:
        """Return a cached collection if present AND not past its max age."""
        entry = self._collection_cache.get(name)
        if entry is None:
            return None
        cached_at, col = entry
        if (time.monotonic() - cached_at) > _COLLECTION_CACHE_TTL:
            # Stale — drop it so the next lookup re-resolves the id.
            self._collection_cache.pop(name, None)
            return None
        return col

    def _cache_put(self, name: str, col: "ChromaHTTPCollection") -> None:
        """Store a collection with the current timestamp for TTL tracking."""
        self._collection_cache[name] = (time.monotonic(), col)

    def get_or_create_collection(
        self, name: str, metadata: Optional[Dict] = None
    ) -> ChromaHTTPCollection:
        cached = self._cache_get(name)
        if cached is not None:
            return cached

        resp = self._http.post(
            self._base,
            json={
                "name": name,
                "metadata": metadata or {},
                "get_or_create": True,
            },
        )
        resp.raise_for_status()
        data = resp.json()
        col = ChromaHTTPCollection(data["id"], data["name"], self)
        self._cache_put(name, col)
        return col

    def get_collection(self, name: str) -> ChromaHTTPCollection:
        cached = self._cache_get(name)
        if cached is not None:
            return cached

        resp = self._http.get(f"{self._base}/{name}")
        resp.raise_for_status()
        data = resp.json()
        col = ChromaHTTPCollection(data["id"], data["name"], self)
        self._cache_put(name, col)
        return col

    def delete_collection(self, name: str) -> None:
        resp = self._http.delete(f"{self._base}/{name}")
        resp.raise_for_status()
        self._collection_cache.pop(name, None)

    def list_collections(self) -> List["_CollectionRef"]:
        """Return lightweight objects with a ``.name`` attribute, matching
        the chromadb SDK behaviour that ``chroma_cloud.py`` relies on."""
        resp = self._http.get(self._base)
        resp.raise_for_status()
        return [_CollectionRef(c["name"]) for c in resp.json()]


class _CollectionRef:
    """Minimal stand-in so ``list_collections()`` results expose ``.name``."""
    __slots__ = ("name",)

    def __init__(self, name: str):
        self.name = name

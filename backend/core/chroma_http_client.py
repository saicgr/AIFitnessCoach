"""
Thin synchronous HTTP client for Chroma Cloud REST API v2.
Replaces the heavy chromadb Python package (~150MB) with direct HTTP calls via httpx.
"""
import httpx
from typing import List, Dict, Optional, Any


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
        return self._post("count", {})


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
        # Cache collection name -> ChromaHTTPCollection to avoid repeated lookups
        self._collection_cache: Dict[str, ChromaHTTPCollection] = {}

    # ── collection management ─────────────────────────────────────────────

    def get_or_create_collection(
        self, name: str, metadata: Optional[Dict] = None
    ) -> ChromaHTTPCollection:
        cached = self._collection_cache.get(name)
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
        self._collection_cache[name] = col
        return col

    def get_collection(self, name: str) -> ChromaHTTPCollection:
        cached = self._collection_cache.get(name)
        if cached is not None:
            return cached

        resp = self._http.get(f"{self._base}/{name}")
        resp.raise_for_status()
        data = resp.json()
        col = ChromaHTTPCollection(data["id"], data["name"], self)
        self._collection_cache[name] = col
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

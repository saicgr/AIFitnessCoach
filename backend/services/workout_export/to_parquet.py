"""
Emit a Parquet export with two tables (strength + cardio) bundled together.

Parquet is columnar and faster to re-import at scale than CSV — useful for
power users with tens of thousands of rows (coaches, multi-year pro lifters).

Implementation:
  - One `.parquet` file per table, packed into a ZIP. Arrow doesn't have
    native "multi-table single file" support without switching to IPC/Feather,
    and ZIP-of-parquet is what pandas + duckdb consume easily.
  - Column types flow from the CanonicalRow pydantic models via model_dump().
    Explicit schema would be nicer but pyarrow's auto-inference handles our
    shapes correctly for every field we export.
  - Nested fields (splits_json) are emitted as JSON strings rather than
    Arrow structs — keeps the output portable to tools that don't speak
    nested Arrow (pandas < 2.0, BigQuery LOAD, DuckDB COPY).
"""
from __future__ import annotations

import io
import json
import zipfile
from typing import Any, List, Optional
from uuid import UUID

import pyarrow as pa
import pyarrow.parquet as pq

from services.workout_import.canonical import (
    CanonicalCardioRow,
    CanonicalSetRow,
)


def _stringify_nested(row: dict) -> dict:
    """pyarrow auto-inference chokes on heterogeneous nested fields; serialize
    dict/list values to JSON strings so the column stays a flat string."""
    out = {}
    for k, v in row.items():
        if isinstance(v, (dict, list)):
            out[k] = json.dumps(v, default=str)
        elif isinstance(v, UUID):
            out[k] = str(v)
        else:
            out[k] = v
    return out


def _rows_to_table(rows: List[Any]) -> pa.Table:
    dicts = [_stringify_nested(r.model_dump(mode="json")) for r in rows]
    if not dicts:
        return pa.table({})
    return pa.Table.from_pylist(dicts)


def export_parquet(
    strength_rows: List[CanonicalSetRow],
    cardio_rows: List[CanonicalCardioRow],
    *,
    include_strength: bool = True,
    include_cardio: bool = True,
) -> bytes:
    zip_buf = io.BytesIO()
    with zipfile.ZipFile(zip_buf, "w", zipfile.ZIP_DEFLATED) as zf:
        if include_strength:
            buf = io.BytesIO()
            table = _rows_to_table(strength_rows)
            # Empty-table case: pyarrow can't write a parquet with 0 columns.
            # Emit a one-column marker so downstream readers don't error.
            if table.num_columns == 0:
                table = pa.table({"_empty": pa.array([], type=pa.int32())})
            pq.write_table(table, buf)
            zf.writestr("strength.parquet", buf.getvalue())

        if include_cardio:
            buf = io.BytesIO()
            table = _rows_to_table(cardio_rows)
            if table.num_columns == 0:
                table = pa.table({"_empty": pa.array([], type=pa.int32())})
            pq.write_table(table, buf)
            zf.writestr("cardio.parquet", buf.getvalue())

    zip_buf.seek(0)
    return zip_buf.getvalue()

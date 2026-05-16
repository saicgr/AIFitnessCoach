"""Known-good (and deliberately-bad) barcodes for the Phase-2 sweep.

Exercises GET /nutrition/barcode/{barcode}. The good barcodes are real
products in Open Food Facts; the bad ones test graceful handling.

NOTE: barcode lookup depends on the Open Food Facts public API. If OFF is
down (502/timeout), these will fail through no fault of our code — the
sweep records that distinctly.
"""
from typing import List, Tuple

# (label, barcode) — label drives the expected outcome
BARCODES: List[Tuple[str, str]] = [
    # Known-good — real products in Open Food Facts
    ("good_nutella", "3017620422003"),
    ("good_cocacola", "5449000000996"),
    ("good_oreo", "7622210449283"),
    ("good_lurpak", "5060292302701"),
    ("good_pringles", "5053990138654"),
    ("good_kelloggs", "5050083016509"),
    ("good_heinz", "0013000006408"),
    ("good_nutrigrain", "038000180507"),
    ("good_cliffbar", "722252100900"),
    ("good_chobani", "894700010045"),
    # Edge cases
    ("unknown_barcode", "0000000000000"),       # valid format, not in DB
    ("malformed_short", "123"),                  # too short → 400 expected
    ("malformed_alpha", "ABCDEFGH"),             # non-numeric → 400 expected
]


def get_barcodes() -> List[Tuple[str, str]]:
    return BARCODES


if __name__ == "__main__":
    print(f"barcodes: {len(BARCODES)}")

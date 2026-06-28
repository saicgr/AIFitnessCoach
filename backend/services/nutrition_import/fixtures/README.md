# Nutrition import fixtures

Parsers are validated against **real vendor exports** before each source is
enabled in production (Step 0 of the plan — vendor CSV columns are not
published/stable). Drop one real (anonymized) export per source here:

- `myfitnesspal_export.zip` — MFP *Settings → Export Data* (zip of 3 CSVs)
- `macrofactor_export.csv` — MacroFactor *More → Export Data / Quick Export*
- `cronometer_servings.csv` — Cronometer *Account → Export Data → Export Servings*

`test_nutrition_import.py` runs against synthetic samples that encode the
best-known headers; replace with `pytest -k real_fixture` assertions once real
files land. **Do not enable a source for users until its real-export test passes.**

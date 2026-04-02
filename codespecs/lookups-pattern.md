# Lookups Pattern

Standard process for building the Lookups tab in any analytics pipeline. The Lookups tab contains mapping tables used by Prepared Data formulas (VLOOKUPs, INDEX-MATCH).

## Process

1. **Create the Lookups tab** at the designated position in the sheet tab order
2. **Write sections sequentially** — each section occupies a column range with a header row and data rows
3. **Use `valueInputOption: RAW`** for static lookup values (hardcoded mappings)
4. **Use `valueInputOption: USER_ENTERED`** for data tables pulled from other tabs (preserves formulas if needed)
5. **Verify with read-back** — read the Lookups tab with `FORMATTED_VALUE` and confirm all sections populated

## Section Layout

Each section follows this pattern:
- **Column A of section:** Key column (the value being looked up)
- **Columns B+ of section:** Value columns (what the lookup returns)
- **Row 1:** Section header (bold)
- **Row 2:** Column headers
- **Row 3+:** Data rows

Sections are separated by empty columns to avoid range overlap.

## Verification

- All sections populated with expected row counts
- No blank key values (Column A of each section)
- Distinct values in key columns match source data distinct values
- Read-back confirms no errors

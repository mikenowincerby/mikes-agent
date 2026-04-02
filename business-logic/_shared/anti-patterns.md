# Anti-Patterns — Known Analytical Gotchas

Common mistakes in sales/pipeline analysis. Each entry documents the mistake, why it's wrong, the correct approach, and how to catch it. Referenced by `manifests/adhoc.md` and all pipeline manifests.

---

## AP-1: Stage Progression — Current Stage vs Reached Stage

**Mistake:** Inferring an opp "hit" a stage because its current stage number is higher. For example, assuming a Stage 10 (Closed-Lost) deal passed through Stages 2-6.

**Why it's wrong:** Deals can be lost or qualified-out from any stage. A deal lost at Stage 3 never reached Stages 4, 5, or 6. Inferring from current stage inflates intermediate stage counts.

**Correct approach:** "Reached Stage X" = the Stage X entry date field is not blank. Use `Reached SX` helper fields (see `../sales/data-dictionary.md`). Never infer stage progression from the current Stage field alone.

**Sanity check:** Funnel hit counts must be monotonically non-increasing: S2 >= S3 >= S4 >= S5 >= S6 >= S9. If they're not, you're likely inferring from current stage instead of entry dates.

**Example:**
```
WRONG:  hit_stage_4 = (current_stage_number >= 4)  # Counts lost-at-S3 deals as hitting S4
RIGHT:  hit_stage_4 = (stage_4_start_date != "")    # Only counts deals that actually entered S4
```

---

## AP-2: LOI / Service Swap Contamination

**Mistake:** Including LOI or Service Swap deals in pipeline, conversion, or booking analyses.

**Why it's wrong:** These are administrative entries, not real pipeline deals. LOI deals represent letters of intent that bypass the normal sales process. Service Swap deals are internal adjustments. Including them distorts pipeline counts, conversion rates, and deal values.

**Correct approach:** Filter where Opportunity Type does NOT contain "LOI" or "Service Swap". In Sheets: `=NOT(OR(ISNUMBER(SEARCH("LOI",OppType)), ISNUMBER(SEARCH("Service Swap",OppType))))`. In Python: `not ("LOI" in opp_type or "Service Swap" in opp_type)`.

**Sanity check:** Check for unexpected Opportunity Type values beyond "New Business" and "Existing Business".

---

## AP-3: Sales Cycle Timing — Including Lost Deals

**Mistake:** Including Closed-Lost or Qualified-Out deals in average sales cycle or days-to-close calculations.

**Why it's wrong:** Lost deals don't represent completed sales cycles — their timing reflects the point of loss, not natural deal completion. Including them deflates the average (lost deals tend to be shorter) and misrepresents how long deals actually take to close.

**Correct approach:** Only use Closed-Won deals for timing metrics (Average Sales Cycle, Days S2 to Close, etc.). See `../sales/data-dictionary.md` § Sales Cycle Days.

**Sanity check:** Verify the filter includes only Stage = "9. Closed-Won" for timing calculations. If the average seems unusually low, check whether lost deals are included.

---

## AP-4: Date Parsing — Ignoring Timestamps

**Mistake:** Treating raw Salesforce date fields as pure dates when they contain text with timestamps.

**Why it's wrong:** Raw dates arrive as text like `"2025-02-08 15:18:35"`. Direct date parsing fails or produces incorrect results because the time component isn't expected.

**Correct approach:**
- **Sheets:** `DATEVALUE(LEFT(cell,10))` — extracts the date portion before parsing
- **Python:** `datetime.strptime(s[:10], '%Y-%m-%d')` — slices to first 10 characters

**Sanity check:** If date parsing returns errors, nulls, or unexpected values, check whether the raw data includes timestamp suffixes.

---

## AP-5: Row Truncation — Hardcoded Range Limits

**Mistake:** Pulling data with a fixed range like `A2:Z5000` without checking how many rows the tab actually contains.

**Why it's wrong:** Source tabs can have 10K–20K+ rows (e.g., the Account tab has ~16K rows). A capped range silently drops data, producing incomplete results with no error. The agent reports a count that looks plausible but is wrong.

**Correct approach:** Always paginate in batches (e.g., 10K rows per batch) until an empty result is returned. Alternatively, use a range large enough to cover the full sheet (e.g., `A2:Z100000`). After pulling, log the total row count and sanity-check it against expectations.

**Sanity check:** If a filtered result seems low (e.g., "201 accounts" when the user expects 300+), check whether the pull range was too small. Compare total rows returned against the sheet's known size.

---

## AP-6: Hallucinated Data — Plausible But Unverified Claims

**Mistake:** Presenting numbers, dates, or facts not read from a source in the current session — e.g., "~500 accounts" from memory, a metric from a prior conversation, or a round number plugged in when a formula errored.

**Why it's wrong:** Plausible-sounding numbers don't trigger formula errors or sanity checks, making them the hardest errors to catch.

**Correct approach:** Every data point must come from a cell, query, or formula read in this session. If unavailable, say "not available."

**Sanity check:** For any number in the final output, ask: "What cell/query/formula produced this?" If you can't answer, it's hallucinated.
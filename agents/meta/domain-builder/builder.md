# Domain Builder Agent

- **Role:** Interactively scaffolds new analytics pipelines or validates existing ones
- **Trigger:** User asks to create a new pipeline, scaffold a domain, or validate an existing pipeline
- **Position:** Standalone utility agent, not part of a pipeline sequence

## References

Read before executing:
- `agents/meta/domain-builder/domain-config-schema.md` — required sections and column definitions
- `codespecs/agent-authoring.md` — dispatch file and instruction file structural constraints
- `agents/README.md` — composition patterns, sync check process
- `business-logic/pipeline-registry.md` — current registered pipelines
- `agents/meta/domain-builder/templates/` — all template files (read when ready to scaffold)

## Mode Detection

Determine mode from user request:

- **Build mode:** "create a new pipeline", "scaffold", "add a pipeline", "new domain"
- **Validate mode:** "validate the X pipeline", "check domain-config for X", "run sync check", "verify X pipeline"
- **Template validate:** "validate templates", "validate domain-builder templates"

If ambiguous, ask: "Would you like to scaffold a new pipeline or validate an existing one?"

---

## Build Mode — Conversational Design Process

### Data Source Limitations

**This system currently supports two data source types: Google Sheets and CSV/Excel files.** State this upfront at the start of any build conversation. If the user's data lives in a database, API, or other system that doesn't have a supported ingest adapter, **stop and explain:** the pipeline cannot be built until the data is exported to Sheets or CSV, or a new ingest adapter is created (see `skills/ingest/README.md` for the adapter contract).

### Interaction Rules

1. **One question per message.** Never batch multiple questions.
2. **Multiple choice preferred.** Present options when the answer space is bounded.
3. **Propose approaches with trade-offs.** When design decisions arise, present 2-3 options with your recommendation. See Design Decision Points below for when this applies.
4. **Incremental validation.** After each phase, summarize what you captured and confirm.
5. **Hard gate: no file writes until design is approved.** Collect everything, present summary, get approval, THEN write.
6. **YAGNI ruthlessly.** Flag over-engineering. Simpler pipelines are better.
7. **Data-first when possible.** If the source data is accessible, read it before asking detailed questions. Let the data inform your questions rather than asking the user to describe columns from memory.

### Phase 1: Understand the Domain + Connect to Data

**Q1 — Pipeline identity:**
"What domain is this pipeline for? I need:
- A kebab-case name (e.g., `customer-success-analytics`)
- A display name (e.g., 'Customer Success Analytics')
- A one-line description
- Trigger keywords that should route to this pipeline

For reference, existing pipelines: sales-analytics (sales, pipeline, bookings), marketing-analytics (campaign, MQL, SQL), modeling (forecast model, scoring).

**Note:** This system currently supports Google Sheets and CSV files as data sources. If your data lives elsewhere, we'll need to discuss options."

**Q2 — Data source + validation:**
"Where does the source data live?"
Options: Google Sheets / CSV file / Both / Other

**If "Other":** Stop. Explain: "The pipeline system currently supports Google Sheets and CSV ingest. To proceed, the data would need to be exported to one of these formats, or we'd need to build a custom ingest adapter. Would you like to explore either option, or is this a blocker?"

**If Sheets or CSV:** Collect source name, sheet ID or file path, tab name, read-only flag.

**Data exploration gate:** If the source is accessible (Sheets with a sheet ID, or CSV at a local path):
1. **Read the data immediately.** For Sheets, use `gws sheets values get` to read row 1 (headers) and a sample of 5-10 data rows. For CSV, read the first 10 lines.
2. **Report what you found:** column names, row count (if available), data types you can infer (numeric, date, text, categorical).
3. **Use this to inform all subsequent questions.** Instead of asking "what metrics do you track?" cold, you can ask "I see columns like [X, Y, Z] — which of these are the metrics you want to analyze?"

**If the source is NOT accessible** (user doesn't have the sheet ID handy, data isn't ready yet): Continue with the standard Q&A path. Note in the design summary that data exploration was deferred and the pipeline config may need adjustment once data is connected.

**Q3 — Metrics (data-informed when possible):**
- **If data was explored:** "From the source data, I see these columns: [list]. Which are the metrics you want to analyze? How would you group them into categories?"
- **If no data:** "What are the key metrics you want to analyze? Group them by category."
If the domain is complex, break into follow-up questions per category.
Example: "Sales has 5 categories: Pipeline, Bookings, Win/Loss, Counts, Forecast Accuracy. What categories does your domain have?"

**Q4 — Dimensions (data-informed when possible):**
- **If data was explored:** "I see these columns that look like categorical dimensions: [list]. And these date columns: [list]. Which do you slice by? What time granularity (week/month/quarter/year)?"
- **If no data:** "What dimensions do you slice the data by?" Present common patterns as reference.
Must collect: time granularity (week/month/quarter/year), date anchor column, at least one categorical dimension.

**Q5 — Business logic files:**
"Do you have existing business-logic files (metrics.md, data-dictionary.md, data-prep-rules.md), or should I scaffold placeholders?"
Options: I have existing files / Scaffold placeholders / I'll create them later

*Summarize Phase 1 before continuing. If data was explored, include a data profile summary (column count, row count, date range, key columns identified). Confirm before moving to Phase 2.*

### Phase 2: Design the Pipeline Structure

**Q6 — Lookups (data-informed when possible):**
- **If data was explored:** "Looking at the source columns, I can see [column X] has [N] distinct values like [samples]. Would a mapping table help normalize these? For example, Sales maps raw Stage values to Pipeline Category + Detail Category."
- **If no data:** "What mapping tables does your analysis need? Lookups translate raw field values into analysis-friendly categories."
Present example: "Sales has Stage Mapping (Stage → Pipeline Category), Use Case Mapping (Primary Use Case → Use Case), Fiscal Period Mapping (Month → FQ/FY). What similar mappings does your domain need?"
Collect: section number, key column, value columns, source.

**Q7 — Calculated columns (tiers):**
Walk through tier-by-tier:
- **If data was explored:** Reference actual column names: "Given your raw columns [list] and the lookups we defined, what Tier 1 columns do you need? These use raw data + Lookups (e.g., VLOOKUPs, date extractions)."
- **If no data:** Use generic examples.
Then: "**Tier 2** columns derive from Tier 1 (e.g., boolean flags, aggregations). What Tier 2 columns?"
Then: "**Tier 3** columns derive from Tier 2 (e.g., velocity calculations, compound metrics). Any Tier 3?"

**Q8 — Sanity checks:**
- **If data was explored:** Propose checks based on what you observed: "Based on the data, I'd suggest: [column X] should have only [N] distinct values (currently: [list]), [column Y] should always be positive, [date column] should be within [range]. What else?"
- **If no data:** "What checks should catch bad data or bad analysis?"
Remind: "Row count preservation and no formula errors are automatic. What domain-specific checks do you need?"
For each check, collect: name, rule, severity (hard-fail / warning / info).
Also collect: a one-line "How to Verify" for each check (e.g., "COUNTIF on Status column, expect only 3 values").

**Q9 — Deviations:**
"The standard pipeline uses single-source ingest, row-by-row formulas, and the standard Summary tab layout. Does your domain need to deviate from any of these?"
Options: None — standard patterns work / Yes, let me describe

**Q10 — Inspection overrides (optional):**
"Does this pipeline need custom inspection checks beyond the defaults in `codespecs/inspection-protocol.md`?"
Options: No — defaults are sufficient / Yes, let me describe
If yes: collect check name, stage, rule, severity.

*Summarize Phase 2 before continuing.*

### Context Inlining Defaults

When generating the Context Inlining table, use these defaults (matching established pipeline patterns):

| File | Scope |
|------|-------|
| `business-logic/_shared/formula-rules.md` | all stages |
| `business-logic/_shared/anti-patterns.md` | planner, data-prep, analysis |
| `agents/{{pipeline_name}}/domain-config.md` | all stages |
| Domain-specific data-prep-rules | data-prep |
| Domain-specific data-dictionary | data-prep |
| Domain-specific metrics | analysis, review |

Add domain-specific files collected in Q5 to the appropriate scope rows.

### Phase 3: Review + Approve

Present the full design summary organized by domain-config section:

```
## Pipeline Design Summary: {{display_name}}

### Identity
- Name: {{pipeline_name}}
- Display: {{display_name}}
- Trigger keywords: {{keywords}}

### Data Sources
[table]

### Metric Catalog
[table]

### Dimensions
[text]

### Lookups
[table]

### Calculated Column Tiers
- Tier 1: [list]
- Tier 2: [list]
- Tier 3: [list]

### Sanity Checks
[table with How to Verify column]

### Context Inlining (defaults)
[table — pre-fill with formula-rules.md, anti-patterns.md, domain-config for all stages]

### Inspection Overrides
[table or "None — uses default inspection protocol."]

### Intentional Deviations
[text or "None"]

Ready to scaffold? I'll create [n] files across agents/, .claude/agents/, and update the registry.
```

**Revision loop.** Present summary. User can request changes — update and re-present. Loop until user approves. After 3 rounds without approval, ask: "Should we proceed with the current design, or continue refining?" No hard cap — just a check-in.

### Phase 4: Scaffold Files

After user approval, write files in order. **Read back each file after writing to confirm.** If any write fails, stop and report what succeeded vs what failed. Do NOT rollback.

1. **Create directory:** `agents/{{pipeline_name}}/`
   → Checkpoint: verify directory exists
2. **Write domain-config.md** — substitute collected data into `templates/domain-config.template.md`
   → Checkpoint: read back, verify all required sections present
3. **Write instruction files** (1-planner through 4-review) — substitute into templates
   → Checkpoint: read back each, verify SHARED markers intact
4. **Write dispatch files** to `.claude/agents/` — substitute into dispatch templates
   → Checkpoint: read back each, verify frontmatter valid
5. **Update pipeline-registry.md** — add new row to the Registered Pipelines table
   → Checkpoint: read back, verify new row present
6. **Update CLAUDE.md** — add new row to Agents Index table
   → Checkpoint: read back, verify Agents Index updated
7. **Scaffold business-logic files** (if opted in at Q5):
   - `business-logic/{{domain}}/metrics.md` — metric catalog with TODO formulas
   - `business-logic/{{domain}}/data-dictionary.md` — column headers with TODO descriptions
   - `business-logic/{{domain}}/data-prep-rules.md` — tier structure with TODO rules
   - `agents/{{pipeline_name}}/domain-config.md` § Reading Order
   → Checkpoint: read back each file
8. **Run validate mode** on the new pipeline as post-scaffold integrity check

### Post-Scaffold Output

After all checkpoints pass, present:

```
## Scaffold Complete: {{display_name}}

### Files Created
[list every file written, grouped by location]

### Next Steps
1. Review `agents/{{pipeline_name}}/domain-config.md` — single source of truth
2. Fill in business-logic files (metrics.md, data-dictionary.md, data-prep-rules.md)
3. Customize instruction files if domain has unique sections (like Sales has Forecast Accuracy)
4. Run "validate the {{pipeline_name}} pipeline" to verify integrity
5. Test with a simple Express analysis
```

### Placeholder Substitution Guide

| Placeholder | Source |
|------------|--------|
| `{{pipeline_name}}` | Q1 — kebab-case name |
| `{{display_name}}` | Q1 — display name |
| `{{domain}}` | Q1 — domain folder name (usually same as pipeline_name minus `-analytics` suffix) |
| `{{trigger_description}}` | Q1 — one-line description, rephrased as trigger |
| `{{default_source}}` | Q2 — primary source name |
| `{{data_sources_table}}` | Q2 — full markdown table |
| `{{ingest_config_table}}` | Q2 — derived from source details |
| `{{metric_catalog_table}}` | Q3 — categories × metrics table |
| `{{metric_examples}}` | Q3 — comma-separated sample metric names |
| `{{dimensions_text}}` | Q4 — free text |
| `{{dimension_examples}}` | Q4 — formatted for planner question reference |
| `{{manifest_path}}` | Q5 — `agents/{{pipeline_name}}/domain-config.md` § Reading Order |
| `{{references_list}}` | Q5 — bullet list of business-logic file paths |
| `{{lookups_table}}` | Q6 — numbered sections table (for domain-config) |
| `{{lookups_table_rows}}` | Q6 — table rows for data-prep instruction (# / Section / Key Column / Value Columns / Source) |
| `{{tier_1_columns}}` | Q7 — comma-separated Tier 1 column names |
| `{{tier_2_columns}}` | Q7 — comma-separated Tier 2 column names |
| `{{tier_3_columns}}` | Q7 — comma-separated Tier 3 column names (or "None") |
| `{{sanity_checks_table}}` | Q8 — checks table for domain-config (Check / Rule / Severity) |
| `{{sanity_checks_verify_table}}` | Q8 — expanded table for review (Check / Rule / Severity / How to Verify) |
| `{{domain_scoping_check_rows}}` | Q8 — additional scoping check rows for review |
| `{{deviations}}` | Q9 — text or "None — follows all shared patterns." |
| `{{inspection_overrides}}` | Q10 — table or "None — uses default inspection protocol." |
| `{{context_inlining_table}}` | Auto-generated defaults + Q5 domain files |
| `{{reference_files_data_prep}}` | Context Inlining filtered to data-prep scope — bullet list |
| `{{reference_files_analysis}}` | Context Inlining filtered to analysis scope — bullet list |
| `{{reference_files_review}}` | Context Inlining filtered to review scope — bullet list |
| `{{domain_anti_patterns}}` | Domain-specific anti-patterns (if any from Q9) |
| `{{scoping_questions}}` | Domain-specific planner questions (if any from Q3/Q4) |

---

## Validate Mode

Read the target pipeline's files and check structural integrity. All checks are read-only.

### Check 1: Schema Compliance

Read `agents/{pipeline}/domain-config.md`. Verify all required sections exist per `agents/meta/domain-builder/domain-config-schema.md`:
- Data Sources, Metric Catalog, Dimensions, Lookups Sections, Sanity Checks, Intentional Deviations, Stages, Context Inlining, Ingest Config
- For each table section, verify required columns are present

### Check 2: File Existence

Read `## Stages` from domain-config. For each row:
- Verify instruction file exists at `agents/{pipeline}/{instruction_file}`
- If dispatch file is not `inline`, verify it exists at `.claude/agents/{dispatch_file}.md`

### Check 3: Codespec Reference Integrity

Instruction files reference shared patterns via 1-line pointers to `codespecs/` files. Verify:

1. Each instruction file references the correct codespecs for its stage type:
   - Planners → `codespecs/scoping-steps.md`, `codespecs/plan-doc-format.md`
   - Data-preps → `codespecs/lookups-pattern.md`
   - Reviews → `codespecs/inspection-protocol.md`, `codespecs/error-handling.md`, `codespecs/definitions-pattern.md`
   - Analysis → `codespecs/summary-tab-structure.md`
2. Each referenced codespec file exists
3. Each dispatch file's reference list includes the codespecs needed by its instruction file

### Check 4: Context Inlining Coverage

Read `## Context Inlining` from domain-config. For each file listed:
- Verify file exists at the specified path

Read `## References` from each instruction file. For each referenced file:
- Check if it appears in Context Inlining (or is the plan doc / instruction file itself)
- Flag files referenced in instructions but missing from Context Inlining

### Check 5: Registry Consistency

Read `business-logic/pipeline-registry.md`. Verify:
- Pipeline has an entry in the Registered Pipelines table
- Directory path matches `agents/{pipeline}/`
- Stage count matches the Stages table row count

### Check 6: CLAUDE.md Consistency

Read `CLAUDE.md`. Verify:
- Pipeline appears in the Agents Index table
- Directory and stage information is correct

### Check 7: Template Reference Integrity (templates only)

**Triggered by:** "validate templates", "validate domain-builder templates"

For each template in `agents/meta/domain-builder/templates/`:
1. Verify it contains 1-line references to the correct `codespecs/` files for its stage type (same rules as Check 3)
2. Verify no inline `<!-- SHARED: -->` markers remain — all shared content should be referenced, not duplicated

### Output Format

```
## Validation Report: {pipeline_name}

| Check | Status | Details |
|-------|--------|---------|
| Schema compliance | {PASS/WARN/FAIL} | {details} |
| File existence | {PASS/WARN/FAIL} | {details} |
| Codespec reference integrity | {PASS/WARN/FAIL} | {details} |
| Context Inlining coverage | {PASS/WARN/FAIL} | {details} |
| Registry consistency | {PASS/WARN/FAIL} | {details} |
| CLAUDE.md consistency | {PASS/WARN/FAIL} | {details} |

### Issues Found
| # | Severity | Check | Description | Suggested Fix |
|---|----------|-------|-------------|---------------|
```

---

## Design Decision Points

At these points during Q&A, present 2-3 options with trade-offs and your recommendation. Do NOT present options for every question — only at genuine decision points.

1. **Single vs multi-source ingest** (surfaces at Q2)
   - Single source: simpler, fewer join issues, faster data-prep
   - Multi-source: richer analysis, but requires cross-sheet joins and disambiguation
   - Recommend: start single-source. Add sources later.

2. **4-stage vs 3-stage pipeline** (surfaces at Q9)
   - 4-stage (planner → data-prep → analysis → review): full pipeline with quality gates
   - 3-stage (skip review): faster for simple domains where sanity checks are minimal
   - Recommend: always start with 4. Review stage cost is low and catches real errors.

3. **Tier depth** (surfaces at Q7)
   - 1-tier: simple domains with no derived columns beyond lookups
   - 2-tier: most domains (raw lookups + boolean flags or date helpers)
   - 3-tier: complex domains with velocity calculations or compound metrics
   - Recommend: 2-tier unless user describes compound metrics.

4. **Business-logic scaffolding vs manual** (surfaces at Q5)
   - Scaffold placeholders: fast start, but files need filling in
   - Manual creation: user controls structure from the start
   - Recommend: scaffold for new domains, skip for domains with existing files.

## Anti-Patterns

- **DON'T** write files before the user approves the design summary
- **DON'T** batch multiple questions in one message
- **DON'T** invent metrics or dimensions — only use what the user provides
- **DON'T** skip the incremental validation after each phase
- **DON'T** modify existing pipeline files in validate mode — read-only

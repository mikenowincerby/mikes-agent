# Scoping Steps

Standard scoping process for all analytics pipelines. The planner classifies complexity first, then runs only the steps needed.

## Step 0: Classify Complexity

Before asking ANY questions, assess the user's request against these tiers (defined in `CLAUDE.md` → Complexity Tiers):

**Express** — skip to Restate Scope if ALL of these are true:
- Metrics are stated or obvious from the question
- Dimensions are stated or obvious
- Time range is stated
- Source data is the default (Daily Data / Campaign Data)
- No ambiguity about what "success" looks like

**Standard** — ask only missing 1-2 questions, skip Strategic Recommendation:
- Most parameters are clear but 1-2 need clarification
- Strategic recommendations would not change a decision

**Deep** — run full Steps 1-4:
- Request is open-ended ("give me a full review", "analyze our pipeline")
- Multiple interpretations exist
- User explicitly asks for recommendations ("what else should I look at?")

## Questions (Step 1 — Standard and Deep only)

For **Standard**: ask ONLY the 1-2 questions whose answers are missing. Do not ask questions the user already answered.
For **Deep**: use the full question set.

| Question | Why It Matters |
|----------|---------------|
| What question are you trying to answer? | Determines metric and dimension priority |
| Which metrics? | From the pipeline's metric catalog |
| Which dimensions? | Time (week/month/FQ/FY), plus pipeline-specific dimensions |
| What time range? | Fiscal quarter, fiscal year, custom date range |
| What's the source data? | Default source or a specific Sheet ID/URL |
| What's the expected output? | Summary? Breakdown? Deal lists? Comparisons? |

## Strategic Analysis Recommendation (Step 2 — Deep only)

**Skip this step for Express and Standard.** Only run when the request is Deep complexity OR the user explicitly asks "what else should I look at?"

Apply analytical lenses from `business-logic/_shared/analysis-patterns.md`:

1. Identify the core analysis (what the user explicitly asked for)
2. Apply each analytical lens to the core ask
3. For each lens, ask: **"Given what the user is trying to understand, would this view change a decision or surface a risk?"** If yes, include it. If it's merely interesting, skip it.
4. Generate 3-5 recommended follow-up analyses beyond the core ask
5. Present everything as a single structured list for approval

**Output format:**

```
## Proposed Analysis Scope

### Core Analysis
- [metric(s)] by [dimension(s)] for [time range]
  -> This answers your primary question: [restate the question]

### Recommended Follow-Ups
1. [Metric x Dimension x Time]: [1-sentence reason -- what decision it informs or risk it surfaces]
2. [Metric x Dimension x Time]: [reason]
3. [Metric x Dimension x Time]: [reason]

Approve all, remove items by number, or add your own. One round -- then we lock scope.
```

**Rules:**
- Each recommendation must state WHY, not just WHAT
- Recommendations must use metrics and dimensions from the pipeline's metric catalog -- no invented fields
- Prefer variety across analytical lenses (don't suggest 5 of the same type)
- If the ask is already broad, reduce recommendations to 2-3 that add depth rather than breadth
- ONE round of feedback. User approves, trims, or adds. Then scope is locked.

## Restate Scope (All tiers)

Restate the full scope in plain language:

> "I'll build a [analysis name] analysis using [source] data. I'll calculate [metrics] sliced by [dimensions] for [time range]. Output: Google Sheet with Summary, [n] analysis tabs, [data tabs], Lookups, and Definitions."

- **Express/Standard:** Get a quick confirmation ("Sound right?") — one message, not a formal sign-off loop.
- **Deep:** Get explicit sign-off before proceeding.

## Validate Approach (All tiers, but presentation varies)

Run the Approach Validation checklist from `formula-rules.md`.

- **Express/Standard:** Run internally. Only surface to the user if an item FAILS. Otherwise, note "Approach validation: PASSED" in the plan doc and move on.
- **Deep:** Print the full checklist to the user with each item checked or flagged. If any item fails, revise the approach.

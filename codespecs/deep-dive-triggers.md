# Deep-Dive Triggers

Conditions that trigger follow-up analysis recommendations in the review stage. When the review agent observes any of these patterns in the completed analysis, it should recommend a specific follow-up.

## Trigger Conditions

| Trigger | Pattern | Recommended Follow-Up |
|---------|---------|----------------------|
| **Outsized contribution** | One dimension value accounts for >40% of the total | Dedicated deep-dive on that dimension value (e.g., single campaign, single rep, single segment) |
| **Trend reversal** | A metric changed direction vs prior period (up->down or down->up) | Period-over-period comparison to isolate what changed |
| **Conversion anomaly** | Conversion rate is >2x or <0.5x the average across dimension values | Investigate the outlier -- is it a data issue or a real signal? |
| **Zero or near-zero** | A dimension value shows zero activity where activity is expected | Check data completeness -- missing data vs genuinely zero |
| **High variance** | Standard deviation across dimension values is >50% of the mean | Break down further to find what drives the spread |
| **Threshold breach** | A metric crosses a known business threshold (e.g., ADS drops below $X) | Alert with context on when it last crossed and what happened |

## Output Format

Recommendations must be:
- **Specific** -- reference actual data points from the analysis ("Campaign X has 200 MQLs but zero SQLs")
- **Actionable** -- state what decision the follow-up would inform ("helps determine if targeting or content is the issue")
- **Grounded in metrics** -- use metrics from the pipeline's metric catalog, not invented measures

## Rules

- Minimum 2, maximum 3 recommendations
- Each recommendation must reference specific data from the completed analysis
- Do not recommend analyses already covered in the current deliverable

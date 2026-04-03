# Enablement Session Feedback Survey — Design Spec

## Context

Cerby runs enablement sessions for GTM teams covering topics like identity governance, product positioning, and how Cerby complements IGA solutions. There is currently no structured way to collect feedback after these sessions. This survey provides a reusable Google Form template that captures both quantitative ratings (for trending over time) and qualitative feedback (for actionable improvements). It is anonymous to encourage candid responses.

## Requirements

- **Format:** Google Form (responses export to Google Sheets)
- **Reusable:** Template form cloned or re-sent for each session
- **Anonymous:** No name collection; only GTM team identifier
- **Length:** Max 10 scored questions + context fields
- **Completion time:** 3-5 minutes
- **Question types:** Mix of Likert 1-5, multiple choice, and open-ended

## Survey Structure

### Section 1: Context (not counted toward 10-question limit)

| # | Question | Type | Required | Options / Notes |
|---|----------|------|----------|-----------------|
| C1 | Which GTM team are you on? | Dropdown | Yes | Sales, Customer Success, Customer Delivery, Marketing, SDR, Partnerships, Solutions Engineering, Other |
| C2 | Session title / topic | Short text | Yes | Pre-filled when distributing, or typed by respondent |

### Section 2: Content & Delivery (Questions 1-5)

| # | Question | Type | Required | Scale / Options |
|---|----------|------|----------|-----------------|
| 1 | The material was relevant to my role. | Linear scale (1-5) | Yes | 1 = Strongly Disagree, 5 = Strongly Agree |
| 2 | I learned something I can apply in my day-to-day work. | Linear scale (1-5) | Yes | 1 = Strongly Disagree, 5 = Strongly Agree |
| 3 | The presenter explained the topic clearly and effectively. | Linear scale (1-5) | Yes | 1 = Strongly Disagree, 5 = Strongly Agree |
| 4 | How familiar were you with this topic before the session? | Multiple choice | Yes | Not at all familiar, Slightly familiar, Moderately familiar, Very familiar |
| 5 | I would recommend this session to a colleague. | Linear scale (1-5) | Yes | 1 = Strongly Disagree, 5 = Strongly Agree |

### Section 3: Open Feedback (Questions 6-8)

| # | Question | Type | Required |
|---|----------|------|----------|
| 6 | What was the most valuable part of this session? | Paragraph text | Yes |
| 7 | What could be improved about the content or delivery? | Paragraph text | Yes |
| 8 | What other topics would you like to be enabled on? | Paragraph text | Yes |

### Section 4: Overall (Questions 9-10)

| # | Question | Type | Required | Scale / Options |
|---|----------|------|----------|-----------------|
| 9 | Overall, how would you rate this enablement session? | Linear scale (1-5) | Yes | 1 = Poor, 5 = Excellent |
| 10 | Any other comments or feedback? | Paragraph text | No | Optional catch-all |

## Implementation Plan

### Delivery: Google Forms API via gws CLI

The form will be created programmatically using `gws forms forms create` and `gws forms forms batchUpdate`.

**Steps:**
1. Create the form with title "Enablement Session Feedback"
2. Add all questions via batchUpdate (items with questionItem payloads)
3. Configure settings: anonymous (no email collection), accepting responses
4. Verify form renders correctly via the responderUri
5. Output the form URL and linked Sheets response URL

### Question Type Mapping (Forms API)

| Survey Type | Forms API Type |
|-------------|---------------|
| Dropdown | DROP_DOWN choiceQuestion |
| Short text | TEXT textQuestion (paragraph: false) |
| Linear scale (1-5) | SCALE scaleQuestion |
| Multiple choice | RADIO choiceQuestion |
| Paragraph text | TEXT textQuestion (paragraph: true) |

### Response Sheet

Google Forms automatically creates a linked Google Sheet for responses. No additional sheet setup needed. The sheet will have one column per question, with timestamps.

## Verification

1. Open the responderUri in a browser and confirm all 12 fields render correctly
2. Submit a test response and verify it appears in the linked response sheet
3. Confirm the form is set to anonymous (no email collection)
4. Confirm question 10 is optional and all others are required

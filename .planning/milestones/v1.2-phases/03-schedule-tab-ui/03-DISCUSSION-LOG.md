# Phase 3: Schedule Tab UI - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-03-25
**Phase:** 03-schedule-tab-ui
**Areas discussed:** Group height, Labels inside Activity group, Error message text

---

## Group Height

| Option | Description | Selected |
|--------|-------------|----------|
| Fixed height | Always allocates room for both rows; no dynamic resizing | ✓ |
| Dynamic height | Group box shrinks/grows when exact dropdown shows or hides | |
| Fixed height, hidden-in-place | Exact dropdown slot exists but invisible; no visual gap | |

**User's choice:** Fixed height
**Notes:** Simpler layout math; save button stays anchored to BOTTOM regardless.

---

## Labels Inside Activity Group

| Option | Description | Selected |
|--------|-------------|----------|
| Two labels | "Activity" above primary, "Specific Activity" above exact row | ✓ |
| One label | "Activity" above primary only; exact dropdown has no label | |
| No labels | Group title is sufficient; dropdowns sit inside without sub-labels | |

**User's choice:** Two labels

### Label text for second dropdown

| Option | Description | Selected |
|--------|-------------|----------|
| "Exact Activity" | Matches field name used in codebase/roadmap | |
| "Specific Activity" | More natural-language friendly | ✓ |
| Claude decides | Claude picks consistent wording | |

**User's choice:** "Specific Activity"

---

## Error Message Text

| Option | Description | Selected |
|--------|-------------|----------|
| "Select an activity." | Matches "Select a spec." pattern | ✓ |
| "Select a primary activity." | More specific, distinguishes primary from exact | |
| Claude decides | Claude picks | |

**User's choice:** "Select an activity."

---

## Claude's Discretion

- Exact WINDOW_H delta and Activity group box pixel height (derived from vertical rhythm constants)
- Unique frame names for new dropdowns
- Whether exact-activity row is a sub-frame or separate widget refs toggled via Show/Hide
- Placeholder text (established pattern: "— Select —")

## Deferred Ideas

None.

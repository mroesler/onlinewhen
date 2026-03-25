# Phase 4: Player List Column - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-03-25
**Phase:** 4 — Player List Column

---

## Area: Column sizing & window width

**Q: How should the window grow to fit the Activity column?**

Options presented:
- Widen window only — Add ~130px (800→930), Activity 130px, Time unchanged
- Widen + trim Time column — Add ~80px (800→880), Activity 130px, Time 246→116
- Trim Time, no window grow — Keep 800, split Time's 246px

**Selected:** Widen window only (with Activity at 150px → WINDOW_W 950)

---

**Q: How wide should the Activity column be?**

Options presented:
- 130px — Clips very long dungeon names by ~2 chars
- 150px — Fits all exact activity names in full, window becomes 950
- 110px — More compact, clips more

**Selected:** 150px (fits "Old Hillsbrad Foothills" in full)

---

## Area: Exact activity color

**Q: How should the exact activity (second line) be colored?**

Options presented:
- DIM — Muted gray matching secondary time text; visual hierarchy
- Same white — Equal weight both lines

**Selected:** DIM (matching timeSecondary pattern)

---

**Q: Should the exact activity alpha track the row's isPast fade?**

Options presented:
- Track row alpha — Both lines fade together at 0.38 when past
- Full opacity always — Exact line stays bright when row is faded

**Selected:** Track row alpha

---

## Area: Single-line cell alignment & cell rendering

**Q: When only primary activity is set, how should text sit in the row?**

Options presented:
- Vertically centered — Matches Name/Spec/Level columns; rows with exact have primary at top
- Always top-anchored — Consistent behavior regardless of data; primary sits high when alone

**Selected:** Always top-anchored (TOPLEFT -4 always)

---

**Q: How should the Activity cell be built in the row pool?**

Options presented:
- Always two FontStrings — Pre-create both; simpler pooling, matches timePrimary/timeSecondary
- One FontString, conditional second — Only create exact if entry has sub-types

**Selected:** Always two FontStrings

---

**Q: When sorting by Activity column, where should blank-activity rows appear?**

Options presented:
- Last — Nil entries explicitly pushed to bottom; cleaner for activity browsing
- First — Empty string < 'A'; consistent with Lua string comparison but counterintuitive

**Selected:** Last (nil-last sort logic)

---

## Summary

| Decision | Choice |
|----------|--------|
| WINDOW_W | 800 → 950 |
| Activity column width | 150px at x=420 |
| Time column shift | x=576 (unchanged width) |
| Actions column shift | x=828 (unchanged width) |
| Row pool per row | 2 FontStrings always (activityPrimary + activityExact) |
| Primary anchor | TOPLEFT -4 (always top-anchored) |
| Exact anchor | BOTTOMLEFT +4 |
| Exact color | DIM, tracks row alpha |
| Nil activity display | Blank ("") |
| Sort nil placement | Last (explicit nil-last comparator) |

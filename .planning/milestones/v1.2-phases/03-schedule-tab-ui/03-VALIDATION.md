---
phase: 3
slug: schedule-tab-ui
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-25
---

# Phase 3 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | None — WoW addon; no automated test runner configured |
| **Config file** | None |
| **Quick run command** | Manual in-client: `/reload`, open Schedule tab |
| **Full suite command** | Manual in-client smoke test (all 8 SCHED criteria) |
| **Estimated runtime** | ~2 minutes per full smoke test |

---

## Sampling Rate

- **After every task commit:** `/reload` in-client, open Schedule tab, verify task-specific behavior
- **After every plan wave:** Full manual smoke test of all 8 SCHED requirements
- **Before `/gsd:verify-work`:** Full suite must pass all 8 manual checks

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 3-01-01 | 01 | 1 | SCHED-08 | manual | — | ✅ | ⬜ pending |
| 3-02-01 | 02 | 1 | SCHED-01, SCHED-02 | manual | — | ✅ | ⬜ pending |
| 3-03-01 | 03 | 2 | SCHED-03, SCHED-04 | manual | — | ✅ | ⬜ pending |
| 3-04-01 | 04 | 2 | SCHED-05, SCHED-06, SCHED-07 | manual | — | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

None — no automated test infrastructure exists or is needed for this phase. The project has no
test runner and WoW Classic addon testing is inherently manual.

*Existing infrastructure covers all phase requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Activity group box visible in Schedule tab | SCHED-01 | WoW UI — no headless runner | Open Schedule tab; confirm "Activity" group box is visible below Date & Time |
| Primary dropdown shows 7 activities | SCHED-02 | WoW UI | Click primary dropdown; confirm 7 items in order: Normal Dungeon, Heroic Dungeon, Raid, PVP, Quest, Farm, Chill |
| Selecting dungeon/raid/pvp shows exact dropdown | SCHED-03 | WoW UI | Select Normal Dungeon, Heroic Dungeon, Raid, PVP in turn; confirm exact row appears with correct sub-types |
| Selecting quest/farm/chill hides exact dropdown | SCHED-04 | WoW UI | Select Quest, Farm, Chill in turn; confirm exact row is hidden |
| Save blocked with no activity, error shown | SCHED-05 | WoW UI | Fill all other fields; click Save with no activity selected; confirm "Select an activity." flash on Save button |
| Reset clears both activity dropdowns | SCHED-06 | WoW UI | Save a valid entry; confirm form resets; both activity fields show placeholder |
| Re-open restores activity fields | SCHED-07 | WoW UI | Save with Raid + a specific sub-type; re-open Schedule tab; confirm both fields restored and exact row visible |
| Window tall enough, no clipping | SCHED-08 | WoW UI | Open addon window; confirm Activity group box fully visible without overflow or clipping |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s (manual reload cycle)
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

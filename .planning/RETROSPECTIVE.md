# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

---

## Milestone: v1.2 — Activity System

**Shipped:** 2026-03-25
**Phases:** 5 | **Plans:** 13 | **Tasks:** 16 (tracked)

### What Was Built

- Complete TBC Classic activity data file — 7 primary activities, 45 sub-types (dungeons, raids, battlegrounds)
- 12-field backward-compatible ANN wire protocol with graceful old-client degradation
- Schedule tab activity selector with cascading exact-activity dropdown and required-field validation
- Sortable Activity column in player list with dual-line display (primary + exact)
- Second filter row with cascading primary→exact activity filters; Reset Filters integration

### What Worked

- **Vertical slice planning paid off:** Each phase delivered a fully-loadable slice — no phase left the addon in a broken state. Testing could happen after each phase.
- **Established cascade pattern from class→spec:** Reusing the existing class→spec dropdown cascade as the blueprint for activity→exact-activity meant zero UX design overhead and consistent behavior.
- **Data-first ordering:** Phase 1 (data file) before Phase 2 (protocol) before UI phases meant every subsequent phase had reliable constants to reference.
- **Wave-based sequential plans within phases:** All 5 phases modified the same core files without conflicts because plans were sequenced to depend on prior wave outputs.

### What Was Inefficient

- **Worktree commits not auto-merged to main:** Executor agents ran in isolated worktrees and committed there, but the orchestrator had to manually merge. The verifier caught this as a "gap" (main branch missing changes) before the merge happened — added a confusing verification cycle.
- **SUMMARY.md one-liner field unpopulated in some plans:** Several summaries had `"One-liner:"` as placeholder text rather than actual content, which broke the accomplishment extraction during milestone completion.
- **ROADMAP.md progress table drifted:** The Phase 4 progress entry showed "2/3" even after completion because the table wasn't updated by the phase complete CLI consistently.

### Patterns Established

- **`value = act.label` for activity filter choices** — filter compares against label strings, not IDs. Confirmed correct choice; document for future filter features.
- **Worktree isolation is safe but requires post-merge step** — parallel executor agents in worktrees need explicit merge to main before verification runs.
- **Two filter rows layout:** `columnHeaderY = -(FILTER_TOP_PAD + FILTER_H + FILTER_BOT_PAD + FILTER_H + FILTER_BOT_PAD)` is the established formula for a second filter row.

### Key Lessons

1. **Verify on main, not on worktree branches.** The verifier should be run after merging worktree branches to main, not before. Running it pre-merge produces false gaps that require a correction cycle.
2. **Keep SUMMARY.md one-liner fields populated.** The milestone complete CLI and retrospective depend on these fields. Template enforcement or a post-plan check would prevent empty `"One-liner:"` stubs.
3. **Phase progress table in ROADMAP.md needs explicit update.** The `phase complete` CLI didn't update the progress table consistently — the table drifted from reality during Phase 4.

### Cost Observations

- Model: Sonnet 4.6 throughout (executor + verifier + orchestrator)
- Sessions: Multiple sessions across 4 days
- Notable: Wave-sequential execution (1 agent at a time due to single-file dependency chain) was appropriate — no parallelism possible when all phases modified the same `TabPlayers.lua`

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Phases | Plans | Key Pattern Added |
|-----------|--------|-------|-------------------|
| v1.2 | 5 | 13 | Worktree isolation, cascade dropdown pattern |

### Recurring Issues

| Issue | Milestones Seen | Status |
|-------|----------------|--------|
| Worktree not merged before verify | v1.2 | Known — merge step needed post-execute |
| SUMMARY one-liner unpopulated | v1.2 | Known — template/enforcement gap |

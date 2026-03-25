---
phase: 1
slug: data-foundation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-24
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | None — WoW addon Lua executes inside the WoW client sandbox; no standalone test runner |
| **Config file** | none |
| **Quick run command** | Manual: load addon in WoW client, `/run print(OW.ACTIVITY.NORMAL_DUNGEON)` |
| **Full suite command** | Manual: verify all 5 success criteria in-game via `/run` commands |
| **Estimated runtime** | ~2 minutes (manual in-game checks) |

---

## Sampling Rate

- **After every task commit:** Load addon and run the relevant `/run` command for that task's requirement
- **After every plan wave:** Run all 5 manual checks in sequence
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** ~120 seconds (manual in-game)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 1-01-01 | 01 | 1 | DATA-01 | manual | `/run print(OW.ACTIVITY.NORMAL_DUNGEON)` then `/run print(OW.ACTIVITY.FAKE)` | ❌ manual-only | ⬜ pending |
| 1-01-02 | 01 | 1 | DATA-01 | manual | `/run print(type(OW.ACTIVITY_LIST))` | ❌ manual-only | ⬜ pending |
| 1-02-01 | 02 | 1 | DATA-02 | manual | `/run print(#OW.ACTIVITY_SUBS["Normal Dungeon"])` | ❌ manual-only | ⬜ pending |
| 1-02-02 | 02 | 1 | DATA-03 | manual | `/run print(#OW.ACTIVITY_SUBS["Raid"])` | ❌ manual-only | ⬜ pending |
| 1-02-03 | 02 | 1 | DATA-04 | manual | `/run print(#OW.ACTIVITY_SUBS["PVP"])` | ❌ manual-only | ⬜ pending |
| 1-02-04 | 02 | 1 | DATA-05 | manual | `/run print(OW.ACTIVITY_SUBS["Quest"] ~= nil)` | ❌ manual-only | ⬜ pending |
| 1-03-01 | 03 | 2 | DATA-01 | manual | Load addon without Lua errors; run `/ow` successfully | ❌ manual-only | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

No automated test infrastructure is required for this phase — all checks are manual in-game `/run` commands. WoW addon Lua cannot be unit-tested outside the WoW client sandbox.

*Existing infrastructure covers all phase requirements (manual-only verification).*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `OW.ACTIVITY` enum has 7 keys; unknown key raises Lua error | DATA-01 | WoW Lua sandbox — no standalone test runner | `/run print(OW.ACTIVITY.NORMAL_DUNGEON)` → should print `1`; `/run print(OW.ACTIVITY.FAKE)` → should error |
| `OW.ACTIVITY_LIST` has 7 `{id, label}` records in correct order | DATA-01 | WoW Lua sandbox | `/run for i,v in ipairs(OW.ACTIVITY_LIST) do print(i, v.id, v.label) end` |
| `OW.ACTIVITY_SUBS["Normal Dungeon"]` and `["Heroic Dungeon"]` return dungeon name lists | DATA-02 | WoW Lua sandbox | `/run print(#OW.ACTIVITY_SUBS["Normal Dungeon"])` → ≥14; `/run print(#OW.ACTIVITY_SUBS["Heroic Dungeon"])` → ≥14 |
| `OW.ACTIVITY_SUBS["Raid"]` returns 9 raid names | DATA-03 | WoW Lua sandbox | `/run print(#OW.ACTIVITY_SUBS["Raid"])` → 9 |
| `OW.ACTIVITY_SUBS["PVP"]` returns 4 battleground names | DATA-04 | WoW Lua sandbox | `/run print(#OW.ACTIVITY_SUBS["PVP"])` → 4 |
| `OW.ACTIVITY_SUBS["Quest"]`, `["Farm"]`, `["Chill"]` each return `{}` (not nil) | DATA-05 | WoW Lua sandbox | `/run print(OW.ACTIVITY_SUBS["Quest"] ~= nil)` → true; `/run print(#OW.ACTIVITY_SUBS["Quest"])` → 0 |
| `Data/Activities.lua` loads without Lua errors | DATA-01 | WoW Lua sandbox — load-order errors only visible in-game | Load addon, open chat, no red error frame |

---

## Validation Sign-Off

- [ ] All tasks have manual verify instructions or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without manual verify
- [ ] Wave 0 covers all MISSING references (N/A — all manual)
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

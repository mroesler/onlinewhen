---
phase: 2
slug: database-protocol
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-24
---

# Phase 2 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | None — no automated test framework (WoW addon; Lua runs inside game client) |
| **Config file** | None |
| **Quick run command** | Manual: `/reload` then `/dump OnlineWhenDB.myEntry` in WoW client |
| **Full suite command** | Manual two-client ANN round-trip smoke test |
| **Estimated runtime** | ~5 minutes per wave (manual) |

---

## Sampling Rate

- **After every task commit:** `/reload` UI and inspect `OnlineWhenDB.myEntry` via `/dump OnlineWhenDB.myEntry`
- **After every plan wave:** Full smoke-test: new-client → new-client ANN round-trip; old-client → new-client ANN round-trip
- **Before `/gsd:verify-work`:** All 5 success criteria from ROADMAP.md §Phase 2 verified
- **Max feedback latency:** ~5 minutes (manual in-client test)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 2-02-01 | 02 | 1 | NET-01 | manual | `/dump` split output with `;;` input in client | N/A | ⬜ pending |
| 2-02-02 | 02 | 1 | NET-01 | manual | `/dump P.SerializeANN(OnlineWhenDB.myEntry)` — verify 12 fields | N/A | ⬜ pending |
| 2-02-03 | 02 | 1 | NET-02 | manual | Send 10-field ANN from old client; inspect received entry for nil activity fields | N/A | ⬜ pending |
| 2-01-01 | 01 | 2 | NET-03 | manual | Call `OW.SaveMyEntry(...)` with activity args; `/dump OnlineWhenDB.myEntry` shows both fields | N/A | ⬜ pending |
| 2-03-01 | 03 | 3 | NET-04 | manual | Full round-trip: new-client sends ANN → peer receives and stores both activity fields | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

None — no test infrastructure to create. Existing in-client inspection tools (`/dump`, `/reload`) cover all verification.

*Existing infrastructure covers all phase requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `SerializeANN` produces 12-field string ending in `;primaryActivity;exactActivity` | NET-01 | WoW Lua client required — no standalone test runner | `/dump P.SerializeANN(OnlineWhenDB.myEntry)` after SaveMyEntry with activity args; count semicolons |
| 10-field ANN from old client accepted; `primaryActivity` and `exactActivity` nil in entry | NET-02 | Requires two-client session with mixed client versions | Log into WoW with old client on one account; inspect received peer entry for nil activity |
| `SaveMyEntry(...)` stores both activity fields in `myEntry` | NET-03 | WoW Lua client required | Call `OW.SaveMyEntry(...)` passing activity args; `/dump OnlineWhenDB.myEntry` |
| `UpsertPeer` stores activity fields from `HandleANN`-built entry | NET-04 | Requires live ANN receive from another updated client | New-client ANN send; verify receiving peer shows activity fields in stored entry |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 300s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

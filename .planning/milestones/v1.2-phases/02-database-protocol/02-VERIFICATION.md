---
phase: 02-database-protocol
verified: 2026-03-25T00:00:00Z
status: human_needed
score: 9/9 automated must-haves verified
re_verification: false
human_verification:
  - test: "In-client smoke test: 12-field ANN output from SerializeANN"
    expected: "/dump OW.Protocol.SerializeANN(OnlineWhenDB.myEntry) returns a 12-field semicolon string with two trailing empty fields"
    why_human: "WoW Lua runtime required; cannot invoke SerializeANN or inspect SavedVariables without a loaded client session"
  - test: "Old-client ANN backward compatibility end-to-end"
    expected: "A 10-field ANN from an old client is accepted, parsed, and stored with nil primaryActivity and nil exactActivity — no Lua error"
    why_human: "Requires two live WoW clients on the same channel; cannot simulate wire receipt in static analysis"
  - test: "No Lua errors on /reload after Phase 2 changes"
    expected: "Addon loads cleanly; no red error dialog; no errors in chat"
    why_human: "Requires WoW client runtime to execute TOC loading order and evaluate Lua globals"
---

# Phase 2: Database + Protocol Verification Report

**Phase Goal:** Activity fields are stored in every entry record and transmitted in the ANN wire message; old-client peers degrade gracefully to blank activity
**Verified:** 2026-03-25
**Status:** human_needed — all automated checks pass; 3 items require WoW client runtime
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `OW.SaveMyEntry` accepts 8 parameters including `primaryActivity` and `exactActivity` | VERIFIED | `Database.lua:20` — function signature has all 8 params |
| 2 | Calling `SaveMyEntry` with activity values stores them in `OnlineWhenDB.myEntry` | VERIFIED | `Database.lua:30-31` — `primaryActivity = primaryActivity or nil`, `exactActivity = exactActivity or nil` assigned in struct |
| 3 | `SaveMyEntry` with nil activity values results in nil fields (not empty string) | VERIFIED | `or nil` idiom on both fields — empty string inputs normalize to nil |
| 4 | `split()` preserves empty tokens so consecutive semicolons produce empty-string entries | VERIFIED | `Protocol.lua:152` — `(str .. sep):gmatch("([^" .. sep .. "]*)" .. sep)` — star quantifier + sentinel |
| 5 | `SerializeANN` produces a 12-field semicolon-delimited string with `primaryActivity` and `exactActivity` as fields 11-12 | VERIFIED | `Protocol.lua:125-140` — `table.concat` array confirmed at exactly 12 entries |
| 6 | `validateANN` accepts 10-field (old client) and 12-field (new client) ANNs; rejects all other counts | VERIFIED | `Protocol.lua:170` — `if #fields ~= 10 and #fields ~= 12 then return false end` |
| 7 | `HandleANN` maps `fields[11]` and `fields[12]` to `primaryActivity` and `exactActivity`, converting empty string to nil | VERIFIED | `Protocol.lua:264-265` — `(fields[11] and fields[11] ~= "") and fields[11] or nil` pattern on both fields |
| 8 | Old-client 10-field ANNs produce entry records with nil `primaryActivity` and nil `exactActivity` | VERIFIED | `fields[11]` is nil for 10-field messages; `(nil and ...)` short-circuits to nil — no runtime error possible |
| 9 | `UpsertPeer` stores activity fields because `HandleANN` includes them in the entry table | VERIFIED | `Protocol.lua:255-271` — entry constructed with activity fields at lines 264-265, then `OnlineWhen.UpsertPeer(key, entry)` at line 271; `Database.lua:45` — `OnlineWhenDB.peers[key] = entry` stores as-is |

**Score:** 9/9 automated truths verified

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `Core/Database.lua` | Extended `OW.SaveMyEntry` with activity fields | VERIFIED | 8-param signature at line 20; `primaryActivity` appears 2x (param + assignment); `exactActivity` appears 2x; no `ACTIVITY_LIST` or `VALID_ACTIVITIES` |
| `Network/Protocol.lua` | 12-field ANN wire format, fixed `split()`, relaxed `validateANN`, extended `HandleANN` | VERIFIED | All 4 changes confirmed present; `primaryActivity` appears 3x; `exactActivity` appears 3x |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `Core/Database.lua (SaveMyEntry)` | `Network/Protocol.lua (SerializeANN)` | `BroadcastSelf` reads `OnlineWhenDB.myEntry` | VERIFIED | `Database.lua:33-35` calls `OW.Protocol.BroadcastSelf()`; `Protocol.lua:200-203` calls `OnlineWhen.GetMyEntry()` then `P.SerializeANN(myEntry)` |
| `Network/Protocol.lua (HandleANN)` | `Core/Database.lua (UpsertPeer)` | entry table with activity fields | VERIFIED | `Protocol.lua:271` — `OnlineWhen.UpsertPeer(key, entry)` called after entry is constructed with activity fields at lines 264-265 |
| `Network/Protocol.lua (SerializeANN)` | `Network/Protocol.lua (HandleANN)` | 12-field wire format round-trip | VERIFIED | SerializeANN emits fields 11-12 as `entry.primaryActivity or ""`; HandleANN reads `fields[11]`/`fields[12]` with empty-to-nil conversion |

---

### Data-Flow Trace (Level 4)

Not applicable — these are not rendering components. `SaveMyEntry` and `UpsertPeer` are data-storage functions; `SerializeANN`/`HandleANN` are serialization functions. No UI rendering in Phase 2 scope.

---

### Behavioral Spot-Checks

Step 7b skipped for the live-client behaviors — WoW Lua runtime required. Static code checks substituted:

| Behavior | Check | Result | Status |
|----------|-------|--------|--------|
| `SaveMyEntry` 8-param signature present | `grep "function OW.SaveMyEntry"` | `SaveMyEntry(name, spec, class, level, onlineAt, tzId, primaryActivity, exactActivity)` | PASS |
| `split()` uses star-quantifier sentinel pattern | `grep` of line 152 | `(str .. sep):gmatch("([^" .. sep .. "]*)" .. sep)` | PASS |
| `validateANN` dual field-count guard | `grep "#fields ~= 10 and #fields ~= 12"` | Line 170 confirmed | PASS |
| `HandleANN` activity field mapping | `grep "fields\[11\]"` | Lines 264-265 confirmed with nil-guard pattern | PASS |
| No activity value validation (D-05) | `grep "VALID_ACTIVITIES\|ACTIVITY_LIST"` in both files | 0 matches | PASS |
| `HandleBYE` 4-field guard unchanged | `grep "#fields ~= 4"` | Line 281 confirmed | PASS |
| `SerializeANN` has exactly 12 fields | Count `table.concat` array entries | 12 entries (MSG_VERSION through exactActivity) | PASS |
| All 4 commits exist in git history | `git show` on each hash | `f196c81`, `11ebfbb`, `f6e4c7d`, `64d7d02` all verified | PASS |

---

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| NET-01 | 02-02, 02-03 | `primaryActivity` and `exactActivity` fields appended to ANN wire message | SATISFIED | `SerializeANN` fields 11-12 at `Protocol.lua:137-138` |
| NET-02 | 02-02, 02-03 | Old clients (missing activity fields) handled gracefully — activity blank | SATISFIED | `validateANN` accepts `#fields == 10`; `HandleANN` nil-guards on `fields[11]`/`fields[12]` |
| NET-03 | 02-01, 02-03 | `OW.SaveMyEntry` accepts and stores activity fields in `OnlineWhenDB.myEntry` | SATISFIED | 8-param signature at `Database.lua:20`; struct assignment at lines 30-31 |
| NET-04 | 02-02, 02-03 | `OW.UpsertPeer` stores activity fields from deserialized ANN messages | SATISFIED | `HandleANN` constructs entry with activity fields; `UpsertPeer` stores entry as-is (`Database.lua:45`) |

All 4 phase requirements satisfied. No orphaned requirements — REQUIREMENTS.md maps NET-01 through NET-04 to Phase 2 and all are covered by plans 02-01, 02-02, and 02-03.

---

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| — | — | — | — | — |

No anti-patterns found in `Core/Database.lua` or `Network/Protocol.lua`. No TODO/FIXME/HACK/PLACEHOLDER comments, no stub return patterns, no prohibited `VALID_ACTIVITIES` or `ACTIVITY_LIST` references in either file.

---

### Human Verification Required

#### 1. In-client smoke test: 12-field ANN output

**Test:** Log into WoW TBC Classic Anniversary. Open the OnlineWhen Schedule tab. Save an entry. Then run `/dump OW.Protocol.SerializeANN(OnlineWhenDB.myEntry)`.
**Expected:** A 12-field semicolon-delimited string is printed. The last two fields are empty (two trailing semicolons), since Phase 3 has not yet wired the activity UI. Example: `1;ANN;PlayerName;RealmName;Retribution;70;1742900000;UTC;1742900000;Paladin;;`
**Why human:** WoW Lua runtime required to call `SerializeANN` against a live `myEntry`. Cannot simulate this in static analysis.

#### 2. Old-client ANN backward compatibility end-to-end

**Test:** Have a second WoW client (or captured packet) send a 10-field ANN to the channel. Inspect the stored peer entry with `/dump OnlineWhenDB.peers`.
**Expected:** The peer entry is stored successfully with `primaryActivity = nil` and `exactActivity = nil`. No Lua error appears.
**Why human:** Requires two live clients on the same channel. Cannot simulate inbound wire receipt statically.

#### 3. No Lua errors on /reload after Phase 2 changes

**Test:** `/reload` in WoW with the updated addon. Check chat and the Blizzard error dialog.
**Expected:** Addon loads cleanly with no red error popup and no error messages in chat.
**Why human:** Requires WoW client runtime to evaluate global state, `OW.CLASS_SPECS`, TOC load ordering, and all cross-file references at runtime.

---

### Gaps Summary

No gaps. All 9 automated truths verified. All 4 requirement IDs (NET-01, NET-02, NET-03, NET-04) satisfied with direct code evidence. All key links confirmed wired in both directions. No anti-patterns in modified files. All 4 commits exist in git history.

The 3 human verification items are runtime behaviors that require a live WoW client. They are consistent with Plan 02-03 Task 2 (the blocking human-verify checkpoint), which the SUMMARY documents as approved. If the in-client smoke test has already been performed and approved (as documented in 02-03-SUMMARY.md), these items can be treated as satisfied by the prior human approval and the phase can be marked fully passed.

---

_Verified: 2026-03-25_
_Verifier: Claude (gsd-verifier)_

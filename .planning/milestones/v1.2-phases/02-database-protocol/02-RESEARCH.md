# Phase 2: Database + Protocol - Research

**Researched:** 2026-03-24
**Domain:** Lua WoW addon — SavedVariables schema extension + wire protocol serialization
**Confidence:** HIGH

## Summary

Phase 2 extends two existing Lua modules: `Core/Database.lua` gains two new optional parameters on `OW.SaveMyEntry`, and `Network/Protocol.lua` gains a backward-compatible 12-field ANN wire format. The work is purely additive — no existing behavior is removed, and old-client peers (10-field ANN) remain fully supported.

The core technical challenge is the `split()` function bug: the current `gmatch("([^;]+)")` pattern silently drops empty tokens, which would cause `primaryActivity = ""` to vanish and leave `fields[11]` pointing at the wrong value. Decision D-01 fixes this with a sentinel-append pattern: `(str..";"):gmatch("([^;]*);")`. This fix must land before any field-index work in `HandleANN`.

The secondary challenge is `validateANN`'s hardcoded `#fields ~= 10` guard. STATE.md documents this explicitly: the fix is `#fields ~= 10 and #fields ~= 12` (or equivalently `#fields < 10 or (#fields ~= 10 and #fields ~= 12)`). Decision D-03 codifies the exact acceptance rule: 10 or 12 fields only; any other count is rejected.

**Primary recommendation:** Fix `split()` first (Plan 02-02), then extend `SerializeANN` and `HandleANN`, then extend `SaveMyEntry` (Plan 02-01) — this ordering avoids a window where the serializer produces 12 fields but the receiver cannot yet parse them.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Fix the `split()` function in `Protocol.lua` to preserve empty tokens. The current `gmatch("([^;]+)")` skips empty fields — change to `(str..";"):gmatch("([^;]*);")` so that consecutive separators (`;;`) yield empty-string entries rather than being silently dropped.
- **D-02:** New-client ANNs **always serialize as 12 fields**. When `primaryActivity` or `exactActivity` is nil/unset, serialize as empty string `""`. Format: `1;ANN;Name;Realm;Spec;Level;OnlineAtUTC;TzId;UpdatedUTC;Class;primaryActivity;exactActivity`
- **D-03:** `validateANN` must accept **10 or 12 fields** — 10 = old client (treat activity as nil); 12 = new client. Any other count is rejected.
- **D-04:** When mapping deserialized fields to entry table, empty string → nil: `primaryActivity = fields[11] ~= "" and fields[11] or nil` / `exactActivity = fields[12] ~= "" and fields[12] or nil`
- **D-05:** Do **not** validate activity field values against `OW.ACTIVITY_LIST`. Accept any non-empty string — pass through as-is.

### Claude's Discretion

- Exact Lua pattern syntax for the fixed split (pattern shown in D-01 is the decision; minor syntax variations acceptable as long as empty tokens are preserved)
- Whether to inline the activity-field mapping in `HandleANN` or extract a helper

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| NET-01 | `primaryActivity` and `exactActivity` fields appended to the ANN wire message | D-02: `SerializeANN` appends two fields; `(str..";"):gmatch(...)` fix enables empty-field round-trip |
| NET-02 | Old clients (missing activity fields) are handled gracefully — activity treated as blank | D-03: `validateANN` accepts 10 or 12; D-04: empty string → nil mapping |
| NET-03 | `OW.SaveMyEntry` accepts and stores activity fields in `OnlineWhenDB.myEntry` | `SaveMyEntry` is a simple struct assignment — add two params and two table keys |
| NET-04 | `OW.UpsertPeer` stores activity fields from deserialized ANN messages | `UpsertPeer` stores the entry as-is; activity fields just need to be present when `HandleANN` builds the entry table |
</phase_requirements>

## Standard Stack

### Core

This phase is pure Lua for a WoW TBC Classic Anniversary addon. There are no external libraries, package managers, or build tools — the "stack" is the WoW addon API and standard Lua 5.1 string/table operations.

| Component | Version | Purpose |
|-----------|---------|---------|
| Lua | 5.1 (WoW embedded) | Language for all addon logic |
| WoW SavedVariables | TBC Classic API | Persistent table written/read as `OnlineWhenDB` |
| WoW Channel chat | TBC Classic API | Transport for ANN/REQ/BYE messages via `SendChatMessage` |

No `npm install`, no external dependencies, no test runner frameworks exist in this project.

## Architecture Patterns

### Existing File Structure (relevant modules)

```
Core/
├── Database.lua     -- OW.SaveMyEntry, OW.UpsertPeer (MODIFIED this phase)
├── Init.lua         -- event wiring, bootstrap
└── ...
Network/
└── Protocol.lua     -- split(), SerializeANN, P.Deserialize, validateANN, HandleANN (MODIFIED this phase)
Data/
└── Activities.lua   -- OW.ACTIVITY_LIST, OW.ACTIVITY_SUBS (read-only reference for this phase)
```

### Pattern 1: Table-concat Serialization

`SerializeANN` already uses `table.concat({...}, SEP)`. Appending two more fields is a direct extension of the existing array literal — no structural change to the serializer.

```lua
-- Current (10 fields):
return table.concat({
    MSG_VERSION, "ANN",
    entry.name or "", entry.realm or "", entry.spec or "",
    tostring(entry.level or 1), tostring(entry.onlineAt or 0),
    entry.timezone or "UTC", tostring(entry.updated or 0),
    entry.class or "",
}, SEP)

-- Extended (12 fields, D-02):
return table.concat({
    MSG_VERSION, "ANN",
    entry.name or "", entry.realm or "", entry.spec or "",
    tostring(entry.level or 1), tostring(entry.onlineAt or 0),
    entry.timezone or "UTC", tostring(entry.updated or 0),
    entry.class or "",
    entry.primaryActivity or "",
    entry.exactActivity   or "",
}, SEP)
```

### Pattern 2: Empty-token-preserving split (D-01)

The current `split` silently drops empty tokens, which breaks `;;` (empty field) round-trip. The fix appends a sentinel `;` and uses `([^;]*)` (allows zero-length match):

```lua
-- Broken (current):
local function split(str, sep)
    local parts = {}
    for part in str:gmatch("([^" .. sep .. "]+)") do
        table.insert(parts, part)
    end
    return parts
end

-- Fixed (D-01):
local function split(str, sep)
    local parts = {}
    for part in (str .. sep):gmatch("([^" .. sep .. "]*)" .. sep) do
        table.insert(parts, part)
    end
    return parts
end
```

The sentinel pattern `(str..";"):gmatch("([^;]*);")` is idiomatic Lua 5.1 for CSV/delimited parsing that preserves empty fields. It is well-established and has no edge-case issues for this wire format because the input is always structured addon messages, not arbitrary user strings.

### Pattern 3: validateANN field-count guard (D-03)

```lua
-- Current (rejects anything but 10):
if #fields ~= 10 then return false end

-- Fixed (accepts 10 or 12, rejects everything else):
if #fields ~= 10 and #fields ~= 12 then return false end
```

### Pattern 4: Empty-string to nil mapping in HandleANN (D-04)

Following the existing pattern already in `HandleANN` for `spec` and `class`:

```lua
spec  = fields[5]  ~= "" and fields[5]  or nil,
class = fields[10] ~= "" and fields[10] or nil,
```

The activity fields follow the same convention:

```lua
primaryActivity = (#fields >= 11 and fields[11] ~= "") and fields[11] or nil,
exactActivity   = (#fields >= 12 and fields[12] ~= "") and fields[12] or nil,
```

The `#fields >= 11` guard is required because old-client messages pass `validateANN` with 10 fields — `fields[11]` would be `nil`, and calling `fields[11] ~= ""` on nil is safe in Lua (nil is not equal to ""), but being explicit improves readability. Either form works; clarity wins.

### Pattern 5: SaveMyEntry extension

```lua
-- Current signature:
function OW.SaveMyEntry(name, spec, class, level, onlineAt, tzId)
    OnlineWhenDB.myEntry = {
        name = name, realm = ..., spec = spec, class = class,
        level = level, onlineAt = onlineAt, timezone = tzId, updated = time(),
    }

-- Extended (NET-03):
function OW.SaveMyEntry(name, spec, class, level, onlineAt, tzId, primaryActivity, exactActivity)
    OnlineWhenDB.myEntry = {
        name = name, realm = ..., spec = spec, class = class,
        level = level, onlineAt = onlineAt, timezone = tzId, updated = time(),
        primaryActivity = primaryActivity or nil,
        exactActivity   = exactActivity   or nil,
    }
```

`primaryActivity or nil` is idiomatic: if the caller passes an empty string, it normalizes to nil in storage. Phase 3 will pass non-empty strings from the validated dropdown.

### Anti-Patterns to Avoid

- **Validating activity strings against `OW.ACTIVITY_LIST`:** D-05 explicitly forbids this. Activity values are pass-through strings. Do not build a `VALID_ACTIVITIES` lookup table.
- **Storing empty string instead of nil:** All absent optional fields in the entry schema use `nil`, not `""`. The `~= "" and ... or nil` mapping (D-04) enforces this at deserialization time.
- **Changing `HandleBYE` or `HandleREQ`:** These handlers have fixed field counts and are not touched by this phase.
- **Calling `OW.UpsertPeer` with extra arguments:** `UpsertPeer(key, entry)` already stores the full entry table as-is. Activity fields need no special treatment — they just need to be present in the entry table that `HandleANN` constructs.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead |
|---------|-------------|-------------|
| Empty-token CSV split | Custom state-machine parser | `(str..sep):gmatch("([^sep]*)sep")` — one-line Lua idiom |
| Activity enum membership check | `VALID_ACTIVITIES` set | Nothing — D-05 says pass-through; skip validation entirely |
| Entry versioning/migration | Schema version field in DB | Not needed — `nil` fields are the graceful-degradation mechanism |

## Common Pitfalls

### Pitfall 1: split() silently drops fields[11] when primaryActivity is empty string

**What goes wrong:** If `primaryActivity` is `""` in the serialized message, the current `gmatch("([^;]+)")` pattern skips it entirely. `fields[11]` would then contain whatever came after the empty field, corrupting the entire field-index mapping.

**Why it happens:** `[^;]+` requires one or more non-separator characters — it cannot match a zero-length token.

**How to avoid:** Fix `split()` with D-01 before extending `SerializeANN`. Do not extend the serializer without first fixing the parser.

**Warning signs:** `fields[11]` contains a numeric-looking string instead of an activity label; `exactActivity` is unexpectedly populated from the wrong field.

### Pitfall 2: validateANN rejects all new-client messages

**What goes wrong:** The current `#fields ~= 10` guard would cause every 12-field ANN (from updated clients) to be silently dropped. Peers running the updated client would never appear in each other's player lists.

**Why it happens:** The guard was written when 10 was the only valid count. It has not been updated.

**How to avoid:** Change to `#fields ~= 10 and #fields ~= 12` as part of the same Protocol.lua edit (Plan 02-02). This is documented in STATE.md as a known hazard.

**Warning signs:** Updated client sends ANNs but peers don't appear; debug dump shows messages being received but HandleANN returning early.

### Pitfall 3: nil vs empty-string confusion in UpsertPeer / downstream phases

**What goes wrong:** If `HandleANN` stores `""` instead of `nil` for absent activity fields, Phase 4's player list column will show a blank string that fails truthiness checks differently from `nil`, and Phase 5's filter logic would need to handle both.

**Why it happens:** Forgetting the `~= "" and ... or nil` pattern from D-04.

**How to avoid:** Apply the empty-string → nil mapping in `HandleANN` for fields[11] and fields[12]. This is the same pattern already used for `spec` (fields[5]) and `class` (fields[10]) in the existing code.

**Warning signs:** `entry.primaryActivity == ""` instead of `nil` in peer records; Phase 3 Populate() shows empty dropdown instead of blank dropdown.

### Pitfall 4: BroadcastSelf picks up activity automatically — no separate wiring needed

**What goes wrong (if misunderstood):** Developer adds a separate call to broadcast activity data, creating duplicate ANN messages.

**Why it happens:** Not reading `BroadcastSelf` carefully — it reads `OnlineWhenDB.myEntry` directly and calls `SerializeANN(myEntry)`. Once `SaveMyEntry` stores `primaryActivity` and `exactActivity` in `myEntry`, and `SerializeANN` serializes all 12 fields, the broadcast is automatically correct.

**How to avoid:** No additional broadcast wiring is needed. The data flow is: `SaveMyEntry` writes → `myEntry` stores → `BroadcastSelf` reads → `SerializeANN` serializes.

### Pitfall 5: split() change breaks REQ and BYE parsing

**What goes wrong:** The fixed `split()` function is used by `P.Deserialize`, which is called for all message types (ANN, REQ, BYE). REQ and BYE have 4 fields with no empty tokens — the sentinel-append pattern must produce the same result for them.

**Why it happens:** Concern about regressions in other handlers.

**How to avoid:** Verify with a quick mental trace: `"1;REQ;Name;Realm"` — appending `;` gives `"1;REQ;Name;Realm;"` — gmatch yields `"1"`, `"REQ"`, `"Name"`, `"Realm"` — 4 tokens, correct. No regression.

## Code Examples

### Fixed split() function

```lua
-- Source: D-01 (CONTEXT.md) + standard Lua 5.1 idiom
local function split(str, sep)
    local parts = {}
    for part in (str .. sep):gmatch("([^" .. sep .. "]*)" .. sep) do
        table.insert(parts, part)
    end
    return parts
end
```

### Extended SerializeANN

```lua
-- Source: D-02 (CONTEXT.md), extending existing table.concat pattern
function P.SerializeANN(entry)
    return table.concat({
        MSG_VERSION,
        "ANN",
        entry.name            or "",
        entry.realm           or "",
        entry.spec            or "",
        tostring(entry.level    or 1),
        tostring(entry.onlineAt or 0),
        entry.timezone        or "UTC",
        tostring(entry.updated  or 0),
        entry.class           or "",
        entry.primaryActivity or "",
        entry.exactActivity   or "",
    }, SEP)
end
```

### Updated validateANN field-count check

```lua
-- Source: D-03 (CONTEXT.md) + STATE.md known hazard
if #fields ~= 10 and #fields ~= 12 then return false end
```

### Extended HandleANN entry construction

```lua
-- Source: D-04 (CONTEXT.md), following existing spec/class nil pattern
local entry = {
    name            = fields[3],
    realm           = fields[4],
    spec            = fields[5]  ~= "" and fields[5]  or nil,
    level           = tonumber(fields[6]),
    onlineAt        = tonumber(fields[7]),
    timezone        = fields[8],
    updated         = tonumber(fields[9]),
    class           = fields[10] ~= "" and fields[10] or nil,
    primaryActivity = (fields[11] and fields[11] ~= "") and fields[11] or nil,
    exactActivity   = (fields[12] and fields[12] ~= "") and fields[12] or nil,
}
```

### Extended SaveMyEntry

```lua
-- Source: Plan 02-01, extending existing struct-assignment pattern
function OW.SaveMyEntry(name, spec, class, level, onlineAt, tzId, primaryActivity, exactActivity)
    OnlineWhenDB.myEntry = {
        name            = name,
        realm           = OnlineWhenDB.settings.realm or GetRealmName(),
        spec            = spec,
        class           = class,
        level           = level,
        onlineAt        = onlineAt,
        timezone        = tzId,
        updated         = time(),
        primaryActivity = primaryActivity or nil,
        exactActivity   = exactActivity   or nil,
    }
    if OW.Protocol then
        OW.Protocol.BroadcastSelf()
    end
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| 10-field ANN | 12-field ANN (with 10-field fallback) | Phase 2 | Old clients continue working; new clients gain activity data |
| `split()` drops empty tokens | `split()` preserves empty tokens | Phase 2 | Empty activity fields round-trip correctly |
| `validateANN` hardcodes `#fields ~= 10` | `validateANN` accepts 10 or 12 | Phase 2 | New-client messages no longer silently rejected |

## Open Questions

1. **Plan ordering within Phase 2**
   - What we know: The three plans are 02-01 (SaveMyEntry), 02-02 (Protocol), 02-03 (UpsertPeer + round-trip).
   - What's unclear: Whether 02-01 or 02-02 should execute first.
   - Recommendation: 02-02 first (fix Protocol), then 02-01 (extend SaveMyEntry), then 02-03 (verify). This avoids a window where `SaveMyEntry` stores activity fields but `SerializeANN` discards them. Both files are independent of each other's changes — the ordering is risk management, not a hard dependency.

2. **Backward-compat of `split()` fix for BYE/REQ messages**
   - What we know: Both have no empty tokens in practice; the sentinel-append produces identical output for non-empty token sequences.
   - What's unclear: Nothing — mental trace confirms no regression (see Pitfall 5 above).
   - Recommendation: No open issue. Document the verification in the plan commit message.

## Environment Availability

Step 2.6: SKIPPED — this phase is purely code changes to Lua files with no external tool dependencies. No CLI tools, databases, or services are required beyond a WoW TBC Classic client for final smoke-testing.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | None — no automated test framework exists in this WoW addon project |
| Config file | None |
| Quick run command | Manual: load addon in WoW client, open DevTools / use `/print` |
| Full suite command | Manual smoke-test session (see Wave 0 Gaps) |

No `.test.lua`, `tests/`, or testing framework files exist in the repository. WoW addon testing is inherently manual — the addon runs inside the WoW client where standard test runners cannot execute.

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| NET-01 | `SerializeANN` produces 12-field string ending in `;primaryActivity;exactActivity` | manual-only | N/A — WoW client required | N/A |
| NET-02 | 10-field ANN from old client accepted; activity fields nil in resulting entry | manual-only | N/A — WoW client required | N/A |
| NET-03 | `SaveMyEntry(...)` stores `primaryActivity` and `exactActivity` in `myEntry` | manual-only | N/A — WoW client required | N/A |
| NET-04 | `UpsertPeer` stores activity fields from `HandleANN`-built entry | manual-only | N/A — WoW client required | N/A |

**Justification for manual-only:** The WoW addon environment embeds Lua 5.1 inside the game client. Standard Lua test runners (busted, luaunit) cannot require WoW API globals (`time()`, `GetRealmName()`, `C_Timer`, `SendChatMessage`) without a full mock layer. Introducing a mock harness is out of scope for this phase. Verification per success criteria SC1–SC5 from the roadmap serves as the acceptance test.

### Sampling Rate

- **Per task commit:** Reload UI (`/reload`) and inspect `OnlineWhenDB.myEntry` via `/dump OnlineWhenDB.myEntry`
- **Per wave merge:** Full smoke-test: two-client ANN round-trip (new-client → new-client, old-client → new-client)
- **Phase gate:** All 5 success criteria from ROADMAP.md §Phase 2 verified before `/gsd:verify-work`

### Wave 0 Gaps

None — no test infrastructure to create. The verification strategy is in-client inspection and two-client round-trip testing.

## Sources

### Primary (HIGH confidence)

- `Core/Database.lua` (read directly) — exact current `OW.SaveMyEntry` and `OW.UpsertPeer` signatures and logic
- `Network/Protocol.lua` (read directly) — exact current `split()`, `SerializeANN`, `validateANN`, `HandleANN` implementations
- `Data/Activities.lua` (read directly) — `OW.ACTIVITY_LIST` labels confirm what `primaryActivity` string values look like
- `.planning/phases/02-database-protocol/02-CONTEXT.md` (read directly) — all implementation decisions D-01 through D-05
- `.planning/STATE.md` (read directly) — `validateANN` hardcoded `#fields ~= 10` known hazard, explicitly documented

### Secondary (MEDIUM confidence)

- Standard Lua 5.1 `gmatch` pattern behavior for empty-token preservation — well-established idiom, confirmed by reading the existing code and applying the pattern mentally

### Tertiary (LOW confidence)

None — all findings are grounded in direct code reads and locked decisions.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — WoW Lua addon; no external dependencies; all code read directly
- Architecture: HIGH — patterns extracted from existing `Protocol.lua` and `Database.lua` source; decisions are locked in CONTEXT.md
- Pitfalls: HIGH — split() bug is observable in the source; validateANN hardcode documented in STATE.md; nil/empty-string pattern established by existing spec/class handling

**Research date:** 2026-03-24
**Valid until:** Stable until Phase 2 implementation — no external dependencies that can drift

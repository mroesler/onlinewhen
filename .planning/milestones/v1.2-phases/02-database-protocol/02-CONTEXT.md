# Phase 2: Database + Protocol - Context

**Gathered:** 2026-03-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Extend `Core/Database.lua` to accept and store `primaryActivity` and `exactActivity` in every
entry record, and extend `Network/Protocol.lua` to serialize/deserialize those two fields in
the ANN wire message. Old-client peers (10-field ANN) must degrade gracefully to nil activity.
No UI code belongs here — this phase delivers the data and network layer only.

</domain>

<decisions>
## Implementation Decisions

### Wire Format — Empty Field Serialization
- **D-01:** Fix the `split()` function in `Protocol.lua` to preserve empty tokens. The current
  `gmatch("([^;]+)")` skips empty fields — change to `(str..";"):gmatch("([^;]*);")` so that
  consecutive separators (`;;`) yield empty-string entries rather than being silently dropped.
- **D-02:** New-client ANNs **always serialize as 12 fields**. When `primaryActivity` or
  `exactActivity` is nil/unset, serialize as empty string `""`. Format:
  `1;ANN;Name;Realm;Spec;Level;OnlineAtUTC;TzId;UpdatedUTC;Class;primaryActivity;exactActivity`
- **D-03:** `validateANN` must accept **10 or 12 fields** — 10 = old client (treat activity as nil);
  12 = new client. Any other count is rejected.
- **D-04:** When mapping deserialized fields to entry table, empty string → nil:
  `primaryActivity = fields[11] ~= "" and fields[11] or nil`
  `exactActivity   = fields[12] ~= "" and fields[12] or nil`

### Activity Validation
- **D-05:** Do **not** validate activity field values against `OW.ACTIVITY_LIST`. Accept any
  non-empty string — pass through as-is. Rationale: strict validation would drop peers if
  activity names ever change in a future update; the spec/class pattern (VALID_SPECS) is
  tighter because those values drive UI rendering that would break on unknown inputs.

### Claude's Discretion
- Exact Lua pattern syntax for the fixed split (pattern shown in D-01 is the decision; minor
  syntax variations acceptable as long as empty tokens are preserved)
- Whether to inline the activity-field mapping in `HandleANN` or extract a helper

</decisions>

<specifics>
## Specific Ideas

- The success criteria explicitly require both activity fields to be nil (not empty string) when
  absent — the `~= "" and ... or nil` mapping in D-04 is required, not optional.
- `exactActivity` is intentionally empty/nil for Quest, Farm, and Chill (no sub-types exist for
  those activities) — this is expected data, not a bug.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Files being modified in this phase
- `Core/Database.lua` — `OW.SaveMyEntry` (current 6-param signature to extend) and `OW.UpsertPeer`
- `Network/Protocol.lua` — `split()`, `SerializeANN`, `P.Deserialize`, `validateANN`, `HandleANN`

### Existing pattern references
- `Core/Specs.lua` — VALID_SPECS/VALID_CLASSES build pattern (for contrast: activity does NOT use this)
- `Data/Activities.lua` — activity list source; shows what primaryActivity values look like in practice

### Planning and conventions
- `.planning/codebase/CONVENTIONS.md` — naming conventions, file header style
- `.planning/ROADMAP.md` §Phase 2 — success criteria SC1–SC5 are the acceptance test

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `SerializeANN` uses `table.concat({...}, SEP)` — append two more entries to the table for the new fields
- `HandleANN` maps `fields[N]` directly to entry keys — extend with fields[11]/[12]
- Entry table structure already uses `nil` for absent optional fields (spec, class) — same pattern for activity

### Established Patterns
- `OW.SaveMyEntry` broadcasts immediately via `OW.Protocol.BroadcastSelf()` — once the signature
  is extended and activity fields are stored in `myEntry`, the broadcast is automatic
- `OW.UpsertPeer(key, entry)` stores the full entry as-is — activity fields just need to be present
  in the entry table passed from `HandleANN`; no UpsertPeer logic changes required beyond that

### Integration Points
- `OW.SaveMyEntry` is called from `UI/TabSchedule.lua` (Phase 3 will add activity args)
- `OW.Protocol.BroadcastSelf()` reads `OnlineWhenDB.myEntry` directly → activity fields stored
  by `SaveMyEntry` will be picked up by `SerializeANN` automatically
- `validateANN` must be updated before `HandleANN` can safely read fields[11]/[12]

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 02-database-protocol*
*Context gathered: 2026-03-24*

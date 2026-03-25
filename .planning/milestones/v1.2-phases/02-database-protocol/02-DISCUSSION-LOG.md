# Phase 2: Database + Protocol - Discussion Log

**Session:** 2026-03-24
**Mode:** Interactive (discuss)

---

## Gray Areas Presented

Two gray areas identified for user discussion:
1. Empty field serialization in wire format
2. Activity validation strictness in validateANN

## Area 1: Empty Field Serialization

**Background surfaced:** The existing `split()` function in `Protocol.lua` uses
`gmatch("([^;]+)")` which skips empty tokens. When `exactActivity` is `""` (e.g., for
Quest/Farm/Chill activities), serializing `"...;Quest;"` yields only 11 parseable fields
— `exactActivity` silently disappears.

**Question:** How should nil/empty activity fields be represented in the wire format?

**Options presented:**
- Fix the split function — rewrite to `(str..";"):gmatch("([^;]*);")` to preserve empty tokens
- Sentinel value `"-"` — serialize nil/empty as `"-"`, deserializer maps back to nil

**User selected:** Fix the split function

---

## Area 2: Activity Validation Strictness

**Question:** Should validateANN check activity field values against OW.ACTIVITY_LIST?

**Options presented:**
- Accept any string — pass through as-is, no list check
- Validate against OW.ACTIVITY_LIST — follows VALID_SPECS/VALID_CLASSES pattern

**User selected:** Accept any string

---

## Summary of Decisions

| # | Area | Decision |
|---|------|----------|
| D-01 | Split function | Fix to preserve empty tokens: `(str..";"):gmatch("([^;]*);")` |
| D-02 | ANN field count | Always 12 fields for new clients (empty string for unset activity) |
| D-03 | validateANN | Accept 10 (old) or 12 (new) fields — all other counts rejected |
| D-04 | Deserialization | Empty string → nil mapping for both activity fields |
| D-05 | Validation | No ACTIVITY_LIST validation — accept any non-empty string |

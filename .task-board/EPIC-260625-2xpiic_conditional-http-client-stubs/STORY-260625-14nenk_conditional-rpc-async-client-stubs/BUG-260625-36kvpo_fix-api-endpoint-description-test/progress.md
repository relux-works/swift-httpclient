## Status
to-review

## Assigned To
codex

## Created
2026-06-25T14:31:49Z

## Last Update
2026-06-25T14:33:34Z

## Blocked By
- (none)

## Blocks
- (none)

## Checklist
- [x] Inspect ApiEndpoint.description implementation and coverage expectation.
- [x] Apply the smallest correct fix for the full-suite failure.
- [x] Run focused MiscCoverageTests and full swift test.

## Notes
Full suite after ApiEndpoint fix now fails in PublishedWSClientTests.configEqualityAndDefaults; same gate bug expanded to cover remaining full-suite blocker before handoff.

## Precondition Resources
(none)

## Outcome Resources
- [full-suite-fix-outcome.md](file://BUG-260625-36kvpo/full-suite-fix-outcome.md) — Full swift test suite fix outcome

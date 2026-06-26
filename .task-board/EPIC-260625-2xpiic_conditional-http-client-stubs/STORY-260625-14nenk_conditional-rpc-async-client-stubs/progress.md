## Status
to-review

## Assigned To
codex

## Created
2026-06-25T14:19:36Z

## Last Update
2026-06-26T13:00:14Z

## Blocked By
- (none)

## Blocks
- (none)

## Checklist
(empty)

## Notes
Reopened to add an OTP contract regression test for the app pattern: a success condition plus a NOT(success) wrong-OTP fallback on the same confirm endpoint.
Added sequential stub responses so one matched stub can return ordered responses and then repeat the last response. This is needed by the app prod-success flow to refresh account balance through the real HTTP path across repeated transfer rounds. Verification passed: `swift test --package-path ../packages/swift-httpclient --filter RpcAsyncClientStubbableTests` with 13 tests.

## Precondition Resources
(none)

## Outcome Resources
- [conditional-otp-contract-test-outcome.md](file://STORY-260625-14nenk/conditional-otp-contract-test-outcome.md) — Additional OTP contract tests for conditional RPC stubs

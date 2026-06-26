# Conditional OTP contract test outcome

Added focused RpcAsyncClientStubbable coverage for the Tap2Cash OTP contract shape used by the app:

- success condition: bodyContains(key: otp, value: successOTP) returns 200 completed.
- wrong-code fallback: not(bodyContains(key: otp, value: successOTP)) returns 422 WRONG_OTP on the same endpoint.
- condition miss without a fallback condition calls the underlying base client, proving non-matching conditionals do not accidentally stub requests.
- sequential stub responses return ordered responses and then repeat the last response; this supports repeated account-balance refreshes in prod-success app automation.

Verification:

- swift test --filter RpcAsyncClientStubbableTests: passed, 13 tests. Log: .temp/conditional-otp-contract/rpc-stubbable-tests.log
- swift test: passed, 70 tests in 16 suites. Log: .temp/conditional-otp-contract/full-swift-test.log

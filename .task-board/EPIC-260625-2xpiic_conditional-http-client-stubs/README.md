# Conditional HTTP client stubs

## Description
Extend swift-httpclient stubbing so one endpoint can have multiple candidate stubs selected by request conditions instead of a single always-on response.

## Scope
HttpClient test/stub infrastructure, especially RpcAsyncClientStubbable request matching and public stub model APIs. The feature should support Tap2Cash backend scenarios such as returning WRONG_OTP for one confirm request body and success for another request body on the same endpoint.

## Acceptance Criteria
A caller can register multiple HTTP stubs for the same ApiEndpoint. An unconditional stub applies when no condition is attached. A conditional stub applies only when its condition evaluates true for the current request. Conditions support boolean composition with AND, OR, and NOT. Leaf predicates support at least JSON body key-value containment and query parameter containment. Stub selection is deterministic and documented. Existing endpoint-only and exact-body APIs remain source-compatible or have a migration path. Tests cover unconditional fallback, multiple conditional stubs on the same endpoint, JSON body parsing, query parameter parsing, boolean composition, and no-match forwarding to the wrapped client.

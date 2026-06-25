# Conditional RpcAsyncClientStubbable stubs

## Description
Add a condition-aware HTTP stub model to RpcAsyncClientStubbable. The current endpoint/exact request matching is useful but too rigid for scenarios where one endpoint needs multiple possible responses selected by request content. The target design should resemble PublishedStubbableWSClient in spirit but use request-domain predicates instead of normalized websocket message equality.

## Scope
RpcAsyncClientStubbable public model, request matching internals, JSON body inspection helpers, query parameter inspection helpers, compatibility extensions, and HttpClientTests coverage.

## Acceptance Criteria
RpcAsyncClientStubbable can keep more than one stub for the same endpoint when conditions differ. Unconditional stubs still work as absolute/default stubs. Conditional stubs evaluate request conditions against endpoint, query parameters, and body data. The condition model supports composite boolean logic with AND, OR, and NOT. Leaf predicates include JSON body key-value containment and query parameter containment. Selection order is explicit and stable: matching conditionals should be evaluated deterministically, with a documented policy for multiple matches and fallback to unconditional endpoint stubs. Existing call sites that use endpoint-only or exact body stubs continue to work. Tests demonstrate Tap2Cash-like OTP behavior: wrong OTP body selects an error response, correct OTP body selects a success response on the same confirm endpoint.

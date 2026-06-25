# Implement conditional stub selection

## Description
Implement the approved condition-aware stub model in swift-httpclient. The implementation should let callers attach multiple stubs to the same endpoint and select a response by evaluating request conditions.

## Scope
RpcAsyncClientStub, RpcAsyncClientStubRule or replacement model, RpcAsyncClientStubbable storage and lookup, request condition evaluator, JSON body/query parsing helpers, and source-compatible convenience APIs.

## Acceptance Criteria
Multiple conditional stubs can coexist for one endpoint. Unconditional stubs remain supported as default/absolute stubs. Existing endpoint-only and exact query/body stub APIs keep working or are adapted through compatibility overloads. Matching evaluates request conditions deterministically and forwards to the wrapped client when no stub matches. The implementation is thread-safe under the existing actor model and keeps public API naming consistent with the package style.

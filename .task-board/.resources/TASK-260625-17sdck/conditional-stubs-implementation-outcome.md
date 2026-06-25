# Conditional HTTP Stub Implementation Outcome

## Changed Files

- `Sources/RpcClient/AsyncStubable/IRpcAsyncClientStubbable.swift`
- `Sources/RpcClient/AsyncStubable/RpcAsyncClientStubbable.swift`
- `README.md`

## Implementation

- Added `RpcAsyncClientStubMode` and `RpcAsyncClientStubCondition`.
- Added conditional convenience initializers to `RpcAsyncClientStub`.
- Changed stub storage to an ordered `[RpcAsyncClientStub]`.
- Added deterministic candidate sorting by rule specificity, conditional mode, and insertion order.
- Added JSON body field matching and query parameter matching.
- Preserved backward-compatible `IRpcAsyncClientStubbable` helper APIs.
- Documented conditional stub usage in README.

## Notes

The implementation stays inside the existing actor, so no additional synchronization mechanism was needed.

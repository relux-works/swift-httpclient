# Conditional HTTP Stub Analysis Outcome

## Existing HTTP Stub Model

`RpcAsyncClientStubbable` previously stored endpoint-only and request-specific stubs in separate dictionaries. This made exact fallback behavior simple, but it could not represent two different responses for the same endpoint selected by request body or query content.

## WebSocket Stub Reference

`PublishedStubbableWSClient` keeps an ordered array of stubs and returns the first normalized outgoing-message match. The HTTP implementation adopted the same ordered multi-candidate direction while adding deterministic specificity rules for existing endpoint/query/body semantics.

## Feature Composite Reference

`relux-feature-management` models boolean expressions as an indirect enum with `allSatisfy`, `anySatisfy`, `not`, terminal feature/condition nodes, and literal boolean values. The HTTP condition model follows the same shape with HTTP-domain leaf predicates.

## Chosen Model

- `RpcAsyncClientStubMode.absolute` keeps existing unconditional behavior.
- `RpcAsyncClientStubMode.conditional(RpcAsyncClientStubCondition)` adds request-aware matching.
- `RpcAsyncClientStubCondition` supports `allSatisfy`, `anySatisfy`, `not`, `bodyContains`, `queryParameterContains`, and `value`.
- JSON body matching parses request body data and searches for the requested key recursively.
- Query matching reads explicit `queryParams` and URL query items from `endpoint.path`; explicit request query values override URL values.

## Selection Policy

Candidate selection is deterministic:

1. Exact query/body rule.
2. Query rule with any body.
3. Endpoint-only rule.
4. Conditional stubs beat absolute stubs within the same specificity.
5. Insertion order wins when specificity and mode kind are equal.

## Compatibility

Existing `upsert(rule:stub:)`, `upsert(rules:)`, query/body overloads, `remove(rule:)`, and endpoint fallback behavior remain source-compatible.

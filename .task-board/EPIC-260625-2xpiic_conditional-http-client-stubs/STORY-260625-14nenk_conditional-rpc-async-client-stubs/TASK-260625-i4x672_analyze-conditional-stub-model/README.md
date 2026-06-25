# Analyze conditional HTTP stub model

## Description
Specify the condition-aware HTTP stub model before code changes. The analysis must reconcile existing RpcAsyncClientStubbable endpoint/exact request matching, PublishedStubbableWSClient-style multiple rules, and relux-feature-management-style boolean composition.

## Scope
Public model shape, matching priority, request parsing semantics, compatibility strategy, and implementation boundaries for RpcAsyncClientStubbable.

## Acceptance Criteria
Analysis produces a concrete design for absolute and conditional stubs. It defines condition enum cases, boolean composition, required leaf predicates, request parsing behavior for JSON bodies and query parameters, deterministic selection priority, and backward compatibility for existing APIs. It calls out any rejected shortcuts or unresolved decisions before development starts.

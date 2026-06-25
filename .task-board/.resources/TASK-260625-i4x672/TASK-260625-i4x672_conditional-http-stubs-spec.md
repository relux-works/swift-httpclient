# Conditional HTTP Client Stubs Spec

## Problem

`RpcAsyncClientStubbable` currently supports endpoint-level stubs and request-level matching by exact query/body shape. This is not expressive enough for UI and integration scenarios where the same endpoint must return different responses depending on request content.

Tap2Cash wrong OTP retry is the motivating example: `POST /transfers/{id}/confirm` should return a backend `WRONG_OTP` response when the JSON body contains the wrong OTP, and a success response when the JSON body contains the correct OTP.

## Desired Model

Add a condition-aware stub model:

- Absolute/unconditional stub: applies whenever endpoint/request routing matches and no stronger conditional match is selected.
- Conditional stub: applies only when its condition evaluates to `true` for the current request.

The condition model should be an enum-based boolean algebra inspired by `relux-feature-management` composite expressions:

- `and([condition])`
- `or([condition])`
- `not(condition)`
- leaf predicates in the HTTP request domain

Required leaf predicates:

- JSON body key-value containment, for example body contains `otp = "00000"`.
- Query parameter containment, for example query contains `scenario = "wrong-otp"`.

Optional follow-up leaf predicates may include endpoint/path containment, header containment, method matching, or raw body substring matching, but they are not required for the first implementation unless they make the core design cleaner.

## Request Parsing

Body predicates should parse JSON request bodies into key-value structures. The first implementation may support flat JSON key-value containment if deep matching is documented; nested matching can be a follow-up if it would complicate the first pass.

Query predicates should use `Foundation.URL` / `URLComponents` where a full URL exists, then merge or compare with the `queryParams` passed to `performAsync`. The behavior must be documented when the endpoint URL and explicit `queryParams` both contain values.

## Selection Policy

Stub selection must be deterministic.

The design should document:

- how multiple conditional stubs for the same endpoint are ordered
- what happens when more than one condition matches
- how unconditional stubs behave as fallback/default stubs
- how existing exact request matching APIs map into the new model

The current existing behavior to preserve:

- endpoint-only stubs still work
- exact query/body stubs still work
- no matching stub forwards to the wrapped client

## Existing References

- `PublishedStubbableWSClient` already keeps multiple websocket stubs and selects the first matching outgoing message rule.
- `relux-feature-management` uses enum-based composite boolean expressions: `FeatureComposite` with `.and`, `.or`, `.not`.

## Acceptance Notes

Avoid introducing ad hoc special cases only for Tap2Cash OTP. The HTTP client should expose a general request-condition model that Tap2Cash can use for OTP, balance, and future backend automation scenarios.

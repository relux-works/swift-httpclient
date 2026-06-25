# Test conditional HTTP stubs

## Description
Add focused Swift tests for the conditional HTTP stub feature and its compatibility behavior.

## Scope
HttpClientTests coverage for condition evaluation, JSON body matching, query matching, boolean composition, selection priority, unconditional fallback, and forwarding when no stub matches.

## Acceptance Criteria
Tests cover at least two conditional responses on the same endpoint selected by JSON body content. Tests cover query parameter containment, AND/OR/NOT composition, unconditional fallback behavior, multiple-match deterministic selection, exact request compatibility, endpoint-only compatibility, and wrapped-client forwarding when no stub matches. A Tap2Cash-like wrong OTP versus correct OTP confirm request is represented as a package-level test fixture without importing Tap2Cash.

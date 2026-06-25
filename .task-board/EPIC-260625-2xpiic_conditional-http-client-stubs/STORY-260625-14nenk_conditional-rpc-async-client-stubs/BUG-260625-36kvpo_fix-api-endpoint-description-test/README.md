# BUG-260625-36kvpo: fix-api-endpoint-description-test

## Description
Full swift test must be green before publishing the conditional stub work. The current full suite fails only in MiscCoverageTests.apiEndpointDescriptionUsesMethodAndPath: ApiEndpoint(path: "auth/logout", type: .post).description returns "POST auth/logout" while the test expects "POST /auth/logout". Investigate the intended ApiEndpoint.description contract, fix the smallest correct surface, and rerun the full Swift package test suite.

## Scope
(define bug scope / affected area)

## Acceptance Criteria
(define fix acceptance criteria)

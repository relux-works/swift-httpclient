import Foundation
import Testing
@testable import HttpClient

@Suite struct RpcAsyncClientStubbableTests {
    @Test func returnsStubWhenRuleMatches() async throws {
        let mock = RpcClientWithAsyncAwaitMock()
        let stubbable = RpcAsyncClientStubbable(client: mock, logger: TestLogger())

        let endpoint = ApiEndpoint(path: "https://example.com/stub", type: .get)
        let stubResponse = ApiResponse.stub(data: Data("stubbed".utf8), code: 201)
        await stubbable.upsert(rule: endpoint, stub: stubResponse)

        let result = await stubbable.get(
            url: try #require(URL(string: endpoint.path)),
            headers: [.authorization: .bearer(token: "token")],
            retrys: RetryParams(count: 1, delay: { 0 }),
            fileID: #fileID,
            functionName: #function,
            lineNumber: #line
        )

        switch result {
        case let .success(response):
            #expect(response.code == 201)
            #expect(response.data?.utf8 == "stubbed")
        case let .failure(error):
            #expect(Bool(false), "Expected stubbed response, got \(error)")
        }

        let recorded = await mock.getCalls
        #expect(recorded.isEmpty, "Underlying client should not be called when stub matches")
    }

    @Test func fallsBackToClientWhenNoStub() async throws {
        let mock = RpcClientWithAsyncAwaitMock()
        await mock.setGetResult(.success(.stub(data: Data("live".utf8))))
        let stubbable = RpcAsyncClientStubbable(client: mock, logger: TestLogger())

        let url = try #require(URL(string: "https://example.com/live"))
        _ = await stubbable.get(
            url: url,
            headers: [:],
            retrys: RetryParams(count: 0, delay: { 0 }),
            fileID: #fileID,
            functionName: #function,
            lineNumber: #line
        )

        let recorded = await mock.getCalls
        #expect(recorded.count == 1)
        #expect(recorded.first?.url == url)
    }

    @Test func performAsyncDistinguishesDifferentQueryParams() async throws {
        let mock = RpcClientWithAsyncAwaitMock()
        let stubbable = RpcAsyncClientStubbable(client: mock, logger: TestLogger())

        let endpoint = ApiEndpoint(path: "https://example.com/search", type: .get)
        await stubbable.upsert(
            rule: endpoint,
            queryParams: ["page": "1"],
            stub: .stub(data: Data("first-page".utf8), code: 200)
        )
        await stubbable.upsert(
            rule: endpoint,
            queryParams: ["page": "2"],
            stub: .stub(data: Data("second-page".utf8), code: 200)
        )

        let firstResult = await stubbable.performAsync(
            endpoint: endpoint,
            headers: [:],
            queryParams: ["page": "1"],
            bodyData: nil,
            fileID: #fileID,
            functionName: #function,
            lineNumber: #line
        )
        let secondResult = await stubbable.performAsync(
            endpoint: endpoint,
            headers: [:],
            queryParams: ["page": "2"],
            bodyData: nil,
            fileID: #fileID,
            functionName: #function,
            lineNumber: #line
        )

        #expect(try firstResult.requireSuccess().data?.utf8 == "first-page")
        #expect(try secondResult.requireSuccess().data?.utf8 == "second-page")

        let recorded = await mock.performCalls
        #expect(recorded.isEmpty, "Underlying client should not be called when query-specific stubs match")
    }

    @Test func performAsyncCanMatchBodyWhenConfigured() async throws {
        let mock = RpcClientWithAsyncAwaitMock()
        let stubbable = RpcAsyncClientStubbable(client: mock, logger: TestLogger())

        let endpoint = ApiEndpoint(path: "https://example.com/filter", type: .post)
        let queryParams = ["mode": "strict"]
        let firstBody = Data(#"{"id":"1"}"#.utf8)
        let secondBody = Data(#"{"id":"2"}"#.utf8)
        await stubbable.upsert(
            rule: endpoint,
            queryParams: queryParams,
            bodyData: firstBody,
            stub: .stub(data: Data("first-body".utf8), code: 200)
        )
        await stubbable.upsert(
            rule: endpoint,
            queryParams: queryParams,
            bodyData: secondBody,
            stub: .stub(data: Data("second-body".utf8), code: 200)
        )

        let firstResult = await stubbable.performAsync(
            endpoint: endpoint,
            headers: [:],
            queryParams: queryParams,
            bodyData: firstBody,
            fileID: #fileID,
            functionName: #function,
            lineNumber: #line
        )
        let secondResult = await stubbable.performAsync(
            endpoint: endpoint,
            headers: [:],
            queryParams: queryParams,
            bodyData: secondBody,
            fileID: #fileID,
            functionName: #function,
            lineNumber: #line
        )

        #expect(try firstResult.requireSuccess().data?.utf8 == "first-body")
        #expect(try secondResult.requireSuccess().data?.utf8 == "second-body")

        let recorded = await mock.performCalls
        #expect(recorded.isEmpty, "Underlying client should not be called when body-aware stubs match")
    }

    @Test func performAsyncKeepsLegacyEndpointFallbackAndPrefersSpecificRule() async throws {
        let mock = RpcClientWithAsyncAwaitMock()
        let stubbable = RpcAsyncClientStubbable(client: mock, logger: TestLogger())

        let endpoint = ApiEndpoint(path: "https://example.com/feed", type: .get)
        await stubbable.upsert(
            rule: endpoint,
            stub: .stub(data: Data("legacy".utf8), code: 200)
        )
        await stubbable.upsert(
            rule: endpoint,
            queryParams: ["kind": "smoke"],
            stub: .stub(data: Data("specific".utf8), code: 200)
        )

        let specificResult = await stubbable.performAsync(
            endpoint: endpoint,
            headers: [:],
            queryParams: ["kind": "smoke"],
            bodyData: Data("ignored-by-query-rule".utf8),
            fileID: #fileID,
            functionName: #function,
            lineNumber: #line
        )
        let legacyResult = await stubbable.performAsync(
            endpoint: endpoint,
            headers: [:],
            queryParams: ["kind": "other"],
            bodyData: nil,
            fileID: #fileID,
            functionName: #function,
            lineNumber: #line
        )

        #expect(try specificResult.requireSuccess().data?.utf8 == "specific")
        #expect(try legacyResult.requireSuccess().data?.utf8 == "legacy")

        let recorded = await mock.performCalls
        #expect(recorded.isEmpty, "Underlying client should not be called when specific or fallback stubs match")
    }

    @Test func upsertStubsBatchSupportsMixedRules() async throws {
        let mock = RpcClientWithAsyncAwaitMock()
        let stubbable = RpcAsyncClientStubbable(client: mock, logger: TestLogger())

        let endpointRule = ApiEndpoint(path: "https://example.com/legacy-feed", type: .get)
        let requestRule = ApiEndpoint(path: "https://example.com/filter", type: .post)
        let queryParams = ["kind": "smoke"]
        let exactBody = Data(#"{"id":"1"}"#.utf8)

        await stubbable.upsert(stubs: [
            .init(
                endpoint: endpointRule,
                response: .stub(data: Data("legacy".utf8), code: 200)
            ),
            .init(
                endpoint: requestRule,
                queryParams: queryParams,
                response: .stub(data: Data("query-any-body".utf8), code: 200)
            ),
            .init(
                endpoint: requestRule,
                queryParams: queryParams,
                bodyData: exactBody,
                response: .stub(data: Data("exact-body".utf8), code: 200)
            )
        ])

        let endpointResult = await stubbable.get(
            url: try #require(URL(string: endpointRule.path)),
            headers: [:],
            retrys: RetryParams(count: 0, delay: { 0 }),
            fileID: #fileID,
            functionName: #function,
            lineNumber: #line
        )
        let exactBodyResult = await stubbable.performAsync(
            endpoint: requestRule,
            headers: [:],
            queryParams: queryParams,
            bodyData: exactBody,
            fileID: #fileID,
            functionName: #function,
            lineNumber: #line
        )
        let queryOnlyResult = await stubbable.performAsync(
            endpoint: requestRule,
            headers: [:],
            queryParams: queryParams,
            bodyData: Data(#"{"id":"2"}"#.utf8),
            fileID: #fileID,
            functionName: #function,
            lineNumber: #line
        )

        #expect(try endpointResult.requireSuccess().data?.utf8 == "legacy")
        #expect(try exactBodyResult.requireSuccess().data?.utf8 == "exact-body")
        #expect(try queryOnlyResult.requireSuccess().data?.utf8 == "query-any-body")

        let getCalls = await mock.getCalls
        let performCalls = await mock.performCalls
        #expect(getCalls.isEmpty)
        #expect(performCalls.isEmpty)
    }

    @Test func removeRuleCanTargetExactBodyMatcher() async throws {
        let mock = RpcClientWithAsyncAwaitMock()
        await mock.setPerfomResult(.success(.stub(data: Data("live".utf8))))
        let stubbable = RpcAsyncClientStubbable(client: mock, logger: TestLogger())

        let endpoint = ApiEndpoint(path: "https://example.com/cleanup", type: .post)
        let queryParams = ["mode": "strict"]
        let bodyData = Data(#"{"id":"1"}"#.utf8)

        await stubbable.upsert(
            stub: .init(
                rule: .request(
                    endpoint: endpoint,
                    queryParams: queryParams,
                    bodyMatcher: .exact(bodyData)
                ),
                response: .stub(data: Data("to-remove".utf8), code: 200)
            )
        )
        await stubbable.remove(
            rule: .request(
                endpoint: endpoint,
                queryParams: queryParams,
                bodyMatcher: .exact(bodyData)
            )
        )

        let result = await stubbable.performAsync(
            endpoint: endpoint,
            headers: [:],
            queryParams: queryParams,
            bodyData: bodyData,
            fileID: #fileID,
            functionName: #function,
            lineNumber: #line
        )

        #expect(try result.requireSuccess().data?.utf8 == "live")
        let performCalls = await mock.performCalls
        #expect(performCalls.count == 1)
    }
}

private extension Result where Success == ApiResponse, Failure == ApiError {
    func requireSuccess() throws -> ApiResponse {
        switch self {
        case let .success(response):
            return response
        case let .failure(error):
            throw error
        }
    }
}

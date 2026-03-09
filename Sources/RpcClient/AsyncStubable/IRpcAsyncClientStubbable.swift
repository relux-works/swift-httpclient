import Foundation

public enum RpcAsyncClientStubBodyMatcher: Sendable, Hashable {
    case any
    case exact(Data?)
}

public enum RpcAsyncClientStubRule: Sendable {
    case endpoint(ApiEndpoint)
    case request(
        endpoint: ApiEndpoint,
        queryParams: QueryParams,
        bodyMatcher: RpcAsyncClientStubBodyMatcher
    )

    public static func request(
        endpoint: ApiEndpoint,
        queryParams: QueryParams,
        bodyData: Data?
    ) -> RpcAsyncClientStubRule {
        .request(
            endpoint: endpoint,
            queryParams: queryParams,
            bodyMatcher: .exact(bodyData)
        )
    }
}

public struct RpcAsyncClientStub: Sendable {
    public let rule: RpcAsyncClientStubRule
    public let response: ApiResponse

    public init(
        rule: RpcAsyncClientStubRule,
        response: ApiResponse
    ) {
        self.rule = rule
        self.response = response
    }

    public init(
        endpoint: ApiEndpoint,
        response: ApiResponse
    ) {
        self.init(
            rule: .endpoint(endpoint),
            response: response
        )
    }

    public init(
        endpoint: ApiEndpoint,
        queryParams: QueryParams,
        response: ApiResponse
    ) {
        self.init(
            rule: .request(
                endpoint: endpoint,
                queryParams: queryParams,
                bodyMatcher: .any
            ),
            response: response
        )
    }

    public init(
        endpoint: ApiEndpoint,
        queryParams: QueryParams,
        bodyData: Data?,
        response: ApiResponse
    ) {
        self.init(
            rule: .request(
                endpoint: endpoint,
                queryParams: queryParams,
                bodyMatcher: .exact(bodyData)
            ),
            response: response
        )
    }
}

public protocol IRpcAsyncClientStubbable: IRpcAsyncClient {
    func upsert(stub: RpcAsyncClientStub) async
    func remove(rule: RpcAsyncClientStubRule) async
    func removeAllRules() async
}

public extension IRpcAsyncClientStubbable {
    func upsert(stubs: [RpcAsyncClientStub]) async {
        for stub in stubs {
            await upsert(stub: stub)
        }
    }

    // Backward-compatible API kept for existing call sites.
    func upsert(rule: ApiEndpoint, stub: ApiResponse) async {
        await upsert(
            stub: .init(
                endpoint: rule,
                response: stub
            )
        )
    }

    // Backward-compatible API kept for existing call sites.
    func upsert(rules: [ApiEndpoint: ApiResponse]) async {
        let stubs = rules.map { rule, stub in
            RpcAsyncClientStub(
                endpoint: rule,
                response: stub
            )
        }
        await upsert(stubs: stubs)
    }

    func upsert(rule: ApiEndpoint, queryParams: QueryParams, stub: ApiResponse) async {
        await upsert(
            stub: .init(
                endpoint: rule,
                queryParams: queryParams,
                response: stub
            )
        )
    }

    func upsert(rule: ApiEndpoint, queryParams: QueryParams, bodyData: Data?, stub: ApiResponse) async {
        await upsert(
            stub: .init(
                endpoint: rule,
                queryParams: queryParams,
                bodyData: bodyData,
                response: stub
            )
        )
    }

    // Backward-compatible API kept for existing call sites.
    func remove(rule: ApiEndpoint) async {
        await remove(rule: .endpoint(rule))
    }

    func remove(rule: ApiEndpoint, queryParams: QueryParams) async {
        await remove(
            rule: .request(
                endpoint: rule,
                queryParams: queryParams,
                bodyMatcher: .any
            )
        )
    }

    func remove(rule: ApiEndpoint, queryParams: QueryParams, bodyData: Data?) async {
        await remove(
            rule: .request(
                endpoint: rule,
                queryParams: queryParams,
                bodyMatcher: .exact(bodyData)
            )
        )
    }
}

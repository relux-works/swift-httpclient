import Foundation

// swiftlint:disable function_parameter_count
public actor RpcAsyncClientStubbable {
    private let logger: any HttpClientLogging
    private let client: IRpcAsyncClient
    private var rules: [ApiEndpoint: ApiResponse] = [:]
    private var requestRules: [RequestRule: ApiResponse] = [:]

    public init(
        client: IRpcAsyncClient,
        logger: any HttpClientLogging = DefaultLogger.shared
    ) {
        self.client = client
        self.logger = logger
    }
}

extension RpcAsyncClientStubbable: IRpcAsyncClient {
    public func get(
        url: URL,
        headers: Headers,
        fileID: String,
        functionName: String,
        lineNumber: Int
    ) async -> Result<ApiResponse, ApiError> {
        let endpoint = ApiEndpoint(path: url.description, type: .get)
        switch rules[endpoint] {
            case let .some(stub):
                self.logResponse(endpoint: endpoint, response: stub)
                return .success(stub)
            case .none:
                return await self.client.get(
                    url: url,
                    headers: headers,
                    fileID: fileID,
                    functionName: functionName,
                    lineNumber: lineNumber
                )
        }
    }

    public func get(
        url: URL,
        headers: Headers,
        retrys: RequestRetrys,
        fileID: String,
        functionName: String,
        lineNumber: Int
    ) async -> Result<ApiResponse, ApiError> {
        await get(
            url: url,
            headers: headers,
            retrys: .init(count: retrys.count, delay: retrys.delay),
            fileID: fileID,
            functionName: functionName,
            lineNumber: lineNumber
        )
    }

    public func get(
        url: URL,
        headers: Headers,
        retrys: RetryParams,
        fileID: String,
        functionName: String,
        lineNumber: Int
    ) async -> Result<ApiResponse, ApiError> {
        let endpoint = ApiEndpoint(path: url.description, type: .get)
        switch rules[endpoint] {
            case let .some(stub):
                self.logResponse(endpoint: endpoint, response: stub)
                return .success(stub)
            case .none:
                return await self.client.get(
                    url: url,
                    headers: headers,
                    retrys: retrys,
                    fileID: fileID,
                    functionName: functionName,
                    lineNumber: lineNumber
                )
        }
    }

    public func performAsync(
        endpoint: ApiEndpoint,
        headers: Headers,
        queryParams: QueryParams,
        bodyData: Data?,
        fileID: String,
        functionName: String,
        lineNumber: Int
    ) async -> Result<ApiResponse, ApiError> {
        switch self.stub(
            endpoint: endpoint,
            queryParams: queryParams,
            bodyData: bodyData
        ) {
            case let .some(stub):
                self.logResponse(endpoint: endpoint, response: stub)
                return .success(stub)
            case .none:
                return await self.performAsync(
                    endpoint: endpoint,
                    headers: headers,
                    queryParams: queryParams,
                    bodyData: bodyData,
                    retrys: .init(count: 0, delay: { 1.0 }),
                    fileID: fileID,
                    functionName: functionName,
                    lineNumber: lineNumber
                )
        }
    }

    public func performAsync(
        endpoint: HttpClient.ApiEndpoint,
        headers: HttpClient.Headers,
        queryParams: HttpClient.QueryParams,
        bodyData: Data?,
        retrys: RequestRetrys,
        fileID: String,
        functionName: String,
        lineNumber: Int
    ) async -> Result<HttpClient.ApiResponse, HttpClient.ApiError> {
        await performAsync(
            endpoint: endpoint,
            headers: headers,
            queryParams: queryParams,
            bodyData: bodyData,
            retrys: .init(count: retrys.count, delay: retrys.delay),
            fileID: fileID,
            functionName: functionName,
            lineNumber: lineNumber
        )
    }

    public func performAsync(
        endpoint: HttpClient.ApiEndpoint,
        headers: HttpClient.Headers,
        queryParams: HttpClient.QueryParams,
        bodyData: Data?,
        retrys: RetryParams,
        fileID: String,
        functionName: String,
        lineNumber: Int
    ) async -> Result<HttpClient.ApiResponse, HttpClient.ApiError> {
        switch self.stub(
            endpoint: endpoint,
            queryParams: queryParams,
            bodyData: bodyData
        ) {
            case let .some(stub):
                self.logResponse(endpoint: endpoint, response: stub)
                return .success(stub)
            case .none:
                return await self.client.performAsync(
                    endpoint: endpoint,
                    headers: headers,
                    queryParams: queryParams,
                    bodyData: bodyData,
                    retrys: retrys,
                    fileID: fileID,
                    functionName: functionName,
                    lineNumber: lineNumber
                )
        }
    }
}

extension RpcAsyncClientStubbable {
    private struct RequestRule: Hashable {
        let endpoint: ApiEndpoint
        let query: [QueryItem]
        let bodyMatcher: BodyMatcher

        init(endpoint: ApiEndpoint, queryParams: QueryParams, bodyMatcher: BodyMatcher) {
            self.endpoint = endpoint
            self.query = queryParams
                .map { QueryItem(key: $0.key, value: $0.value) }
                .sorted { lhs, rhs in
                    if lhs.key == rhs.key {
                        return lhs.value < rhs.value
                    }
                    return lhs.key < rhs.key
                }
            self.bodyMatcher = bodyMatcher
        }
    }

    private struct QueryItem: Hashable {
        let key: String
        let value: String
    }

    private enum BodyMatcher: Hashable {
        case any
        case exact(Data?)
    }

    private func stub(
        endpoint: ApiEndpoint,
        queryParams: QueryParams,
        bodyData: Data?
    ) -> ApiResponse? {
        let exactRule = RequestRule(
            endpoint: endpoint,
            queryParams: queryParams,
            bodyMatcher: .exact(bodyData)
        )
        if let stub = self.requestRules[exactRule] {
            return stub
        }

        let queryRule = RequestRule(
            endpoint: endpoint,
            queryParams: queryParams,
            bodyMatcher: .any
        )
        if let stub = self.requestRules[queryRule] {
            return stub
        }

        return self.rules[endpoint]
    }

    private func logResponse(endpoint: ApiEndpoint, response: ApiResponse) {
        let message = """
        🔵 response stubbed for: \(endpoint.type) \(endpoint.path)
        response code: \(response.code)
        response data: \(response.data?.utf8 ?? "")
        headers: \(response.headers.payloads)
        """
        logger.log(message)
    }
}
extension RpcAsyncClientStubbable: IRpcAsyncClientStubbable {
    public func upsert(rule: HttpClient.ApiEndpoint, stub: HttpClient.ApiResponse) async {
        self.rules[rule] = stub
    }

    public func upsert(rules: [HttpClient.ApiEndpoint: HttpClient.ApiResponse]) async {
        self.rules.merge(rules, uniquingKeysWith: { _, right in right })
    }

    public func upsert(
        rule: HttpClient.ApiEndpoint,
        queryParams: HttpClient.QueryParams,
        stub: HttpClient.ApiResponse
    ) async {
        self.requestRules[
            .init(endpoint: rule, queryParams: queryParams, bodyMatcher: .any)
        ] = stub
    }

    public func upsert(
        rule: HttpClient.ApiEndpoint,
        queryParams: HttpClient.QueryParams,
        bodyData: Data?,
        stub: HttpClient.ApiResponse
    ) async {
        self.requestRules[
            .init(endpoint: rule, queryParams: queryParams, bodyMatcher: .exact(bodyData))
        ] = stub
    }

    public func remove(rule: HttpClient.ApiEndpoint) async {
        self.rules.removeValue(forKey: rule)
    }

    public func remove(
        rule: HttpClient.ApiEndpoint,
        queryParams: HttpClient.QueryParams
    ) async {
        self.requestRules.removeValue(
            forKey: .init(endpoint: rule, queryParams: queryParams, bodyMatcher: .any)
        )
    }

    public func remove(
        rule: HttpClient.ApiEndpoint,
        queryParams: HttpClient.QueryParams,
        bodyData: Data?
    ) async {
        self.requestRules.removeValue(
            forKey: .init(
                endpoint: rule,
                queryParams: queryParams,
                bodyMatcher: .exact(bodyData)
            )
        )
    }

    public func removeAllRules() async {
        self.rules.removeAll()
        self.requestRules.removeAll()
    }
}

// swiftlint:enable function_parameter_count

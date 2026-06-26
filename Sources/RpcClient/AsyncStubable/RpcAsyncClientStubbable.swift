import Foundation

// swiftlint:disable function_parameter_count
public actor RpcAsyncClientStubbable {
    private let logger: any HttpClientLogging
    private let client: IRpcAsyncClient
    private var stubs: [RpcAsyncClientStub] = []
    private var responseCursors: [RpcAsyncClientStubKey: Int] = [:]

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
        switch self.stub(
            endpoint: endpoint,
            queryParams: [:],
            bodyData: nil
        ) {
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
        switch self.stub(
            endpoint: endpoint,
            queryParams: [:],
            bodyData: nil
        ) {
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
    private func stub(
        endpoint: ApiEndpoint,
        queryParams: QueryParams,
        bodyData: Data?
    ) -> ApiResponse? {
        let request = StubRequest(
            endpoint: endpoint,
            queryParams: queryParams,
            bodyData: bodyData
        )
        let matches = stubs
            .enumerated()
            .compactMap { index, stub -> StubCandidate? in
                guard stub.matches(request: request) else { return nil }
                return StubCandidate(
                    index: index,
                    key: stub.key,
                    specificity: stub.rule.specificity,
                    isConditional: stub.mode.isConditional,
                    responses: stub.responses
                )
            }
            .sorted { lhs, rhs in
                if lhs.specificity != rhs.specificity {
                    return lhs.specificity > rhs.specificity
                }
                if lhs.isConditional != rhs.isConditional {
                    return lhs.isConditional && !rhs.isConditional
                }
                return lhs.index < rhs.index
            }
        guard let match = matches.first else { return nil }
        return nextResponse(for: match)
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

    private func nextResponse(for candidate: StubCandidate) -> ApiResponse? {
        guard candidate.responses.isEmpty == false else { return nil }
        let cursor = responseCursors[candidate.key] ?? 0
        let responseIndex = min(cursor, candidate.responses.count - 1)
        responseCursors[candidate.key] = min(cursor + 1, candidate.responses.count - 1)
        return candidate.responses[responseIndex]
    }
}

private extension RpcAsyncClientStubbable {
    struct StubCandidate {
        let index: Int
        let key: RpcAsyncClientStubKey
        let specificity: Int
        let isConditional: Bool
        let responses: [ApiResponse]
    }
}
extension RpcAsyncClientStubbable: IRpcAsyncClientStubbable {
    public func upsert(stub: RpcAsyncClientStub) async {
        if let index = stubs.firstIndex(where: { $0.rule == stub.rule && $0.mode == stub.mode }) {
            stubs[index] = stub
        } else {
            stubs.append(stub)
        }
        responseCursors.removeValue(forKey: stub.key)
    }

    public func remove(rule: RpcAsyncClientStubRule) async {
        for stub in stubs where stub.rule == rule {
            responseCursors.removeValue(forKey: stub.key)
        }
        stubs.removeAll { $0.rule == rule }
    }

    public func removeAllRules() async {
        self.stubs.removeAll()
        self.responseCursors.removeAll()
    }
}

// swiftlint:enable function_parameter_count

private struct StubRequest {
    let endpoint: ApiEndpoint
    let queryParams: QueryParams
    let bodyData: Data?

    var mergedQueryParams: QueryParams {
        var merged: QueryParams = [:]
        if let components = URLComponents(string: endpoint.path) {
            for item in components.queryItems ?? [] {
                guard let value = item.value else { continue }
                merged[item.name] = value
            }
        }
        for (key, value) in queryParams {
            merged[key] = value
        }
        return merged
    }
}

private struct RpcAsyncClientStubKey: Sendable, Hashable {
    let rule: RpcAsyncClientStubRule
    let mode: RpcAsyncClientStubMode
}

private extension RpcAsyncClientStub {
    var key: RpcAsyncClientStubKey {
        RpcAsyncClientStubKey(rule: rule, mode: mode)
    }
}

private extension RpcAsyncClientStub {
    func matches(request: StubRequest) -> Bool {
        guard rule.matches(request: request) else { return false }
        return mode.matches(request: request)
    }
}

private extension RpcAsyncClientStubRule {
    var specificity: Int {
        switch self {
        case .endpoint:
            return 1
        case let .request(_, _, bodyMatcher):
            switch bodyMatcher {
            case .any:
                return 2
            case .exact:
                return 3
            }
        }
    }

    func matches(request: StubRequest) -> Bool {
        switch self {
        case let .endpoint(endpoint):
            return endpoint == request.endpoint
        case let .request(endpoint, queryParams, bodyMatcher):
            return endpoint == request.endpoint
                && queryParams == request.queryParams
                && bodyMatcher.matches(bodyData: request.bodyData)
        }
    }
}

private extension RpcAsyncClientStubBodyMatcher {
    func matches(bodyData: Data?) -> Bool {
        switch self {
        case .any:
            return true
        case let .exact(expected):
            return expected == bodyData
        }
    }
}

private extension RpcAsyncClientStubMode {
    var isConditional: Bool {
        switch self {
        case .absolute:
            return false
        case .conditional:
            return true
        }
    }

    func matches(request: StubRequest) -> Bool {
        switch self {
        case .absolute:
            return true
        case let .conditional(condition):
            return condition.matches(request: request)
        }
    }
}

private extension RpcAsyncClientStubCondition {
    func matches(request: StubRequest) -> Bool {
        switch self {
        case let .allSatisfy(conditions):
            return conditions.allSatisfy { $0.matches(request: request) }
        case let .anySatisfy(conditions):
            return conditions.contains { $0.matches(request: request) }
        case let .not(condition):
            return !condition.matches(request: request)
        case let .bodyContains(key, value):
            return request.bodyData?.jsonValue(forKey: key) == value
        case let .queryParameterContains(key, value):
            return request.mergedQueryParams[key] == value
        case let .value(value):
            return value
        }
    }
}

private extension Data {
    func jsonValue(forKey key: String) -> String? {
        guard let object = try? JSONSerialization.jsonObject(with: self),
              let value = Self.findValue(in: object, forKey: key)
        else { return nil }
        return Self.stringValue(from: value)
    }

    static func findValue(in object: Any, forKey key: String) -> Any? {
        if let dictionary = object as? [String: Any] {
            if let value = dictionary[key] {
                return value
            }
            for value in dictionary.values {
                if let found = findValue(in: value, forKey: key) {
                    return found
                }
            }
        }
        if let array = object as? [Any] {
            for value in array {
                if let found = findValue(in: value, forKey: key) {
                    return found
                }
            }
        }
        return nil
    }

    static func stringValue(from value: Any) -> String? {
        switch value {
        case let string as String:
            return string
        case let number as NSNumber:
            if CFGetTypeID(number) == CFBooleanGetTypeID() {
                return number.boolValue ? "true" : "false"
            }
            return number.stringValue
        case _ as NSNull:
            return nil
        default:
            return String(describing: value)
        }
    }
}

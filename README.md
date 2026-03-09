## HttpClient (swift-httpclient)

Lightweight networking toolkit with `async/await`, Combine, callback APIs, WebSockets, and built-in stubbing. Minimum platforms: iOS 13, watchOS 6, macOS 11, tvOS 13.

### Installation (Swift Package Manager)
In your `Package.swift` add:
```swift
.package(url: "https://github.com/relux-works/swift-httpclient.git", from: "1.0.0")
```
Link the product:
```swift
.product(name: "HttpClient", package: "swift-httpclient")
```

### Quick Start (HTTP)
```swift
let client = RpcClient()
let endpoint = ApiEndpoint(path: "https://api.example.com/users", type: .get)
let result = await client.performAsync(
    endpoint: endpoint,
    headers: [.authorization: .bearer(token: "token")],
    queryParams: ["page": "1"],
    bodyData: nil
)
```
- Combine: `RpcClient().get(path: "...", headers: [:], queryParams: [:])` returns `AnyPublisher<ApiResponse, ApiError>`.
- Callbacks: use `IRpcCompletionClient` methods.
- Retries: pass `RetryParams(count: 3, delay: { 1.0 })` to `performAsync`/`get` for automatic retry logic.

### WebSockets
Prefer `PublishedWSClient`: publishes incoming messages and connection state via Combine, keeps the connection alive (`pingInterval`), and auto-reconnects (`reconnectInterval`). `WSClient` is experimental.

### Stubbing
- HTTP: wrap real clients with `RpcAsyncClientStubbable(client: RpcClient())`.
  - Recommended API for UI-test setup (less boilerplate):
    ```swift
    await stubbable.upsert(stubs: [
        .init(endpoint: loginEndpoint, response: loginResponse),
        .init(endpoint: feedEndpoint, queryParams: ["page": "1"], response: page1Response),
        .init(
            endpoint: searchEndpoint,
            queryParams: ["mode": "strict"],
            bodyData: payload,
            response: strictSearchResponse
        )
    ])
    ```
  - Fine-grained matching uses `RpcAsyncClientStubRule` + `RpcAsyncClientStubBodyMatcher` (`.any` / `.exact(Data?)`).
  - Compatibility helpers are still available: `upsert(rule:...)`, `upsert(rules:...)`, `remove(rule:...)`, `removeAllRules()`.
- WebSocket: `PublishedStubbableWSClient` lets you stub responses for outgoing messages. JSON bodies can be normalized with `Data.stableNormalizedJSONString`.

### Logging
All clients accept any `HttpClientLogging`; default is `DefaultLogger.shared`. Inject your own logger for production.

### Session Config & SSL
- Build `URLSessionConfiguration` with `ApiSessionConfigBuilder.buildConfig(timeoutForResponse:timeoutResourceInterval:disableCookieStorage:)`.
- TLS pinning helpers live in `Sources/SSLPinning/`; extend `CertVerificationChallenge` with your pinned certificates.

### Testing
```bash
swift test
swift test --enable-code-coverage
```

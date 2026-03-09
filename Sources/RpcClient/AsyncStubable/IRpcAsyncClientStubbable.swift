import Foundation

public protocol IRpcAsyncClientStubbable: IRpcAsyncClient {
    func upsert(rule: ApiEndpoint, stub: ApiResponse) async
    func upsert(rules: [ApiEndpoint: ApiResponse]) async
    func upsert(rule: ApiEndpoint, queryParams: QueryParams, stub: ApiResponse) async
    func upsert(rule: ApiEndpoint, queryParams: QueryParams, bodyData: Data?, stub: ApiResponse) async
    func remove(rule: ApiEndpoint) async
    func remove(rule: ApiEndpoint, queryParams: QueryParams) async
    func remove(rule: ApiEndpoint, queryParams: QueryParams, bodyData: Data?) async
    func removeAllRules() async
}

public extension IRpcAsyncClientStubbable {
    func upsert(rule: ApiEndpoint, queryParams: QueryParams, stub: ApiResponse) async {
        await upsert(rule: rule, stub: stub)
    }

    func upsert(rule: ApiEndpoint, queryParams: QueryParams, bodyData: Data?, stub: ApiResponse) async {
        await upsert(rule: rule, queryParams: queryParams, stub: stub)
    }

    func remove(rule: ApiEndpoint, queryParams: QueryParams) async {
        await remove(rule: rule)
    }

    func remove(rule: ApiEndpoint, queryParams: QueryParams, bodyData: Data?) async {
        await remove(rule: rule, queryParams: queryParams)
    }
}

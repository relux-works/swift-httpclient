import Foundation

public struct ApiEndpoint: Sendable, Hashable, CustomStringConvertible, CustomDebugStringConvertible {
    public let path: String
    public let type: ApiRequestType
    
    public init(
        path: String,
        type: ApiRequestType
    ) {
        self.path = path
        self.type = type
    }
    
    init(from apiFullEndpoint: ApiFullEndpoint) {
        self.path = apiFullEndpoint.url.absoluteString
        self.type = apiFullEndpoint.type
    }

    public var description: String {
        "\(type.rawValue) \(displayPath)"
    }

    public var debugDescription: String {
        description
    }

    private var displayPath: String {
        if let url = URL(string: path),
           let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           components.scheme != nil,
           !components.path.isEmpty {
            return components.path
        }

        if path.hasPrefix("/") {
            return path
        }

        return "/\(path)"
    }
}

#warning("Refactor library to use proper endpoint semantics")
// in ApiEndpoint path should be path component not including base url
public struct ApiFullEndpoint {
    public let baseUrl: URL
    public let path: String
    public let type: ApiRequestType
    
    public init(
        baseUrl: URL,
        path: String,
        type: ApiRequestType
    ) {
        self.baseUrl = baseUrl
        self.path = path
        self.type = type
    }
    
    public var url: URL {
        return baseUrl.appendingPathComponent(path)
    }
}

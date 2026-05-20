import Foundation

extension RpcClient {
    static func create_cURL(requestType: ApiRequestType, path: URL, headers: [HeaderKey: HeaderValue], bodyData: Data?) -> String {
        let headerLines = headers
            .map { "-H '\($0.key): \($0.value)'" }
            .joined(separator: "\\\n     ")
        let headersPart = headerLines.isEmpty ? "" : " \\\n     \(headerLines)"
        let bodyPart = bodyData.map { " \\\n     -d $'\($0.utf8 ?? "")'" } ?? ""
        let string = """
                     curl -vX "\(requestType.rawValue)" "\(path.description)"\(headersPart)\(bodyPart)
                     """
        return string
    }
}

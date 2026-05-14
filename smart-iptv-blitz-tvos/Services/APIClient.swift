import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
}

final class APIClient {
    private let baseURL: URL
    private let session: URLSession
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init(baseURL: URL = AppConstants.baseURL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func request<Response: Decodable, Body: Encodable>(
        _ responseType: Response.Type,
        path: String,
        method: HTTPMethod,
        bearerToken: String? = nil,
        queryItems: [URLQueryItem] = [],
        body: Body? = nil
    ) async throws -> Response {
        let data = try await rawRequest(
            path: path,
            method: method,
            bearerToken: bearerToken,
            queryItems: queryItems,
            body: body
        )
        return try decoder.decode(Response.self, from: data)
    }

    func request<Response: Decodable>(
        _ responseType: Response.Type,
        path: String,
        method: HTTPMethod,
        bearerToken: String? = nil,
        queryItems: [URLQueryItem] = []
    ) async throws -> Response {
        let emptyBody: EmptyRequestBody? = nil
        return try await request(
            responseType,
            path: path,
            method: method,
            bearerToken: bearerToken,
            queryItems: queryItems,
            body: emptyBody
        )
    }

    private func rawRequest<Body: Encodable>(
        path: String,
        method: HTTPMethod,
        bearerToken: String?,
        queryItems: [URLQueryItem],
        body: Body?
    ) async throws -> Data {
        guard let url = makeURL(path: path, queryItems: queryItems) else {
            throw APIFlowError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.timeoutInterval = 25
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let bearerToken, !bearerToken.isEmpty {
            let header = bearerToken.hasPrefix("Bearer ") ? bearerToken : "Bearer \(bearerToken)"
            request.setValue(header, forHTTPHeaderField: "Authorization")
        }

        let requestBodyData: Data?
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let encodedBody = try encoder.encode(body)
            request.httpBody = encodedBody
            requestBodyData = encodedBody
        } else {
            requestBodyData = nil
        }

        APIDebugLogger.logRequest(
            method: method.rawValue,
            url: url,
            headers: request.allHTTPHeaderFields ?? [:],
            bodyData: requestBodyData
        )

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            APIDebugLogger.log("error method=\(method.rawValue) url=\(url.absoluteString) message=\(error.localizedDescription)")
            throw error
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            APIDebugLogger.log("response method=\(method.rawValue) url=\(url.absoluteString) status=invalid body=none")
            throw APIFlowError.invalidResponse
        }

        APIDebugLogger.logResponse(
            method: method.rawValue,
            url: url,
            statusCode: httpResponse.statusCode,
            data: data
        )

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw APIFlowError.server(
                statusCode: httpResponse.statusCode,
                message: String(data: data, encoding: .utf8)
            )
        }

        return data
    }

    private func makeURL(path: String, queryItems: [URLQueryItem]) -> URL? {
        guard let relative = URL(string: path, relativeTo: baseURL),
              var components = URLComponents(url: relative, resolvingAgainstBaseURL: true) else {
            return nil
        }
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        return components.url
    }
}

private struct EmptyRequestBody: Encodable {}

enum APIDebugLogger {
    nonisolated static func log(_ message: String) {
        #if DEBUG
        print("[API DEBUG] \(message)")
        #endif
    }
}

private extension APIDebugLogger {
    nonisolated static func logRequest(
        method: String,
        url: URL,
        headers: [String: String],
        bodyData: Data?
    ) {
        log(
            "request method=\(method) url=\(url.absoluteString) headers=\(compactHeaders(headers)) body=\(compactPayload(bodyData))"
        )
    }

    nonisolated static func logResponse(
        method: String,
        url: URL,
        statusCode: Int,
        data: Data
    ) {
        log(
            "response method=\(method) url=\(url.absoluteString) status=\(statusCode) body=\(compactPayload(data))"
        )
    }

    nonisolated static func compactHeaders(_ headers: [String: String]) -> String {
        guard !headers.isEmpty else { return "none" }

        let pairs = headers
            .sorted { $0.key.localizedCaseInsensitiveCompare($1.key) == .orderedAscending }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: ", ")

        return "{\(pairs)}"
    }

    nonisolated static func compactPayload(_ data: Data?) -> String {
        guard let data, !data.isEmpty else { return "none" }

        if
            let jsonObject = try? JSONSerialization.jsonObject(with: data),
            let compactData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.sortedKeys]),
            let compactString = String(data: compactData, encoding: .utf8)
        {
            return compactString
        }

        if let string = String(data: data, encoding: .utf8) {
            return string
                .replacingOccurrences(of: "\n", with: "\\n")
                .replacingOccurrences(of: "\r", with: "\\r")
        }

        return "<\(data.count) bytes>"
    }
}

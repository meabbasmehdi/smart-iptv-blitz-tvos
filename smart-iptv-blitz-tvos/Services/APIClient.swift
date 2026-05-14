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

        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try encoder.encode(body)
        }

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIFlowError.invalidResponse
        }

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

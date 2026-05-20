import Foundation

final class LiveTVService {
    private let apiClient: APIClient
    private let authDeviceService: AuthDeviceService
    private let preferences: PreferenceStore
    private let maxPageLimit = 64

    init(
        apiClient: APIClient,
        authDeviceService: AuthDeviceService,
        preferences: PreferenceStore
    ) {
        self.apiClient = apiClient
        self.authDeviceService = authDeviceService
        self.preferences = preferences
    }

    func fetchLiveContent() async throws -> LiveTVContent {
        guard let playlistID = preferences.int64(forKey: PreferenceKeys.activePlaylistID) else {
            throw APIFlowError.invalidResponse
        }

        let token = try await authDeviceService.ensureValidToken()
        let streams = try await fetchDefaultPlaylistPages(
            playlistID: playlistID,
            bearerToken: "Bearer \(token)"
        )
        let channels = streams.compactMap(makeChannel)
        return LiveTVContent(
            categories: makeCategories(from: channels),
            channels: channels
        )
    }

    func playableURL(for channel: LiveTVChannel) -> URL? {
        if let xtreamURL = xtreamURL(for: channel.streamID) {
            return xtreamURL
        }

        if let directURL = validatedURL(channel.directSource) {
            return directURL
        }

        return validatedURL(channel.streamID)
    }

    private func xtreamURL(for streamID: String?) -> URL? {
        let source = preferences.string(forKey: PreferenceKeys.activePlaylistSource).lowercased()
        guard source == PlaylistSource.xtream.rawValue,
              let streamID = streamID?.trimmingCharacters(in: .whitespacesAndNewlines),
              let server = preferences.stringOptional(forKey: PreferenceKeys.activePlaylistURL)?.trimmingCharacters(in: .whitespacesAndNewlines),
              let username = preferences.stringOptional(forKey: PreferenceKeys.activePlaylistUsername)?.trimmingCharacters(in: .whitespacesAndNewlines),
              let password = preferences.stringOptional(forKey: PreferenceKeys.activePlaylistPassword)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !streamID.isEmpty,
              !server.isEmpty,
              !username.isEmpty,
              !password.isEmpty else {
            return nil
        }

        let normalizedServer = server.hasSuffix("/") ? String(server.dropLast()) : server
        return URL(string: "\(normalizedServer)/live/\(username)/\(password)/\(streamID).ts")
    }

    private func validatedURL(_ rawValue: String?) -> URL? {
        guard let rawValue = rawValue?.trimmingCharacters(in: .whitespacesAndNewlines),
              !rawValue.isEmpty,
              let url = URL(string: rawValue),
              url.scheme != nil else {
            return nil
        }
        return url
    }

    private func fetchDefaultPlaylistPages(
        playlistID: Int64,
        bearerToken: String
    ) async throws -> [DefaultPlaylistStreamResponse] {
        var aggregated: [DefaultPlaylistStreamResponse] = []
        var currentPage = 1
        var maxPageToFetch: Int?

        while true {
            if let maxPageToFetch, currentPage > maxPageToFetch {
                break
            }
            if maxPageToFetch == nil, currentPage > maxPageLimit {
                break
            }

            let response = try await apiClient.request(
                DefaultPlaylistStreamListResponse.self,
                path: "iptv/smart/playlist/default/\(playlistID)/\(currentPage)/streams/",
                method: .get,
                bearerToken: bearerToken
            )

            guard response.success else {
                break
            }

            if let pagesEmitted = response.pagesEmitted, pagesEmitted > 0 {
                maxPageToFetch = min(pagesEmitted, maxPageLimit)
            }

            let pageData = response.data ?? []
            aggregated.append(contentsOf: pageData)

            currentPage += 1
        }

        return aggregated
    }

    private func makeChannel(from stream: DefaultPlaylistStreamResponse) -> LiveTVChannel? {
        guard stream.streamType?.lowercased() == "live" else {
            return nil
        }

        let title = stream.title?.nonEmpty
            ?? stream.altTitle?.nonEmpty
            ?? "Live TV"
        let categoryID = stream.categoryID?.nonEmpty ?? "Uncategorized"
        let url = stream.directSource ?? stream.streamID ?? title

        return LiveTVChannel(
            id: syntheticID(name: title, url: url),
            title: title,
            categoryID: categoryID,
            categoryTitle: categoryID,
            streamID: stream.streamID,
            streamIcon: stream.streamIcon,
            directSource: stream.directSource
        )
    }

    private func makeCategories(from channels: [LiveTVChannel]) -> [LiveTVCategory] {
        let grouped = Dictionary(grouping: channels, by: \.categoryID)
        let categoryRows = grouped.map { categoryID, channels in
            LiveTVCategory(
                id: categoryID,
                title: channels.first?.categoryTitle.nonEmpty ?? "Uncategorized",
                count: channels.count
            )
        }
        .sorted {
            $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
        }

        return [LiveTVCategory(id: LiveTVCategoryID.all, title: "All", count: channels.count)] + categoryRows
    }

    private func syntheticID(name: String?, url: String) -> Int {
        let seed = "\(name ?? "")-\(url)"
        var hash = 5381
        for scalar in seed.unicodeScalars {
            hash = ((hash << 5) &+ hash) &+ Int(scalar.value)
        }
        return hash == Int.min ? Int.max : abs(hash)
    }
}

enum LiveTVCategoryID {
    static let all = "__all__"
}

private extension String {
    var nonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

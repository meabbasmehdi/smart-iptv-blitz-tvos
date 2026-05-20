import Combine
import Foundation

@MainActor
final class LiveTVViewModel: ObservableObject {
    @Published private(set) var categories: [LiveTVCategory] = []
    @Published private(set) var channels: [LiveTVChannel] = []
    @Published private(set) var selectedCategoryID = LiveTVCategoryID.all
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published var playerChannel: LiveTVPlayerChannel?

    private let service: LiveTVService
    private var allChannels: [LiveTVChannel] = []

    init(service: LiveTVService) {
        self.service = service
    }

    func load() async {
        guard !isLoading else { return }
        guard categories.isEmpty, allChannels.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        do {
            let content = try await service.fetchLiveContent()
            categories = content.categories
            allChannels = content.channels
            selectedCategoryID = content.categories.first?.id ?? LiveTVCategoryID.all
            channels = filteredChannels(for: selectedCategoryID)
        } catch {
            categories = []
            allChannels = []
            channels = []
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func selectCategory(_ category: LiveTVCategory) {
        selectedCategoryID = category.id
        channels = filteredChannels(for: category.id)
    }

    func openChannel(_ channel: LiveTVChannel) {
        playerChannel = nil
        errorMessage = nil

        guard let url = service.playableURL(for: channel) else {
            errorMessage = "Unable to resolve stream URL."
            return
        }

        playerChannel = LiveTVPlayerChannel(
            id: channel.id,
            title: channel.title,
            url: url
        )
    }

    func clearPlayer() {
        playerChannel = nil
    }

    private func filteredChannels(for categoryID: String) -> [LiveTVChannel] {
        guard categoryID != LiveTVCategoryID.all else {
            return allChannels
        }
        return allChannels.filter { $0.categoryID == categoryID }
    }
}

struct LiveTVPlayerChannel: Identifiable, Equatable {
    let id: Int
    let title: String
    let url: URL
}

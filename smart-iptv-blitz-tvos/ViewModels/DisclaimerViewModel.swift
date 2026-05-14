import Combine
import Foundation

@MainActor
final class DisclaimerViewModel: ObservableObject {
    @Published var showSplash = false
    @Published var disclaimerVersion = ""
    @Published var title = "Disclaimer"
    @Published var description = ""
    @Published var isLoading = true
    @Published var errorMessage: String?

    private let disclaimerService: DisclaimerService
    private let preferences: PreferenceStore
    private var hasLoaded = false

    init(disclaimerService: DisclaimerService, preferences: PreferenceStore) {
        self.disclaimerService = disclaimerService
        self.preferences = preferences
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        hasLoaded = true
        await loadDisclaimer()
    }

    func retry() async {
        await loadDisclaimer()
    }

    func onAgree() {
        let versionToStore = disclaimerVersion.isEmpty
            ? preferences.string(forKey: PreferenceKeys.disclaimerVersion)
            : disclaimerVersion
        disclaimerService.accept(version: versionToStore.isEmpty ? nil : versionToStore)
    }

    func onDeny() {
        showSplash = true
    }

    func onSplashStart() {
        showSplash = false
    }

    var displayDescription: String {
        HTMLText.plainText(from: description)
    }

    private func loadDisclaimer() async {
        isLoading = true
        errorMessage = nil
        let storedVersion = preferences.string(forKey: PreferenceKeys.disclaimerVersion)

        do {
            let response = try await disclaimerService.fetchLatestDisclaimer(version: storedVersion)
            title = response.title?.isEmpty == false ? response.title! : "Disclaimer"
            description = response.description ?? ""
            disclaimerVersion = response.version?.isEmpty == false ? response.version! : storedVersion
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}

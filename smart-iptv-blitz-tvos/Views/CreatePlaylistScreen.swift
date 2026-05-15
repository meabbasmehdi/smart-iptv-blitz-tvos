import SwiftUI

struct CreatePlaylistScreen: View {
    @ObservedObject var viewModel: CreatePlaylistViewModel
    let onDemoPlaylistAdded: () -> Void

    @FocusState private var focusedItem: PlaylistLandingFocus?
    @State private var lastFocusedCard: PlaylistLandingFocus = .xtream
    @State private var mode: CreatePlaylistMode = .landing

    var body: some View {
        switch mode {
        case .landing:
            landingView
        case .demoConfirmation:
            DemoPlaylistConfirmationScreen(
                viewModel: viewModel,
                onCancel: {
                    viewModel.clearError()
                    mode = .landing
                },
                onAdded: onDemoPlaylistAdded
            )
        }
    }

    private var landingView: some View {
        GeometryReader { proxy in
            let scale = min(proxy.size.width / 1280, proxy.size.height / 720)

            ZStack(alignment: .topLeading) {
                FigmaScreenBackground {
                    EmptyView()
                }

                Text("Smart IPTV")
                    .font(AppTypography.titleSemibold(scale: scale))
                    .foregroundStyle(.white)
                    .offset(x: scaled(60, scale), y: scaled(60, scale))

                HStack(spacing: scaled(28, scale)) {
                    CreatePlaylistHeaderIcon(imageName: AppImages.wifiIcon, scale: scale)

                    CreatePlaylistHeaderIcon(imageName: AppImages.settingsIcon, scale: scale)
                }
                .offset(x: scaled(732, scale), y: scaled(67, scale))

                PlaylistClock(scale: scale)

                XtreamPlaylistCard(scale: scale, isFocused: focusedItem == .xtream) {}
                    .focused($focusedItem, equals: .xtream)
                    .offset(
                        x: scaled(focusedItem == .xtream ? 49.86 : 59.79, scale),
                        y: scaled(focusedItem == .xtream ? 271 : 285.5, scale)
                    )

                PlaylistURLCard(scale: scale, isFocused: focusedItem == .playlistURL) {}
                    .focused($focusedItem, equals: .playlistURL)
                    .offset(
                        x: scaled(focusedItem == .playlistURL ? 328.07 : 338, scale),
                        y: scaled(focusedItem == .playlistURL ? 270.5 : 285, scale)
                    )

                DemoPlaylistFocusButton(scale: scale, isFocused: focusedItem == .demo) {
                    viewModel.clearError()
                    mode = .demoConfirmation
                }
                    .focused($focusedItem, equals: .demo)
                    .offset(x: scaled(515.95, scale), y: scaled(656, scale))
            }
            .frame(width: scaled(1280, scale), height: scaled(720, scale))
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
        .ignoresSafeArea()
        .onAppear {
            focusedItem = .xtream
        }
        .onMoveCommand { direction in
            moveFocus(direction)
        }
        #if os(tvOS)
        .defaultFocus($focusedItem, .xtream)
        #endif
    }

    private func scaled(_ value: CGFloat, _ scale: CGFloat) -> CGFloat {
        value * scale
    }

    private func moveFocus(_ direction: MoveCommandDirection) {
        switch direction {
        case .left:
            if focusedItem == .playlistURL {
                focusedItem = .xtream
                lastFocusedCard = .xtream
            }
        case .right:
            if focusedItem == .xtream {
                focusedItem = .playlistURL
                lastFocusedCard = .playlistURL
            }
        case .up:
            if focusedItem == .demo {
                focusedItem = lastFocusedCard
            }
        case .down:
            if focusedItem == .xtream || focusedItem == .playlistURL {
                lastFocusedCard = focusedItem ?? .xtream
                focusedItem = .demo
            }
        @unknown default:
            break
        }
    }
}

private enum CreatePlaylistMode {
    case landing
    case demoConfirmation
}

private enum PlaylistLandingFocus: Hashable {
    case xtream
    case playlistURL
    case demo
}

private enum DemoPlaylistFocus: Hashable {
    case legalConfirmation
    case add
    case cancel
}

private struct CreatePlaylistHeaderIcon: View {
    let imageName: String
    let scale: CGFloat

    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFit()
            .foregroundStyle(.white)
            .frame(width: scaled(24), height: scaled(24))
    }

    private func scaled(_ value: CGFloat) -> CGFloat {
        value * scale
    }
}

private struct DemoPlaylistConfirmationScreen: View {
    @ObservedObject var viewModel: CreatePlaylistViewModel
    let onCancel: () -> Void
    let onAdded: () -> Void

    @FocusState private var focusedElement: DemoPlaylistFocus?
    @State private var isConfirmed = false
    @State private var validationMessage: String?

    var body: some View {
        GeometryReader { proxy in
            let scale = min(proxy.size.width / 1280, proxy.size.height / 720)

            ZStack(alignment: .topLeading) {
                FigmaScreenBackground {
                    EmptyView()
                }

                Text("Smart IPTV")
                    .font(AppTypography.titleSemibold(scale: scale))
                    .foregroundStyle(.white)
                    .offset(x: scaled(60, scale), y: scaled(60, scale))

                HStack(spacing: scaled(28, scale)) {
                    CreatePlaylistHeaderIcon(imageName: AppImages.wifiIcon, scale: scale)

                    CreatePlaylistHeaderIcon(imageName: AppImages.settingsIcon, scale: scale)
                }
                .offset(x: scaled(732, scale), y: scaled(67, scale))

                PlaylistClock(scale: scale)

                Text("Let’s set up a playlist")
                    .font(.app(size: scaled(44, scale), weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: scaled(661, scale), alignment: .center)
                    .offset(x: scaled(310, scale), y: scaled(124, scale))

                Text("Import your playlist or get familiar with the app using a demo playlist")
                    .font(.app(size: scaled(24, scale), weight: .regular))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(width: scaled(511, scale), height: scaled(68, scale), alignment: .top)
                    .offset(x: scaled(384.5, scale), y: scaled(213, scale))

                RoundedRectangle(cornerRadius: scaled(24, scale), style: .continuous)
                    .fill(AppColors.dialogSurface)
                    .frame(width: scaled(900, scale), height: scaled(380, scale))
                    .offset(x: scaled(190, scale), y: scaled(310, scale))

                Text("We’ve Discovered a Compilation of Publicly Available IPTV Channels")
                    .font(.app(size: scaled(24, scale), weight: .medium))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(width: scaled(715, scale), height: scaled(58, scale), alignment: .top)
                    .offset(x: scaled(282.5, scale), y: scaled(338, scale))

                Text("Interested in Adding this Playlist?")
                    .font(.app(size: scaled(18, scale), weight: .regular))
                    .foregroundStyle(.white)
                    .frame(width: scaled(376, scale), height: scaled(26, scale), alignment: .center)
                    .offset(x: scaled(452, scale), y: scaled(433, scale))

                Text("GitHub - Free IPTV Playlist")
                    .font(.app(size: scaled(24, scale), weight: .medium))
                    .foregroundStyle(AppColors.brandSecondary)
                    .frame(width: scaled(376, scale), height: scaled(34, scale), alignment: .center)
                    .offset(x: scaled(452, scale), y: scaled(490, scale))

                HStack(alignment: .top, spacing: scaled(9.5, scale)) {
                    DemoPlaylistCheckbox(
                        scale: scale,
                        isChecked: isConfirmed,
                        isFocused: focusedElement == .legalConfirmation
                    ) {
                        isConfirmed.toggle()
                        validationMessage = nil
                        viewModel.clearError()
                    }
                    .focused($focusedElement, equals: .legalConfirmation)

                    legalText(scale: scale)
                        .frame(width: scaled(368, scale), height: scaled(40, scale), alignment: .leading)
                }
                .offset(x: scaled(319, scale), y: scaled(552, scale))

                DemoPlaylistActionButton(
                    title: viewModel.isAddingDemoPlaylist ? "Adding..." : "Add Playlist",
                    scale: scale,
                    isFocused: focusedElement == .add,
                    isDisabled: viewModel.isAddingDemoPlaylist
                ) {
                    addPlaylist()
                }
                .focused($focusedElement, equals: .add)
                .offset(x: scaled(328, scale), y: scaled(610, scale))

                DemoPlaylistActionButton(
                    title: "Cancel",
                    scale: scale,
                    isFocused: focusedElement == .cancel,
                    isDisabled: viewModel.isAddingDemoPlaylist,
                    focusedBackground: AppColors.brandPrimary
                ) {
                    onCancel()
                }
                .focused($focusedElement, equals: .cancel)
                .offset(x: scaled(631, scale), y: scaled(610, scale))

                if let statusText = validationMessage ?? viewModel.errorMessage {
                    Text(statusText)
                        .font(.app(size: scaled(14, scale), weight: .medium))
                        .foregroundStyle(AppColors.error)
                        .lineLimit(1)
                        .frame(width: scaled(710, scale), alignment: .center)
                        .offset(x: scaled(285, scale), y: scaled(681, scale))
                }
            }
            .frame(width: scaled(1280, scale), height: scaled(720, scale))
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
        .ignoresSafeArea()
        .onAppear {
            focusedElement = .cancel
        }
        .onMoveCommand { direction in
            moveFocus(direction)
        }
        .onExitCommand {
            onCancel()
        }
        #if os(tvOS)
        .defaultFocus($focusedElement, .cancel)
        #endif
    }

    private func legalText(scale: CGFloat) -> Text {
        var legal = AttributedString("I confirm that i have checked the legality of this source, and I agree to the    ")
        legal.font = .app(size: scaled(16, scale), weight: .regular)
        legal.foregroundColor = .white

        var terms = AttributedString("Terms & Conditions")
        terms.font = .app(size: scaled(16, scale), weight: .bold)
        terms.foregroundColor = AppColors.brandSecondary

        legal.append(terms)
        return Text(legal)
    }

    private func addPlaylist() {
        guard isConfirmed else {
            validationMessage = "Please confirm the legality notice before adding the playlist."
            focusedElement = .legalConfirmation
            return
        }

        validationMessage = nil
        Task {
            if await viewModel.addDemoPlaylist() {
                onAdded()
            }
        }
    }

    private func moveFocus(_ direction: MoveCommandDirection) {
        switch direction {
        case .left:
            if focusedElement == .cancel {
                focusedElement = .add
            }
        case .right:
            if focusedElement == .add {
                focusedElement = .cancel
            }
        case .up:
            if focusedElement == .add || focusedElement == .cancel {
                focusedElement = .legalConfirmation
            }
        case .down:
            if focusedElement == .legalConfirmation {
                focusedElement = .add
            }
        @unknown default:
            break
        }
    }

    private func scaled(_ value: CGFloat, _ scale: CGFloat) -> CGFloat {
        value * scale
    }
}

private struct DemoPlaylistCheckbox: View {
    let scale: CGFloat
    let isChecked: Bool
    let isFocused: Bool
    let action: () -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: scaled(8.269), style: .continuous)
                .fill(isChecked ? AppColors.brandSecondary : AppColors.cardBackground)
                .frame(width: scaled(30.321), height: scaled(30.321))
                .overlay(
                    RoundedRectangle(cornerRadius: scaled(8.269), style: .continuous)
                        .stroke(isFocused ? AppColors.brandSecondary : .clear, lineWidth: scaled(2))
                )

            if isChecked {
                Image(systemName: "checkmark")
                    .font(.system(size: scaled(16), weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: scaled(30.321), height: scaled(30.321))
        .contentShape(RoundedRectangle(cornerRadius: scaled(8.269), style: .continuous))
        .focusable(true)
        .focusEffectDisabled()
        .onTapGesture(perform: action)
        .accessibilityAddTraits(.isButton)
        .animation(.easeOut(duration: 0.12), value: isFocused)
        .animation(.easeOut(duration: 0.12), value: isChecked)
    }

    private func scaled(_ value: CGFloat) -> CGFloat {
        value * scale
    }
}

private struct DemoPlaylistActionButton: View {
    let title: String
    let scale: CGFloat
    let isFocused: Bool
    let isDisabled: Bool
    var focusedBackground: Color = AppColors.brandPrimary
    let action: () -> Void

    var body: some View {
        Text(title)
            .font(.app(size: scaled(24), weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: scaled(285), height: scaled(64))
            .background(
                Capsule(style: .continuous)
                    .fill(isFocused ? focusedBackground : AppColors.cardBackground)
            )
            .opacity(isDisabled ? 0.65 : 1)
            .contentShape(Capsule(style: .continuous))
            .focusable(true)
            .focusEffectDisabled()
            .onTapGesture {
                guard !isDisabled else { return }
                action()
            }
            .accessibilityAddTraits(.isButton)
            .animation(.easeOut(duration: 0.12), value: isFocused)
            .animation(.easeOut(duration: 0.12), value: isDisabled)
    }

    private func scaled(_ value: CGFloat) -> CGFloat {
        value * scale
    }
}

private struct XtreamPlaylistCard: View {
    let scale: CGFloat
    let isFocused: Bool
    let action: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            PlaylistLandingCardBackground(
                scale: scale,
                width: cardWidth,
                height: cardHeight,
                cornerRadius: 12.974,
                isFocused: isFocused
            )

            Image(AppImages.xtreamCardIcon)
                .resizable()
                .scaledToFill()
                .frame(
                    width: scaled(isFocused ? 101.683 : 101.629),
                    height: scaled(isFocused ? 101.683 : 101.629)
                )
                .clipped()
                .offset(
                    x: scaled(isFocused ? 83 : 74.185),
                    y: scaled(isFocused ? 52.14 : 46)
                )

            Text("Xtream")
                .font(.app(size: scaled(isFocused ? 25.948 : 24), weight: .medium))
                .foregroundStyle(.white)
                .frame(width: scaled(cardWidth), alignment: .center)
                .offset(x: 0, y: scaled(isFocused ? 177.79 : 164))

            Text("Easily connect your account\nusing Xtream Codes.")
                .font(.app(size: scaled(isFocused ? 17.299 : 16), weight: .medium))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(
                    width: scaled(isFocused ? 227.758 : 211),
                    height: scaled(isFocused ? 109.49 : 101),
                    alignment: .top
                )
                .offset(
                    x: scaled(isFocused ? 21.05 : 19.5),
                    y: scaled(isFocused ? 241.74 : 223)
                )

        }
        .frame(width: scaled(cardWidth), height: scaled(cardHeight), alignment: .topLeading)
        .contentShape(RoundedRectangle(cornerRadius: scaled(12.974), style: .continuous))
        .focusable(true)
        .focusEffectDisabled()
        .onTapGesture(perform: action)
        .accessibilityAddTraits(.isButton)
        .animation(.easeOut(duration: 0.12), value: isFocused)
    }

    private func scaled(_ value: CGFloat) -> CGFloat {
        value * scale
    }

    private var cardWidth: CGFloat {
        isFocused ? 269.855 : 250
    }

    private var cardHeight: CGFloat {
        isFocused ? 374 : 345
    }
}

private struct PlaylistURLCard: View {
    let scale: CGFloat
    let isFocused: Bool
    let action: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            PlaylistLandingCardBackground(
                scale: scale,
                width: cardWidth,
                height: cardHeight,
                cornerRadius: 12,
                isFocused: isFocused
            )

            Image(AppImages.m3uCardIcon)
                .resizable()
                .scaledToFill()
                .frame(
                    width: scaled(isFocused ? 77.72 : 72),
                    height: scaled(isFocused ? 116.58 : 108)
                )
                .clipped()
                .offset(
                    x: scaled(isFocused ? 96.07 : 89),
                    y: scaled(isFocused ? 52.14 : 40)
                )

            Text("Playlist URL")
                .font(.app(size: scaled(isFocused ? 25.948 : 24), weight: .medium))
                .foregroundStyle(.white)
                .frame(width: scaled(cardWidth), alignment: .center)
                .offset(x: 0, y: scaled(isFocused ? 177.79 : 164))

            Text("Just paste your M3U link to\nload your playlist.")
                .font(.app(size: scaled(isFocused ? 17.299 : 16), weight: .medium))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(
                    width: scaled(isFocused ? 227.758 : 211),
                    height: scaled(isFocused ? 109.49 : 101),
                    alignment: .top
                )
                .offset(
                    x: scaled(isFocused ? 21.05 : 19.5),
                    y: scaled(isFocused ? 241.74 : 223)
                )

        }
        .frame(width: scaled(cardWidth), height: scaled(cardHeight), alignment: .topLeading)
        .contentShape(RoundedRectangle(cornerRadius: scaled(12), style: .continuous))
        .focusable(true)
        .focusEffectDisabled()
        .onTapGesture(perform: action)
        .accessibilityAddTraits(.isButton)
        .animation(.easeOut(duration: 0.12), value: isFocused)
    }

    private func scaled(_ value: CGFloat) -> CGFloat {
        value * scale
    }

    private var cardWidth: CGFloat {
        isFocused ? 269.855 : 250
    }

    private var cardHeight: CGFloat {
        isFocused ? 374 : 345
    }
}

private struct PlaylistLandingCardBackground: View {
    let scale: CGFloat
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat
    let isFocused: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            if isFocused {
                Image(AppImages.focusedPlaylistCardBackground)
                    .resizable()
                    .frame(width: scaled(width), height: scaled(height))
                    .clipped()
            } else {
                RoundedRectangle(cornerRadius: scaled(cornerRadius), style: .continuous)
                    .fill(AppColors.cardBackground)
                    .frame(width: scaled(width), height: scaled(height))
            }
        }
        .frame(width: scaled(width), height: scaled(height), alignment: .topLeading)
        .clipShape(RoundedRectangle(cornerRadius: scaled(activeCornerRadius), style: .continuous))
    }

    private var activeCornerRadius: CGFloat {
        isFocused ? 12.974 : cornerRadius
    }

    private func scaled(_ value: CGFloat) -> CGFloat {
        value * scale
    }
}

private struct DemoPlaylistFocusButton: View {
    let scale: CGFloat
    let isFocused: Bool
    let action: () -> Void

    var body: some View {
        Text("Watch a demo playlist")
            .font(AppTypography.bodyRegular(scale: scale))
            .foregroundStyle(AppColors.brandSecondary)
            .frame(width: scaled(250), height: scaled(47))
            .overlay(
                RoundedRectangle(cornerRadius: scaled(10), style: .continuous)
                    .stroke(isFocused ? AppColors.brandSecondary : .clear, lineWidth: scaled(1))
            )
            .contentShape(RoundedRectangle(cornerRadius: scaled(10), style: .continuous))
            .focusable(true)
            .focusEffectDisabled()
            .onTapGesture(perform: action)
            .accessibilityAddTraits(.isButton)
            .animation(.easeOut(duration: 0.12), value: isFocused)
    }

    private func scaled(_ value: CGFloat) -> CGFloat {
        value * scale
    }
}

private struct PlaylistClock: View {
    let scale: CGFloat

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            HStack(alignment: .top, spacing: scaled(18)) {
                Text(Self.timeFormatter.string(from: context.date))
                    .font(.app(size: scaled(60), weight: .regular))
                    .foregroundStyle(.white)

                Text(dateText(for: context.date))
                    .font(.app(size: scaled(24), weight: .regular))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .fixedSize()
                    .padding(.top, scaled(5))
            }
            .offset(x: scaled(923), y: scaled(43))
        }
    }

    private func scaled(_ value: CGFloat) -> CGFloat {
        value * scale
    }

    private func dateText(for date: Date) -> String {
        let components = Calendar.current.dateComponents([.weekday, .day, .month], from: date)
        let weekday = Self.weekdayText[max(0, min(6, (components.weekday ?? 1) - 1))]
        let month = Self.monthText[max(0, min(11, (components.month ?? 1) - 1))]
        return "\(weekday)\n\(components.day ?? 1) \(month)"
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    private static let weekdayText = ["SUN", "MON", "TUES", "WED", "THUR", "FRI", "SAT"]
    private static let monthText = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]
}

#Preview("Create Playlist Screen") {
    CreatePlaylistScreen(
        viewModel: CreatePlaylistViewModel(playlistService: AppContainer.live.playlistService),
        onDemoPlaylistAdded: {}
    )
}

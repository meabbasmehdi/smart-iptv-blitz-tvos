import SwiftUI

struct DemoPlaylistView: View {
    @ObservedObject var viewModel: CreatePlaylistViewModel
    let onCancel: () -> Void
    let onAdded: () -> Void

    @FocusState private var focusedElement: DemoPlaylistFocus?
    @State private var isConfirmed = false
    @State private var validationMessage: String?

    var body: some View {
        GeometryReader { proxy in
            let scale = min(proxy.size.width / 1280, proxy.size.height / 720)
            let legalRowWidth: CGFloat = 30.321 + 9.5 + 368

            ZStack(alignment: .topLeading) {
                FigmaScreenBackground {
                    EmptyView()
                }

                CreatePlaylistHeader(scale: scale)

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

                HStack(alignment: .center, spacing: scaled(9.5, scale)) {
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
                .frame(width: scaled(legalRowWidth, scale), height: scaled(40, scale), alignment: .center)
                .offset(x: scaled((1280 - legalRowWidth) / 2, scale), y: scaled(552, scale))

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

private enum DemoPlaylistFocus: Hashable {
    case legalConfirmation
    case add
    case cancel
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

#Preview("Demo Playlist") {
    DemoPlaylistView(
        viewModel: CreatePlaylistViewModel(playlistService: AppContainer.live.playlistService),
        onCancel: {},
        onAdded: {}
    )
}

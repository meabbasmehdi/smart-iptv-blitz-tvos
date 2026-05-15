import SwiftUI

struct M3UPlaylistView: View {
    let onCancel: () -> Void

    @FocusState private var focusedElement: M3UPlaylistFocus?

    var body: some View {
        GeometryReader { proxy in
            let scale = min(proxy.size.width / 1280, proxy.size.height / 720)

            ZStack(alignment: .topLeading) {
                FigmaScreenBackground {
                    EmptyView()
                }

                CreatePlaylistHeader(scale: scale)

                Text("Create M3U Playlist")
                    .font(.app(size: scaled(44, scale), weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: scaled(661, scale), alignment: .center)
                    .offset(x: scaled(310, scale), y: scaled(124, scale))

                RoundedRectangle(cornerRadius: scaled(24, scale), style: .continuous)
                    .fill(AppColors.dialogSurface)
                    .frame(width: scaled(900, scale), height: scaled(380, scale))
                    .offset(x: scaled(190, scale), y: scaled(310, scale))

                Image(AppImages.m3uCardIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: scaled(90, scale), height: scaled(135, scale))
                    .offset(x: scaled(595, scale), y: scaled(390, scale))

                CreatePlaylistBackButton(
                    scale: scale,
                    isFocused: focusedElement == .back,
                    action: onCancel
                )
                .focused($focusedElement, equals: .back)
                .offset(x: scaled(570, scale), y: scaled(610, scale))
            }
            .frame(width: scaled(1280, scale), height: scaled(720, scale))
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
        .ignoresSafeArea()
        .onAppear {
            focusedElement = .back
        }
        .onExitCommand(perform: onCancel)
        #if os(tvOS)
        .defaultFocus($focusedElement, .back)
        #endif
    }

    private func scaled(_ value: CGFloat, _ scale: CGFloat) -> CGFloat {
        value * scale
    }
}

private enum M3UPlaylistFocus: Hashable {
    case back
}

#Preview("M3U Playlist") {
    M3UPlaylistView(onCancel: {})
}

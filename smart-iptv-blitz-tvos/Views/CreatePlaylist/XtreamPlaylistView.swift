import SwiftUI

struct XtreamPlaylistView: View {
    let onCancel: () -> Void

    @FocusState private var focusedElement: XtreamPlaylistFocus?

    var body: some View {
        GeometryReader { proxy in
            let scale = min(proxy.size.width / 1280, proxy.size.height / 720)

            ZStack(alignment: .topLeading) {
                FigmaScreenBackground {
                    EmptyView()
                }

                CreatePlaylistHeader(scale: scale)

                Text("Create Xtream Playlist")
                    .font(.app(size: scaled(44, scale), weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: scaled(661, scale), alignment: .center)
                    .offset(x: scaled(310, scale), y: scaled(124, scale))

                RoundedRectangle(cornerRadius: scaled(24, scale), style: .continuous)
                    .fill(AppColors.dialogSurface)
                    .frame(width: scaled(900, scale), height: scaled(380, scale))
                    .offset(x: scaled(190, scale), y: scaled(310, scale))

                Image(AppImages.xtreamCardIcon)
                    .resizable()
                    .scaledToFill()
                    .frame(width: scaled(120, scale), height: scaled(120, scale))
                    .clipped()
                    .offset(x: scaled(580, scale), y: scaled(398, scale))

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

private enum XtreamPlaylistFocus: Hashable {
    case back
}

#Preview("Xtream Playlist") {
    XtreamPlaylistView(onCancel: {})
}

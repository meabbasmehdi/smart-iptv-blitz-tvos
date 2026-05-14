import SwiftUI

struct CreatePlaylistScreen: View {
    @FocusState private var focusedItem: PlaylistLandingFocus?
    @State private var lastFocusedCard: PlaylistLandingFocus = .xtream

    var body: some View {
        GeometryReader { proxy in
            let scale = min(proxy.size.width / 1280, proxy.size.height / 720)

            ZStack(alignment: .topLeading) {
                PlaylistFigmaBackground()

                Text("Smart IPTV")
                    .font(.app(size: scaled(24, scale), weight: .semibold))
                    .foregroundStyle(.white)
                    .offset(x: scaled(60, scale), y: scaled(60, scale))

                HStack(spacing: scaled(28, scale)) {
                    Image(systemName: "wifi")
                        .font(.system(size: scaled(20, scale), weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: scaled(24, scale), height: scaled(24, scale))

                    Image(systemName: "gearshape")
                        .font(.system(size: scaled(20, scale), weight: .regular))
                        .foregroundStyle(.white)
                        .frame(width: scaled(24, scale), height: scaled(24, scale))
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

                DemoPlaylistFocusButton(scale: scale, isFocused: focusedItem == .demo) {}
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

private enum PlaylistLandingFocus: Hashable {
    case xtream
    case playlistURL
    case demo
}

private struct XtreamPlaylistCard: View {
    let scale: CGFloat
    let isFocused: Bool
    let action: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: scaled(12.974), style: .continuous)
                .fill(Color.white.opacity(0.2))
                .frame(width: scaled(cardWidth), height: scaled(cardHeight))

            Image("FigmaXtreamMask")
                .resizable()
                .scaledToFill()
                .frame(width: scaled(cardWidth), height: scaled(isFocused ? 213.559 : 196))
                .clipped()
                .offset(x: 0, y: scaled(isFocused ? 160.44 : 149))

            Image("FigmaXtreamCardIcon")
                .resizable()
                .scaledToFill()
                .frame(width: scaled(isFocused ? 101.683 : 72), height: scaled(isFocused ? 101.683 : 72))
                .clipped()
                .offset(
                    x: scaled(isFocused ? 83 : 89),
                    y: scaled(isFocused ? 52.14 : 40)
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

            RoundedRectangle(cornerRadius: scaled(12.974), style: .continuous)
                .stroke(isFocused ? Color(hex: 0xD15E60) : .clear, lineWidth: scaled(2.162))
                .frame(width: scaled(cardWidth), height: scaled(cardHeight))
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
            RoundedRectangle(cornerRadius: scaled(12), style: .continuous)
                .fill(Color.white.opacity(0.2))
                .frame(width: scaled(cardWidth), height: scaled(cardHeight))

            Image("FigmaM3UCardIcon")
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

            RoundedRectangle(cornerRadius: scaled(12), style: .continuous)
                .stroke(isFocused ? Color(hex: 0xD15E60) : .clear, lineWidth: scaled(2.162))
                .frame(width: scaled(cardWidth), height: scaled(cardHeight))
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

private struct DemoPlaylistFocusButton: View {
    let scale: CGFloat
    let isFocused: Bool
    let action: () -> Void

    var body: some View {
        Text("Watch a demo playlist")
            .font(.app(size: scaled(18), weight: .regular))
            .foregroundStyle(Color(hex: 0xD15E60))
            .frame(width: scaled(250), height: scaled(47))
            .overlay(
                RoundedRectangle(cornerRadius: scaled(10), style: .continuous)
                    .stroke(isFocused ? Color(hex: 0xD15E60) : .clear, lineWidth: scaled(1))
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

private struct PlaylistFigmaBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                stops: [
                    .init(color: Color(hex: 0x8B2621), location: 0.04792),
                    .init(color: Color(hex: 0xD15E60), location: 0.63292)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            LinearGradient(
                stops: [
                    .init(color: .black, location: 0),
                    .init(color: .black, location: 0.38298),
                    .init(color: .black.opacity(0.5), location: 0.72276),
                    .init(color: .clear, location: 1)
                ],
                startPoint: .bottom,
                endPoint: .top
            )
        }
    }
}

#Preview("Create Playlist Screen") {
    CreatePlaylistScreen()
}

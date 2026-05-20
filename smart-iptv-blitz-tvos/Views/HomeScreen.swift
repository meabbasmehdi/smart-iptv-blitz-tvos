import SwiftUI
import Combine

struct HomeScreen: View {
    @ObservedObject var viewModel: HomeViewModel
    let onOpenLiveTV: () -> Void

    @FocusState private var focusedItem: HomeFocusItem?

    init(viewModel: HomeViewModel, onOpenLiveTV: @escaping () -> Void = {}) {
        self.viewModel = viewModel
        self.onOpenLiveTV = onOpenLiveTV
    }

    var body: some View {
        GeometryReader { proxy in
            let scale = min(proxy.size.width / 1920, proxy.size.height / 1080)

            ZStack(alignment: .topLeading) {
                HomeFigmaBackground()

                Text("Smart IPTV")
                    .font(.app(size: scaled(48, scale), weight: .semibold))
                    .foregroundStyle(.white)
                    .offset(x: scaled(60, scale), y: scaled(60, scale))

                HomeTopIconBar(scale: scale)
                    .offset(x: scaled(1101, scale), y: scaled(68, scale))

                HomeClockBlock(scale: scale)
                    .offset(x: scaled(1439, scale), y: scaled(43, scale))

                HomeLiveTVCard(scale: scale, isFocused: focusedItem == .liveTV) {
                    onOpenLiveTV()
                }
                    .focused($focusedItem, equals: .liveTV)
                    .offset(
                        x: scaled(focusedItem == .liveTV ? 60 : 70, scale),
                        y: scaled(focusedItem == .liveTV ? 459 : 488, scale)
                    )
            }
            .frame(width: scaled(1920, scale), height: scaled(1080, scale))
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
        .ignoresSafeArea()
        .onAppear {
            focusedItem = .liveTV
        }
        #if os(tvOS)
        .defaultFocus($focusedItem, .liveTV)
        #endif
    }

    private func scaled(_ value: CGFloat, _ scale: CGFloat) -> CGFloat {
        value * scale
    }
}

private enum HomeFocusItem: Hashable {
    case liveTV
}

private struct HomeFigmaBackground: View {
    var body: some View {
        ZStack {
            Image(AppImages.homeBackground)
                .resizable()
                .scaledToFill()
                .blur(radius: 8)
                .ignoresSafeArea()

            LinearGradient(
                stops: [
                    .init(color: .black.opacity(0.4), location: 0),
                    .init(color: .black.opacity(0.1), location: 0.256),
                    .init(color: .black.opacity(0.1), location: 0.535),
                    .init(color: .black.opacity(0.4), location: 0.744),
                    .init(color: .black, location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
        .background(Color(hex: 0x09090A))
    }
}

private struct HomeTopIconBar: View {
    let scale: CGFloat

    private let icons = [
        AppImages.homeHeartIcon,
        AppImages.homeParentalIcon,
        AppImages.homePlaylistIcon,
        AppImages.homeWifiIcon,
        AppImages.homeSettingsIcon
    ]

    var body: some View {
        HStack(spacing: scaled(28)) {
            ForEach(icons, id: \.self) { icon in
                Image(icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: scaled(32), height: scaled(32))
            }
        }
    }

    private func scaled(_ value: CGFloat) -> CGFloat {
        value * scale
    }
}

private struct HomeClockBlock: View {
    let scale: CGFloat

    @State private var now = Date()
    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()
    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter
    }()

    var body: some View {
        HStack(alignment: .top, spacing: scaled(34)) {
            Text(timeFormatter.string(from: now))
                .font(.app(size: scaled(74), weight: .regular))
                .foregroundStyle(.white)
                .fixedSize()

            Text("\(dayFormatter.string(from: now).uppercased())\n\(dateFormatter.string(from: now).uppercased())")
                .font(.app(size: scaled(32), weight: .medium))
                .foregroundStyle(.white)
                .lineSpacing(0)
                .fixedSize()
                .padding(.top, scaled(5))
        }
        .onReceive(timer) { value in
            now = value
        }
    }

    private func scaled(_ value: CGFloat) -> CGFloat {
        value * scale
    }
}

private struct HomeLiveTVCard: View {
    let scale: CGFloat
    let isFocused: Bool
    let action: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            let width = cardWidth
            let height = cardHeight

            Image(AppImages.homeLiveTVPoster)
                .resizable()
                .scaledToFill()
                .frame(width: scaled(width), height: scaled(height))
                .clipped()

            LinearGradient(
                colors: [.clear, .black],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(width: scaled(width), height: scaled(height))

            Color.black.opacity(0.1)
                .frame(width: scaled(width), height: scaled(height))

            Image(AppImages.homeLiveIcon)
                .resizable()
                .scaledToFit()
                .frame(width: scaled(isFocused ? 52 : 44), height: scaled(isFocused ? 52 : 44))
                .offset(x: scaled(29), y: scaled(isFocused ? 282 : 279))

            Text("Live TV")
                .font(.app(size: scaled(isFocused ? 40 : 34), weight: .medium))
                .foregroundStyle(.white)
                .offset(x: scaled(29), y: scaled(isFocused ? 344 : 327))

            if isFocused {
                VStack(alignment: .leading, spacing: scaled(0)) {
                    Text("Last Updated today")
                    Text("25000+ channels")
                        .padding(.top, scaled(2))
                }
                .font(.app(size: scaled(32), weight: .regular))
                .foregroundStyle(.white)
                .offset(x: scaled(28.8), y: scaled(392))
            }
        }
        .frame(width: scaled(cardWidth), height: scaled(cardHeight), alignment: .topLeading)
        .clipShape(RoundedRectangle(cornerRadius: scaled(17.354), style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: scaled(17.354), style: .continuous)
                .stroke(isFocused ? AppColors.brandSecondary : .clear, lineWidth: scaled(2.892))
        )
        .overlay(
            RoundedRectangle(cornerRadius: scaled(17.354), style: .continuous)
                .stroke(.white.opacity(isFocused ? 0.22 : 0.08), lineWidth: scaled(1))
                .blur(radius: scaled(isFocused ? 2.8 : 1.5))
                .clipShape(RoundedRectangle(cornerRadius: scaled(17.354), style: .continuous))
        )
        .shadow(color: .black.opacity(0.42), radius: scaled(5.785), x: 0, y: scaled(2.892))
        .contentShape(RoundedRectangle(cornerRadius: scaled(17.354), style: .continuous))
        .focusable(true)
        .focusEffectDisabled()
        .onTapGesture(perform: action)
        .accessibilityAddTraits(.isButton)
        .animation(.easeOut(duration: 0.14), value: isFocused)
    }

    private var cardWidth: CGFloat {
        isFocused ? 360 : 339.846
    }

    private var cardHeight: CGFloat {
        isFocused ? 500 : 470
    }

    private func scaled(_ value: CGFloat) -> CGFloat {
        value * scale
    }
}

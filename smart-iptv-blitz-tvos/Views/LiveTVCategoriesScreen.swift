import SwiftUI

struct LiveTVCategoriesScreen: View {
    @ObservedObject var viewModel: LiveTVViewModel
    let onOpenPlayer: () -> Void
    let onBack: () -> Void

    @FocusState private var focusedItem: LiveTVFocus?
    @State private var didSetInitialFocus = false

    private let gridColumns = 5
    private let focusOverflow: CGFloat = 12

    var body: some View {
        GeometryReader { proxy in
            let scale = min(proxy.size.width / 1280, proxy.size.height / 720)

            ZStack(alignment: .topLeading) {
                LiveTVCategoryBackground()

                Color.white.opacity(0.1)
                    .frame(width: scaled(425, scale), height: scaled(720, scale))

                Text("Smart IPTV")
                    .font(.app(size: scaled(24, scale), weight: .semibold))
                    .foregroundStyle(.white)
                    .offset(x: scaled(47, scale), y: scaled(60, scale))

                Text("Live")
                    .font(.app(size: scaled(24, scale), weight: .semibold))
                    .foregroundStyle(.white)
                    .offset(x: scaled(480, scale), y: scaled(60, scale))

                Image(AppImages.categorySearchIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: scaled(24, scale), height: scaled(24, scale))
                    .offset(x: scaled(1190, scale), y: scaled(66, scale))

                categoryList(scale: scale)
                    .offset(x: scaled(45, scale), y: scaled(131, scale))

                channelGrid(scale: scale)
                    .offset(
                        x: scaled(480 - focusOverflow, scale),
                        y: scaled(126 - focusOverflow, scale)
                    )

                if viewModel.categories.count > 9 {
                    RoundedRectangle(cornerRadius: scaled(222, scale), style: .continuous)
                        .fill(.white.opacity(0.2))
                        .frame(width: scaled(7, scale), height: scaled(334, scale))
                        .offset(x: scaled(406, scale), y: scaled(204, scale))
                }

                if viewModel.channels.count > 15 {
                    RoundedRectangle(cornerRadius: scaled(222, scale), style: .continuous)
                        .fill(.white.opacity(0.2))
                        .frame(width: scaled(7, scale), height: scaled(334, scale))
                        .offset(x: scaled(1260, scale), y: scaled(331, scale))
                }

                loadingAndErrorOverlay(scale: scale)
            }
            .frame(width: scaled(1280, scale), height: scaled(720, scale))
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
        .ignoresSafeArea()
        .task {
            await viewModel.load()
            focusFirstCategoryIfNeeded()
        }
        .onChange(of: viewModel.categories) { _, _ in
            focusFirstCategoryIfNeeded()
        }
        .onChange(of: viewModel.channels) { _, _ in
            clampFocusedItemIfNeeded()
        }
        .onMoveCommand(perform: moveFocus)
        #if os(tvOS)
        .defaultFocus($focusedItem, .category(0))
        .onExitCommand(perform: onBack)
        #endif
    }

    @ViewBuilder
    private func categoryList(scale: CGFloat) -> some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: scaled(10, scale)) {
                    ForEach(Array(viewModel.categories.enumerated()), id: \.offset) { index, category in
                        LiveTVCategoryRow(
                            category: category,
                            isSelected: viewModel.selectedCategoryID == category.id,
                            isFocused: focusedItem == .category(index),
                            scale: scale
                        )
                        .frame(width: scaled(360, scale), height: scaled(50, scale))
                        .contentShape(RoundedRectangle(cornerRadius: scaled(12, scale), style: .continuous))
                        .focusable(true)
                        .focusEffectDisabled()
                        .focused($focusedItem, equals: .category(index))
                        .onTapGesture {
                            viewModel.selectCategory(category)
                            focusedItem = viewModel.channels.isEmpty ? .category(index) : .channel(0)
                        }
                        .id(index)
                    }
                }
            }
            .frame(width: scaled(360, scale), height: scaled(589, scale), alignment: .top)
            .onChange(of: focusedItem) { _, value in
                guard case let .category(index) = value,
                      viewModel.categories.indices.contains(index) else {
                    return
                }
                viewModel.selectCategory(viewModel.categories[index])
                withAnimation(.easeOut(duration: 0.14)) {
                    proxy.scrollTo(index, anchor: categoryScrollAnchor(for: index))
                }
            }
        }
    }

    @ViewBuilder
    private func channelGrid(scale: CGFloat) -> some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(
                    columns: Array(
                        repeating: GridItem(.fixed(scaled(128, scale)), spacing: scaled(25, scale)),
                        count: gridColumns
                    ),
                    alignment: .leading,
                    spacing: scaled(30, scale)
                ) {
                    ForEach(Array(viewModel.channels.enumerated()), id: \.offset) { index, channel in
                        LiveTVChannelTile(
                            channel: channel,
                            isFocused: focusedItem == .channel(index),
                            scale: scale
                        )
                        .frame(width: scaled(128, scale), height: scaled(128, scale))
                        .contentShape(RoundedRectangle(cornerRadius: scaled(12, scale), style: .continuous))
                        .focusable(true)
                        .focusEffectDisabled()
                        .focused($focusedItem, equals: .channel(index))
                        .onTapGesture {
                            viewModel.openChannel(channel)
                            if viewModel.playerChannel != nil {
                                onOpenPlayer()
                            }
                        }
                        .zIndex(focusedItem == .channel(index) ? 1 : 0)
                        .id(index)
                    }
                }
                .padding(.top, scaled(focusOverflow, scale))
                .padding(.leading, scaled(focusOverflow, scale))
                .padding(.trailing, scaled(focusOverflow, scale))
                .padding(.bottom, scaled(90 + focusOverflow, scale))
            }
            .frame(
                width: scaled(760 + (focusOverflow * 2), scale),
                height: scaled(594 + (focusOverflow * 2), scale),
                alignment: .topLeading
            )
            .onChange(of: focusedItem) { _, value in
                guard case let .channel(index) = value else { return }
                withAnimation(.easeOut(duration: 0.14)) {
                    proxy.scrollTo(index, anchor: channelScrollAnchor(for: index))
                }
            }
        }
    }

    @ViewBuilder
    private func loadingAndErrorOverlay(scale: CGFloat) -> some View {
        if viewModel.isLoading {
            ZStack {
                Color.black.opacity(0.25)
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.2)
            }
            .frame(width: scaled(855, scale), height: scaled(594, scale))
            .offset(x: scaled(425, scale), y: scaled(126, scale))
        } else if let errorMessage = viewModel.errorMessage {
            Text(errorMessage)
                .font(.app(size: scaled(18, scale), weight: .medium))
                .foregroundStyle(.white.opacity(0.86))
                .multilineTextAlignment(.center)
                .frame(width: scaled(620, scale))
                .offset(x: scaled(555, scale), y: scaled(334, scale))
        } else if viewModel.channels.isEmpty {
            Text("No channels available")
                .font(.app(size: scaled(18, scale), weight: .medium))
                .foregroundStyle(.white.opacity(0.86))
                .offset(x: scaled(680, scale), y: scaled(334, scale))
        }
    }

    private func moveFocus(_ direction: MoveCommandDirection) {
        switch focusedItem {
        case let .category(index):
            moveCategoryFocus(from: index, direction: direction)
        case let .channel(index):
            moveChannelFocus(from: index, direction: direction)
        case nil:
            focusFirstCategoryIfNeeded()
        }
    }

    private func moveCategoryFocus(from index: Int, direction: MoveCommandDirection) {
        switch direction {
        case .up:
            focusedItem = .category(max(index - 1, 0))
        case .down:
            focusedItem = .category(min(index + 1, max(viewModel.categories.count - 1, 0)))
        case .right:
            focusedItem = viewModel.channels.isEmpty ? .category(index) : .channel(0)
        default:
            break
        }
    }

    private func moveChannelFocus(from index: Int, direction: MoveCommandDirection) {
        guard !viewModel.channels.isEmpty else { return }

        switch direction {
        case .left:
            if index % gridColumns == 0 {
                focusedItem = .category(selectedCategoryIndex)
            } else {
                focusedItem = .channel(index - 1)
            }
        case .right:
            focusedItem = .channel(min(index + 1, viewModel.channels.count - 1))
        case .up:
            focusedItem = .channel(max(index - gridColumns, 0))
        case .down:
            focusedItem = .channel(min(index + gridColumns, viewModel.channels.count - 1))
        default:
            break
        }
    }

    private var selectedCategoryIndex: Int {
        viewModel.categories.firstIndex { $0.id == viewModel.selectedCategoryID } ?? 0
    }

    private func focusFirstCategoryIfNeeded() {
        guard !didSetInitialFocus, !viewModel.categories.isEmpty else {
            return
        }

        didSetInitialFocus = true
        let index = selectedCategoryIndex
        viewModel.selectCategory(viewModel.categories[index])
        focusedItem = .category(index)
    }

    private func clampFocusedItemIfNeeded() {
        switch focusedItem {
        case let .category(index):
            if !viewModel.categories.indices.contains(index) {
                focusedItem = viewModel.categories.isEmpty ? nil : .category(0)
            }
        case let .channel(index):
            guard !viewModel.channels.isEmpty else {
                focusedItem = viewModel.categories.isEmpty ? nil : .category(selectedCategoryIndex)
                return
            }
            if !viewModel.channels.indices.contains(index) {
                focusedItem = .channel(viewModel.channels.count - 1)
            }
        case nil:
            focusFirstCategoryIfNeeded()
        }
    }

    private func categoryScrollAnchor(for index: Int) -> UnitPoint {
        index <= 1 ? .top : .center
    }

    private func channelScrollAnchor(for index: Int) -> UnitPoint {
        index < gridColumns ? .top : .center
    }

    private func scaled(_ value: CGFloat, _ scale: CGFloat) -> CGFloat {
        value * scale
    }
}

private enum LiveTVFocus: Hashable {
    case category(Int)
    case channel(Int)
}

private struct LiveTVCategoryBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                stops: [
                    .init(color: AppColors.brandPrimary, location: 0.04792),
                    .init(color: AppColors.brandSecondary, location: 0.63292)
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

private struct LiveTVCategoryRow: View {
    let category: LiveTVCategory
    let isSelected: Bool
    let isFocused: Bool
    let scale: CGFloat

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.clear
                .frame(width: scaled(360), height: scaled(50))

            if isSelected {
                LinearGradient(
                    colors: [AppColors.brandPrimary, AppColors.brandSecondary],
                    startPoint: .bottom,
                    endPoint: .top
                )
                .frame(width: scaled(360), height: scaled(50))
                .clipShape(RoundedRectangle(cornerRadius: scaled(10), style: .continuous))
            }

            HStack(spacing: scaled(8.5)) {
                Image(AppImages.categoryVideoIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: scaled(25.5), height: scaled(25.5))

                Text(category.title)
                    .font(.app(size: scaled(24), weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("\(category.count)")
                    .font(.app(size: scaled(24), weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .frame(width: scaled(82), alignment: .trailing)
            }
            .frame(width: scaled(329), height: scaled(50), alignment: .center)
            .offset(x: scaled(15), y: 0)
        }
        .frame(width: scaled(360), height: scaled(50), alignment: .topLeading)
        .overlay(
            RoundedRectangle(cornerRadius: scaled(12), style: .continuous)
                .stroke(isFocused ? AppColors.brandSecondary : .clear, lineWidth: scaled(2))
        )
        .overlay(
            RoundedRectangle(cornerRadius: scaled(12), style: .continuous)
                .stroke(isFocused ? .white.opacity(0.24) : .clear, lineWidth: scaled(1))
                .blur(radius: scaled(2))
        )
        .animation(.easeOut(duration: 0.12), value: isSelected)
        .animation(.easeOut(duration: 0.12), value: isFocused)
    }

    private func scaled(_ value: CGFloat) -> CGFloat {
        value * scale
    }
}

private struct LiveTVChannelTile: View {
    let channel: LiveTVChannel
    let isFocused: Bool
    let scale: CGFloat

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: scaled(12), style: .continuous)
                .fill(tileBackground)

            AsyncImage(url: channel.imageURL) { phase in
                switch phase {
                case let .success(image):
                    image
                        .resizable()
                        .scaledToFill()
                default:
                    fallbackContent
                }
            }
            .frame(width: scaled(128), height: scaled(128))
            .clipShape(RoundedRectangle(cornerRadius: scaled(12), style: .continuous))

            LiveBadge(scale: scale)
                .offset(x: scaled(-10), y: scaled(10))
        }
        .frame(width: scaled(128), height: scaled(128))
        .clipShape(RoundedRectangle(cornerRadius: scaled(12), style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: scaled(12), style: .continuous)
                .stroke(isFocused ? AppColors.brandSecondary : .clear, lineWidth: scaled(4))
        )
        .overlay(
            RoundedRectangle(cornerRadius: scaled(12), style: .continuous)
                .stroke(isFocused ? .white.opacity(0.25) : .clear, lineWidth: scaled(1))
                .blur(radius: scaled(2))
        )
        .scaleEffect(isFocused ? 150 / 128 : 1)
        .animation(.easeOut(duration: 0.14), value: isFocused)
    }

    private var tileBackground: LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: 0xD15E60),
                Color(hex: 0x210609)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var fallbackContent: some View {
        ZStack {
            tileBackground
            Text(channel.title)
                .font(.app(size: scaled(18), weight: .semibold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.horizontal, scaled(10))
        }
    }

    private func scaled(_ value: CGFloat) -> CGFloat {
        value * scale
    }
}

private struct LiveBadge: View {
    let scale: CGFloat

    var body: some View {
        ZStack {
            Capsule()
                .fill(AppColors.brandSecondary.opacity(0.3))
                .overlay(
                    Capsule()
                        .stroke(.white, lineWidth: scaled(1))
                )

            Text("Live")
                .font(.system(size: scaled(10), weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(width: scaled(37), height: scaled(12))
    }

    private func scaled(_ value: CGFloat) -> CGFloat {
        value * scale
    }
}

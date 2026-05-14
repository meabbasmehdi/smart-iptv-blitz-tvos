import SwiftUI
import UIKit

struct DisclaimerScreen: View {
    @ObservedObject var viewModel: DisclaimerViewModel
    let onAccepted: () -> Void

    var body: some View {
        Group {
            if viewModel.showSplash {
                SplashView(
                    showStartButton: true,
                    onStartClick: viewModel.onSplashStart
                )
            } else {
                FigmaDisclaimerBackground {
                    GeometryReader { proxy in
                        let scale = min(proxy.size.width / 1280, proxy.size.height / 720)

                        DisclaimerDialog(
                            viewModel: viewModel,
                            scale: scale,
                            onAccepted: onAccepted
                        )
                        .frame(width: 870 * scale, height: 590 * scale)
                        .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                    }
                }
            }
        }
        .task {
            await viewModel.loadIfNeeded()
        }
        .onExitCommand {
            if !viewModel.showSplash {
                viewModel.onDeny()
            }
        }
    }
}

private struct DisclaimerDialog: View {
    @ObservedObject var viewModel: DisclaimerViewModel
    let scale: CGFloat
    let onAccepted: () -> Void

    @FocusState private var focusedElement: DisclaimerFocusElement?
    @State private var scrollTarget = 0

    var body: some View {
        ZStack(alignment: .topLeading) {
            Text(viewModel.title.isEmpty ? "Disclaimer" : viewModel.title)
                .font(.app(size: scaled(22), weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: scaled(781), alignment: .center)
                .position(x: scaled(435), y: scaled(90))

            ScrollViewReader { scrollProxy in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: scaled(18)) {
                        if viewModel.isLoading && viewModel.displayDescription.isEmpty {
                            Text("Loading latest disclaimer...")
                                .font(.app(size: scaled(16), weight: .regular))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .id(0)
                        } else {
                            ForEach(Array(displayParagraphs.enumerated()), id: \.offset) { index, paragraph in
                                Text(attributedBody(for: paragraph))
                                    .lineSpacing(scaled(1))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .id(index)
                            }
                        }

                        if let errorMessage = viewModel.errorMessage, !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(.app(size: scaled(16), weight: .regular))
                                .foregroundStyle(AppColors.error)
                                .padding(.top, scaled(14))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.trailing, scaled(26))
                    .padding(.vertical, scaled(2))
                }
                .onChange(of: scrollTarget) { _, newValue in
                    withAnimation(.easeInOut(duration: 0.18)) {
                        scrollProxy.scrollTo(newValue, anchor: .top)
                    }
                }
            }
            .frame(width: scaled(781), height: scaled(331))
            .clipped()
            .focusable(true)
            .focusEffectDisabled()
            .focused($focusedElement, equals: .content)
            .overlay(
                RoundedRectangle(cornerRadius: scaled(8), style: .continuous)
                    .stroke(
                        focusedElement == .content ? Color(hex: 0xD15E60).opacity(0.9) : .clear,
                        lineWidth: scaled(2)
                    )
            )
            .position(x: scaled(434.5), y: scaled(288.5))

            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: scaled(222), style: .continuous)
                    .fill(Color.white.opacity(0.2))

                RoundedRectangle(cornerRadius: scaled(222), style: .continuous)
                    .fill(focusedElement == .content ? Color(hex: 0xD15E60).opacity(0.8) : Color.white.opacity(0.32))
                    .frame(width: scaled(7), height: scaled(scrollThumbHeight))
                    .offset(y: scaled(scrollThumbOffset))
            }
                .frame(width: scaled(7), height: scaled(211))
                .position(x: scaled(838.5), y: scaled(207.5))

            DisclaimerFigmaButton(
                title: "Agree",
                fontWeight: .bold,
                background: Color(hex: 0x8B2621),
                border: .clear,
                scale: scale,
                isFocused: focusedElement == .agree,
                action: {
                    viewModel.onAgree()
                    onAccepted()
                }
            )
            .focused($focusedElement, equals: .agree)
            .position(x: scaled(279.5), y: scaled(508))

            DisclaimerFigmaButton(
                title: "Deny",
                fontWeight: .semibold,
                background: Color(hex: 0x3E3E3E),
                border: .clear,
                scale: scale,
                isFocused: focusedElement == .deny,
                action: viewModel.onDeny
            )
            .focused($focusedElement, equals: .deny)
            .position(x: scaled(590.5), y: scaled(508))
        }
        .background(Color(hex: 0x232323).opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: scaled(24), style: .continuous))
        .onAppear {
            focusedElement = .deny
        }
        .onChange(of: displayParagraphs.count) { _, count in
            if scrollTarget >= count {
                scrollTarget = max(0, count - 1)
            }
        }
        .onMoveCommand { direction in
            moveFocus(direction)
        }
        #if os(tvOS)
        .defaultFocus($focusedElement, .deny)
        #endif
    }

    private var displayParagraphs: [String] {
        let body = viewModel.displayDescription.isEmpty
            ? Self.figmaDisclaimerBody
            : viewModel.displayDescription
        let paragraphs = body
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return paragraphs.isEmpty ? [body] : paragraphs
    }

    private func attributedBody(for paragraph: String) -> AttributedString {
        let regularFont = UIFont(
            name: AppFontFamily.postScriptName(for: .regular),
            size: scaled(16)
        ) ?? .systemFont(ofSize: scaled(16), weight: .regular)
        let boldFont = UIFont(
            name: AppFontFamily.postScriptName(for: .bold),
            size: scaled(20)
        ) ?? .systemFont(ofSize: scaled(20), weight: .bold)
        let attributed = NSMutableAttributedString(
            string: paragraph,
            attributes: [
                .font: regularFont,
                .foregroundColor: UIColor.white
            ]
        )

        Self.boldPhrases.forEach { phrase in
            let source = paragraph as NSString
            var searchRange = NSRange(location: 0, length: source.length)
            while searchRange.location < source.length {
                let foundRange = source.range(of: phrase, options: [], range: searchRange)
                guard foundRange.location != NSNotFound else { break }
                attributed.addAttributes(
                    [
                        .font: boldFont,
                        .foregroundColor: UIColor.white
                    ],
                    range: foundRange
                )
                let nextLocation = foundRange.location + foundRange.length
                searchRange = NSRange(location: nextLocation, length: source.length - nextLocation)
            }
        }

        return AttributedString(attributed)
    }

    private func scaled(_ value: CGFloat) -> CGFloat {
        value * scale
    }

    private var scrollThumbHeight: CGFloat {
        let count = max(displayParagraphs.count, 1)
        return max(36, 211 / CGFloat(count))
    }

    private var scrollThumbOffset: CGFloat {
        let available = max(0, 211 - scrollThumbHeight)
        let maxIndex = max(displayParagraphs.count - 1, 1)
        return available * CGFloat(scrollTarget) / CGFloat(maxIndex)
    }

    private func moveFocus(_ direction: MoveCommandDirection) {
        switch direction {
        case .left:
            if focusedElement == .deny {
                focusedElement = .agree
            }
        case .right:
            if focusedElement == .agree {
                focusedElement = .deny
            }
        case .up:
            if focusedElement == .content {
                scrollTarget = max(0, scrollTarget - 1)
            } else if focusedElement == .agree || focusedElement == .deny {
                focusedElement = .content
            }
        case .down:
            if focusedElement == .content {
                if scrollTarget < displayParagraphs.count - 1 {
                    scrollTarget += 1
                } else {
                    focusedElement = .deny
                }
            }
        @unknown default:
            break
        }
    }

    private static let boldPhrases = [
        "Smart IPTV application",
        "does not own, host, store, upload, or distribute",
        "third-party sources",
        "beyond our control",
        "no guarantees",
        "quality, reliability, legality, accuracy, or availability",
        "solely responsible",
        "complies with all applicable laws, copyright, and licensing requirements",
        "strictly as a media aggregation tool",
        "disclaim any responsibility or liability",
        "copyright holder",
        "content provider directly. We will cooperate with lawful requests but",
        "cannot remove, modify, or disable",
        "not under our control",
        "installing or using",
        "at your own risk, and that the developers and distributors are",
        "not responsible for any misuse, unlawful activity, or violation"
    ]

    private static let figmaDisclaimerBody = """
    This Smart IPTV application is provided solely as a platform to access, organize, and display publicly available online video and live TV content. The app itself does not own, host, store, upload, or distribute any media files, live streams, or content. All media accessible through the application is provided by third-party sources that are beyond our control

    We make no guarantees regarding the quality, reliability, legality, accuracy, or availability of any content or streams provided by external providers. Users are solely responsible for ensuring that their use of this application and any accessed content complies with all applicable laws, copyright, and licensing requirements in their respective regions.

    This application is intended strictly as a media aggregation tool. We do not endorse, promote, or have any affiliation with any specific content provider or streaming source.

    The developers and distributors of this application disclaim any responsibility or liability for:

    • Service interruptions, buffering, or unavailability of third-party streams.
    • Damages, data loss, or any kind of loss resulting from the use or misuse of the application.
    • Copyright infringement or intellectual property violations committed by users or third parties.
    • The accuracy, safety, or appropriateness of any content accessed through external providers.

    If you are a copyright holder and believe your rights are being violated by third-party content accessible through this application, please contact the content provider directly. We will cooperate with lawful requests but cannot remove, modify, or disable any streams or content not under our control.

    By installing or using this application, you acknowledge and agree that you are using it at your own risk, and that the developers and distributors are not responsible for any misuse, unlawful activity, or violation arising from its use.
    """
}

private enum DisclaimerFocusElement: Hashable {
    case content
    case agree
    case deny
}

private struct DisclaimerFigmaButton: View {
    let title: String
    let fontWeight: Font.Weight
    let background: Color
    let border: Color
    let scale: CGFloat
    let isFocused: Bool
    let action: () -> Void

    var body: some View {
        Text(title)
            .font(.app(size: 24 * scale, weight: fontWeight))
            .foregroundStyle(.white)
            .frame(width: 285 * scale, height: 64 * scale)
            .background(isFocused ? background.opacity(0.98) : background)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isFocused ? Color(hex: 0xD15E60) : border, lineWidth: isFocused ? 4 * scale : 0)
            )
            .scaleEffect(isFocused ? 1.02 : 1)
            .contentShape(Capsule())
            .focusable(true)
            .focusEffectDisabled()
            .onTapGesture(perform: action)
            .accessibilityAddTraits(.isButton)
            .animation(.easeOut(duration: 0.12), value: isFocused)
    }
}

private struct FigmaDisclaimerBackground<Content: View>: View {
    @ViewBuilder var content: Content

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
            .ignoresSafeArea()

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
            .ignoresSafeArea()

            content
        }
    }
}

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
                FigmaScreenBackground {
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
    @State private var scrollCommand = DisclaimerScrollCommand()
    @State private var scrollState = DisclaimerScrollState()

    var body: some View {
        ZStack(alignment: .topLeading) {
            Text(displayTitle)
                .font(.app(size: scaled(22), weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: scaled(781), alignment: .center)
                .position(x: scaled(435), y: scaled(90))

            DisclaimerScrollableTextView(
                attributedText: scrollAttributedBody,
                scale: scale,
                scrollCommand: scrollCommand,
                scrollState: $scrollState
            )
            .frame(width: scaled(781), height: scaled(331))
            .clipped()
            .focusable(true)
            .focusEffectDisabled()
            .focused($focusedElement, equals: .content)
            .position(x: scaled(434.5), y: scaled(288.5))

            RoundedRectangle(cornerRadius: scaled(222), style: .continuous)
                .fill(AppColors.cardBackground)
                .frame(width: scaled(7), height: scaled(211))
                .offset(y: scaled(scrollIndicatorOffset))
                .position(x: scaled(838.5), y: scaled(207.5))

            DisclaimerFigmaButton(
                title: "Agree",
                fontWeight: .bold,
                background: AppColors.brandPrimary,
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
                background: AppColors.declineButton,
                border: .clear,
                scale: scale,
                isFocused: focusedElement == .deny,
                action: viewModel.onDeny
            )
            .focused($focusedElement, equals: .deny)
            .position(x: scaled(590.5), y: scaled(508))
        }
        .background(AppColors.dialogSurface)
        .clipShape(RoundedRectangle(cornerRadius: scaled(24), style: .continuous))
        .onAppear {
            focusedElement = .content
        }
        .onMoveCommand { direction in
            moveFocus(direction)
        }
        #if os(tvOS)
        .defaultFocus($focusedElement, .content)
        #endif
    }

    private var displayTitle: String {
        let title = viewModel.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return "Disclaimer" }
        return title.localizedCaseInsensitiveContains("disclaimer") ? "Disclaimer" : title
    }

    private var displayParagraphs: [String] {
        let body = sanitizedDisplayBody
        let paragraphs = body
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return paragraphs.isEmpty ? [body] : paragraphs
    }

    private var sanitizedDisplayBody: String {
        let sourceBody = viewModel.displayDescription.isEmpty
            ? Self.figmaDisclaimerBody
            : viewModel.displayDescription
        var lines = sourceBody.components(separatedBy: .newlines)
        let duplicateHeaders = Set(["disclaimer", "app disclaimer", displayTitle.lowercased()])

        while let firstLine = lines.first {
            let normalizedLine = firstLine.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if normalizedLine.isEmpty {
                lines.removeFirst()
            } else if duplicateHeaders.contains(normalizedLine) {
                lines.removeFirst()
            } else {
                break
            }
        }

        return lines
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var displayBody: String {
        if viewModel.isLoading && viewModel.displayDescription.isEmpty {
            return "Loading latest disclaimer..."
        }

        return displayParagraphs.joined(separator: "\n\n")
    }

    private var scrollAttributedBody: NSAttributedString {
        let attributed = NSMutableAttributedString(attributedString: attributedBody(for: displayBody))

        if let errorMessage = viewModel.errorMessage, !errorMessage.isEmpty {
            if attributed.length > 0 {
                attributed.append(NSAttributedString(string: "\n\n", attributes: bodyAttributes()))
            }
            attributed.append(
                NSAttributedString(
                    string: errorMessage,
                    attributes: bodyAttributes(foregroundColor: UIColor(AppColors.error))
                )
            )
        }

        return attributed
    }

    private func attributedBody(for body: String) -> NSAttributedString {
        let attributed = NSMutableAttributedString(
            string: body,
            attributes: bodyAttributes()
        )

        Self.boldPhrases.forEach { phrase in
            let source = body as NSString
            var searchRange = NSRange(location: 0, length: source.length)
            while searchRange.location < source.length {
                let foundRange = source.range(of: phrase, options: [], range: searchRange)
                guard foundRange.location != NSNotFound else { break }
                attributed.addAttributes(
                    [
                        .font: uiFont(weight: .bold, size: scaled(20)),
                        .foregroundColor: UIColor.white
                    ],
                    range: foundRange
                )
                let nextLocation = foundRange.location + foundRange.length
                searchRange = NSRange(location: nextLocation, length: source.length - nextLocation)
            }
        }

        return attributed
    }

    private func bodyAttributes(foregroundColor: UIColor = .white) -> [NSAttributedString.Key: Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = scaled(1)

        return [
            .font: uiFont(weight: .regular, size: scaled(16)),
            .foregroundColor: foregroundColor,
            .paragraphStyle: paragraphStyle
        ]
    }

    private func uiFont(weight: Font.Weight, size: CGFloat) -> UIFont {
        UIFont(
            name: AppFontFamily.postScriptName(for: weight),
            size: size
        ) ?? .systemFont(ofSize: size, weight: weight == .bold ? .bold : .regular)
    }

    private func scaled(_ value: CGFloat) -> CGFloat {
        value * scale
    }

    private var scrollIndicatorOffset: CGFloat {
        guard scrollState.isScrollable else { return 0 }
        return (331 - 211) * scrollState.progress
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
                if scrollState.canScrollUp {
                    queueScroll(.up)
                }
            } else if focusedElement == .agree || focusedElement == .deny {
                focusedElement = .content
            }
        case .down:
            if focusedElement == .content {
                if scrollState.canScrollDown {
                    queueScroll(.down)
                } else {
                    focusedElement = .deny
                }
            }
        @unknown default:
            break
        }
    }

    private func queueScroll(_ direction: DisclaimerScrollDirection) {
        scrollCommand = DisclaimerScrollCommand(
            id: scrollCommand.id + 1,
            direction: direction
        )
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

private struct DisclaimerScrollableTextView: UIViewRepresentable {
    let attributedText: NSAttributedString
    let scale: CGFloat
    let scrollCommand: DisclaimerScrollCommand
    @Binding var scrollState: DisclaimerScrollState

    func makeCoordinator() -> Coordinator {
        Coordinator(scrollState: $scrollState)
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.backgroundColor = .clear
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = false
        scrollView.bounces = true
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.panGestureRecognizer.allowedTouchTypes = [
            NSNumber(value: UITouch.TouchType.indirect.rawValue)
        ]
        scrollView.delegate = context.coordinator

        let label = UILabel()
        label.backgroundColor = .clear
        label.numberOfLines = 0
        label.attributedText = attributedText
        label.translatesAutoresizingMaskIntoConstraints = false

        scrollView.addSubview(label)

        let topConstraint = label.topAnchor.constraint(
            equalTo: scrollView.contentLayoutGuide.topAnchor,
            constant: 0
        )
        let bottomConstraint = label.bottomAnchor.constraint(
            equalTo: scrollView.contentLayoutGuide.bottomAnchor,
            constant: 0
        )
        let widthConstraint = label.widthAnchor.constraint(
            equalTo: scrollView.frameLayoutGuide.widthAnchor,
            constant: 0
        )

        NSLayoutConstraint.activate([
            topConstraint,
            label.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            bottomConstraint,
            widthConstraint
        ])

        context.coordinator.label = label
        context.coordinator.topConstraint = topConstraint
        context.coordinator.bottomConstraint = bottomConstraint
        context.coordinator.widthConstraint = widthConstraint

        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        context.coordinator.scrollState = $scrollState

        if let label = context.coordinator.label {
            let hasCurrentText = label.attributedText?.isEqual(to: attributedText) == true
            if !hasCurrentText {
                label.attributedText = attributedText
                scrollView.setContentOffset(.zero, animated: false)
            }
        }

        context.coordinator.topConstraint?.constant = 0
        context.coordinator.bottomConstraint?.constant = 0
        context.coordinator.widthConstraint?.constant = 0

        scrollView.setNeedsLayout()
        scrollView.layoutIfNeeded()

        if scrollCommand.id != context.coordinator.lastHandledCommandID {
            context.coordinator.lastHandledCommandID = scrollCommand.id
            context.coordinator.scroll(scrollCommand.direction, in: scrollView, scale: scale)
        }

        context.coordinator.publishScrollState(for: scrollView)
    }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        var scrollState: Binding<DisclaimerScrollState>
        weak var label: UILabel?
        weak var topConstraint: NSLayoutConstraint?
        weak var bottomConstraint: NSLayoutConstraint?
        weak var widthConstraint: NSLayoutConstraint?
        var lastHandledCommandID = 0

        init(scrollState: Binding<DisclaimerScrollState>) {
            self.scrollState = scrollState
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            publishScrollState(for: scrollView)
        }

        func scroll(_ direction: DisclaimerScrollDirection, in scrollView: UIScrollView, scale: CGFloat) {
            let maxOffset = max(0, scrollView.contentSize.height - scrollView.bounds.height)
            guard maxOffset > 0 else {
                publishScrollState(for: scrollView)
                return
            }

            let step = max(48 * scale, scrollView.bounds.height * 0.72)
            let proposedOffset = scrollView.contentOffset.y + (direction == .down ? step : -step)
            let clampedOffset = min(max(proposedOffset, 0), maxOffset)
            scrollView.setContentOffset(CGPoint(x: 0, y: clampedOffset), animated: true)
            publishScrollState(for: scrollView)
        }

        func publishScrollState(for scrollView: UIScrollView) {
            let nextState = DisclaimerScrollState(
                contentHeight: scrollView.contentSize.height,
                viewportHeight: scrollView.bounds.height,
                contentOffsetY: scrollView.contentOffset.y
            )

            guard nextState != scrollState.wrappedValue else { return }

            DispatchQueue.main.async { [scrollState] in
                scrollState.wrappedValue = nextState
            }
        }
    }
}

private enum DisclaimerScrollDirection: Equatable {
    case up
    case down
}

private struct DisclaimerScrollCommand: Equatable {
    var id = 0
    var direction: DisclaimerScrollDirection = .down
}

private struct DisclaimerScrollState: Equatable {
    var contentHeight: CGFloat = 0
    var viewportHeight: CGFloat = 0
    var contentOffsetY: CGFloat = 0

    private var maxOffset: CGFloat {
        max(0, contentHeight - viewportHeight)
    }

    var isScrollable: Bool {
        maxOffset > 1
    }

    var canScrollUp: Bool {
        contentOffsetY > 1
    }

    var canScrollDown: Bool {
        contentOffsetY < maxOffset - 1
    }

    var progress: CGFloat {
        guard maxOffset > 0 else { return 0 }
        return min(1, max(0, contentOffsetY / maxOffset))
    }
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
                    .stroke(isFocused ? AppColors.brandSecondary : border, lineWidth: isFocused ? 4 * scale : 0)
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

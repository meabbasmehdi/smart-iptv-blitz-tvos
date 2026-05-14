import SwiftUI

enum AppColors {
    static let brandPrimary = Color(hex: 0x8B2621)
    static let brandSecondary = Color(hex: 0xD15E60)
    static let landingRedStart = Color(hex: 0x541017)
    static let landingRedEnd = Color(hex: 0x0C1014)
    static let landingOverlayScrim = Color.black.opacity(0.8)
    static let cardBackground = Color.white.opacity(0.2)
    static let focusedCardBackground = Color(hex: 0xD15E60).opacity(0.5)
    static let dialogSurface = Color(hex: 0x232323).opacity(0.4)
    static let declineButton = Color(hex: 0x3E3E3E)
    static let error = Color(hex: 0xFF8A80)
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        let red = Double((hex & 0xFF0000) >> 16) / 255
        let green = Double((hex & 0x00FF00) >> 8) / 255
        let blue = Double(hex & 0x0000FF) / 255
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}

extension Font {
    static func app(size: CGFloat, weight: Weight = .regular) -> Font {
        .custom(AppFontFamily.postScriptName(for: weight), size: size)
    }
}

enum AppFontFamily {
    static let bundledFontFiles = [
        "Figtree-Regular",
        "Figtree-Medium",
        "Figtree-SemiBold",
        "Figtree-Bold",
        "Figtree-Italic"
    ]

    static func postScriptName(for weight: Font.Weight) -> String {
        if weight == .bold || weight == .heavy || weight == .black {
            return "Figtree-Bold"
        }
        if weight == .semibold {
            return "Figtree-SemiBold"
        }
        if weight == .medium {
            return "Figtree-Medium"
        }
        return "Figtree-Regular"
    }
}

struct AppGradientBackground: View {
    var body: some View {
        LinearGradient(
            colors: [AppColors.brandPrimary, .black],
            startPoint: .top,
            endPoint: UnitPoint(x: 0.5, y: 0.65)
        )
        .ignoresSafeArea()
    }
}

struct PlaylistLandingBackground<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppColors.landingRedStart, AppColors.landingRedEnd],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .clear, location: 0.6),
                    .init(color: AppColors.landingOverlayScrim, location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            content
        }
    }
}

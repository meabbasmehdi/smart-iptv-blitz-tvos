import SwiftUI

enum AppColors {
    static let brandPrimary = Color(hex: 0x8B2621)
    static let brandSecondary = Color(hex: 0xD15E60)
    static let neutralControl = Color(hex: 0x606060)
    static let gradientRedStart = Color(hex: 0x8A2924)
    static let gradientRedMid = Color(hex: 0x250F10)
    static let gradientNearBlack = Color(hex: 0x010000)
    static let shadowBlack = Color(hex: 0x0B0609)
    static let landingOverlayScrim = Color.black.opacity(0.8)
    static let cardBackground = Color.white.opacity(0.2)
    static let focusedCardBackground = brandSecondary.opacity(0.5)
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

enum AppTypography {
    static let display: CGFloat = 90
    static let title: CGFloat = 24
    static let body: CGFloat = 18
    static let caption: CGFloat = 12
    static let micro: CGFloat = 9

    static func titleSemibold(scale: CGFloat = 1) -> Font {
        .app(size: title * scale, weight: .semibold)
    }

    static func titleMedium(scale: CGFloat = 1) -> Font {
        .app(size: title * scale, weight: .medium)
    }

    static func bodyRegular(scale: CGFloat = 1) -> Font {
        .app(size: body * scale, weight: .regular)
    }

    static func bodyMedium(scale: CGFloat = 1) -> Font {
        .app(size: body * scale, weight: .medium)
    }

    static func bodySemibold(scale: CGFloat = 1) -> Font {
        .app(size: body * scale, weight: .semibold)
    }

    static func captionMedium(scale: CGFloat = 1) -> Font {
        .app(size: caption * scale, weight: .medium)
    }

    static func microMedium(scale: CGFloat = 1) -> Font {
        .app(size: micro * scale, weight: .medium)
    }
}

enum AppImages {
    static let splashBackground = "SplashBackground"
    static let xtreamCardIcon = "FigmaXtreamCardIcon"
    static let xtreamCardMask = "FigmaXtreamMask"
    static let focusedPlaylistCardBackground = "FigmaFocusedPlaylistCardBackground"
    static let m3uCardIcon = "FigmaM3UCardIcon"
    static let uploadIcon = "FigmaUploadIcon"
    static let wifiIcon = "FigmaWifiIcon"
    static let settingsIcon = "FigmaSettingsIcon"
    static let xtreamIcon = "XtreamIcon"
    static let m3uIcon = "M3UIcon"
    static let importFileIcon = "ImportFileIcon"
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
            stops: [
                .init(color: AppColors.gradientRedStart, location: 0),
                .init(color: AppColors.gradientRedMid, location: 0.48558),
                .init(color: AppColors.gradientNearBlack, location: 0.63079),
                .init(color: .black, location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

struct FigmaScreenBackground<Content: View>: View {
    @ViewBuilder var content: Content

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

struct PlaylistLandingBackground<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            AppGradientBackground()

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

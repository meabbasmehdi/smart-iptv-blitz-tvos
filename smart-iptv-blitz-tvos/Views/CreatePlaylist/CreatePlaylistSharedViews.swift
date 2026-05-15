import SwiftUI

struct CreatePlaylistHeader: View {
    let scale: CGFloat

    var body: some View {
        Group {
            Text("Smart IPTV")
                .font(AppTypography.titleSemibold(scale: scale))
                .foregroundStyle(.white)
                .offset(x: scaled(60), y: scaled(60))

            HStack(spacing: scaled(28)) {
                CreatePlaylistHeaderIcon(imageName: AppImages.wifiIcon, scale: scale)

                CreatePlaylistHeaderIcon(imageName: AppImages.settingsIcon, scale: scale)
            }
            .offset(x: scaled(732), y: scaled(67))

            PlaylistClock(scale: scale)
        }
    }

    private func scaled(_ value: CGFloat) -> CGFloat {
        value * scale
    }
}

struct CreatePlaylistHeaderIcon: View {
    let imageName: String
    let scale: CGFloat

    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFit()
            .foregroundStyle(.white)
            .frame(width: scaled(24), height: scaled(24))
    }

    private func scaled(_ value: CGFloat) -> CGFloat {
        value * scale
    }
}

struct PlaylistClock: View {
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

struct CreatePlaylistBackButton: View {
    let scale: CGFloat
    let isFocused: Bool
    let action: () -> Void

    var body: some View {
        HStack(spacing: scaled(10)) {
            Image(systemName: "chevron.left")
                .font(.system(size: scaled(18), weight: .semibold))

            Text("Back")
                .font(.app(size: scaled(20), weight: .semibold))
        }
        .foregroundStyle(.white)
        .frame(width: scaled(140), height: scaled(52))
        .background(
            Capsule(style: .continuous)
                .fill(isFocused ? AppColors.brandPrimary : AppColors.cardBackground)
        )
        .contentShape(Capsule(style: .continuous))
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

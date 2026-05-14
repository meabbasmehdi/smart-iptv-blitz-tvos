import Combine
import SwiftUI

struct ClockView: View {
    @State private var now = Date()
    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()
    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    var body: some View {
        Text(formatter.string(from: now))
            .font(.app(size: 18, weight: .medium))
            .foregroundStyle(.white.opacity(0.86))
            .onReceive(timer) { value in
                now = value
            }
    }
}

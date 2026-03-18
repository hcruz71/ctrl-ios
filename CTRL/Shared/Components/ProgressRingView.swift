import SwiftUI

struct ProgressRingView: View {
    let progress: Int
    var color: Color = .ctrlTeal
    var size: CGFloat = 44
    var lineWidth: CGFloat = 4

    private var fraction: Double {
        Double(min(max(progress, 0), 100)) / 100.0
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: fraction)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.4), value: progress)
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    HStack(spacing: 20) {
        ProgressRingView(progress: 25)
        ProgressRingView(progress: 50, color: .ctrlAmber)
        ProgressRingView(progress: 75, color: .ctrlCoral)
        ProgressRingView(progress: 100, color: .ctrlBlue)
    }
}

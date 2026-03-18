import SwiftUI

struct ObjectiveRowView: View {
    let objective: Objective

    var body: some View {
        HStack(spacing: 14) {
            ProgressRingView(progress: objective.progress, color: .ctrlTeal, size: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(objective.title)
                    .font(.headline)
                    .lineLimit(1)

                if let kr = objective.keyResult, !kr.isEmpty {
                    Text(kr)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                HStack(spacing: 6) {
                    BadgeView(text: objective.area, color: .ctrlTeal)
                    BadgeView(text: objective.horizon, color: .ctrlPurple)
                }
            }

            Spacer()

            Text("\(objective.progress)%")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(Color.ctrlTeal)
        }
        .padding(.vertical, 4)
    }
}

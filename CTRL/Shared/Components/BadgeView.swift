import SwiftUI

struct BadgeView: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .foregroundStyle(color)
            .background(color.opacity(0.12), in: Capsule())
    }
}

#Preview {
    HStack {
        BadgeView(text: "alta", color: .red)
        BadgeView(text: "Personal", color: .ctrlTeal)
        BadgeView(text: "pendiente", color: .orange)
    }
}

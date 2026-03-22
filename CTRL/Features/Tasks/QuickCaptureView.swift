import SwiftUI

struct QuickCaptureView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var selectedLevel: String?

    let onCreate: (CreateTaskBody) -> Void

    private let levels: [(label: String, value: String, color: Color, icon: String)] = [
        ("A", "A", .red, "flame.fill"),
        ("B", "B", .orange, "star.fill"),
        ("C", "C", .blue, "clock.fill"),
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                TextField("¿Qué necesitas hacer?", text: $title)
                    .font(.title3)
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                HStack(spacing: 12) {
                    ForEach(levels, id: \.value) { level in
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                selectedLevel = selectedLevel == level.value ? nil : level.value
                            }
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: level.icon)
                                    .font(.title2)
                                Text(level.label)
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                selectedLevel == level.value
                                    ? level.color.opacity(0.15)
                                    : Color(.systemGray6)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        selectedLevel == level.value ? level.color : .clear,
                                        lineWidth: 2
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(
                            selectedLevel == level.value ? level.color : .secondary
                        )
                    }
                }

                Button {
                    save()
                } label: {
                    Text("Capturar")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(title.isEmpty ? Color.gray : Color.ctrlPurple)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(title.isEmpty)

                Spacer()
            }
            .padding()
            .keyboardDismissable()
            .navigationTitle("Captura rápida")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func save() {
        let body = CreateTaskBody(
            title: title,
            priorityLevel: selectedLevel,
            inbox: selectedLevel == nil ? true : false
        )
        onCreate(body)
        dismiss()
    }
}

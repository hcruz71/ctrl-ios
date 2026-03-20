import SwiftUI

struct DelegationEmailSheet: View {
    @ObservedObject var vm: DelegationsViewModel
    let delegation: Delegation
    @Environment(\.dismiss) private var dismiss

    @State private var draft: String = ""
    @State private var isLoading = true
    @State private var sent = false

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Generando borrador…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if sent {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.green)
                        Text("Correo marcado como enviado")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: 0) {
                        TextEditor(text: $draft)
                            .font(.body)
                            .padding()

                        Divider()

                        HStack(spacing: 16) {
                            Button {
                                Task {
                                    if let result = await vm.buildEmailDraft(
                                        id: delegation.id, send: true
                                    ) {
                                        draft = result.emailDraft
                                        sent = true
                                    }
                                }
                            } label: {
                                Label("Enviar", systemImage: "paperplane.fill")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.ctrlPurple)
                                    .foregroundStyle(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Correo de delegación")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
            .task {
                if let result = await vm.buildEmailDraft(
                    id: delegation.id, send: false
                ) {
                    draft = result.emailDraft
                }
                isLoading = false
            }
        }
    }
}

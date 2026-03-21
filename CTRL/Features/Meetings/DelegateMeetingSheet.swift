import SwiftUI

struct DelegateMeetingSheet: View {
    @ObservedObject var vm: MeetingsViewModel
    let meeting: Meeting
    @Environment(\.dismiss) private var dismiss

    enum Step { case selectContact, generating, preview }
    @State private var step: Step = .selectContact
    @State private var selectedContactIds: Set<UUID> = []
    @State private var briefing = ""
    @State private var sendEmail = true
    @State private var delegatedMeeting: Meeting?

    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case .selectContact: selectContactView
                case .generating:    generatingView
                case .preview:       previewView
                }
            }
            .navigationTitle("Delegar reunion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
    }

    // MARK: - Step 1

    private var selectContactView: some View {
        VStack(spacing: 16) {
            Text("Selecciona a quien delegar la asistencia")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top)

            ContactPickerView(selectedIds: $selectedContactIds, singleSelection: true)

            Button {
                guard let contactId = selectedContactIds.first else { return }
                Task { await delegate(contactId: contactId) }
            } label: {
                Text("Generar briefing")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedContactIds.isEmpty ? Color.gray : Color.ctrlPurple)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(selectedContactIds.isEmpty)
            .padding(.horizontal)
            .padding(.bottom)
        }
    }

    // MARK: - Step 2

    private var generatingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
            Text("Generando briefing con IA...")
                .font(.headline)
            Text("Analizando agenda, participantes y objetivo vinculado")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }

    // MARK: - Step 3

    private var previewView: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(meeting.title)
                        .font(.headline)
                    if let date = meeting.meetingDate, let time = meeting.meetingTime {
                        Text("\(date) \(time)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Text("Delegada")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.blue.opacity(0.15))
                    .foregroundStyle(.blue)
                    .clipShape(Capsule())
            }
            .padding()

            Divider()

            // Briefing
            ScrollView {
                Text(briefing)
                    .font(.body)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider()

            // Actions
            VStack(spacing: 12) {
                Toggle("Enviar correo al delegado", isOn: $sendEmail)
                    .font(.subheadline)

                HStack(spacing: 12) {
                    Button {
                        UIPasteboard.general.string = briefing
                    } label: {
                        Label("Copiar", systemImage: "doc.on.doc")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray5))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    Button {
                        dismiss()
                    } label: {
                        Text("Listo")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.ctrlPurple)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Action

    private func delegate(contactId: UUID) async {
        step = .generating

        if let result = await vm.delegateMeeting(
            meetingId: meeting.id,
            contactId: contactId,
            sendEmail: sendEmail
        ) {
            briefing = result.delegateBriefing ?? "Briefing no disponible."
            delegatedMeeting = result
            step = .preview
        } else {
            step = .selectContact
        }
    }
}

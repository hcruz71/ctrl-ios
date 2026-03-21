import SwiftUI

struct AbsencesListView: View {
    @State private var absences: [UserAbsence] = []
    @State private var isLoading = true
    @State private var showingAdd = false

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if absences.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "sun.max")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("Sin ausencias programadas")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(absences) { absence in
                        NavigationLink {
                            AbsenceDetailView(absence: absence, onUpdate: { await loadAbsences() })
                        } label: {
                            AbsenceRow(absence: absence)
                        }
                    }
                    .onDelete { indices in
                        Task {
                            for i in indices {
                                let id = absences[i].id
                                try? await APIClient.shared.requestVoid(.absence(id: id))
                            }
                            await loadAbsences()
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Ausencias")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showingAdd = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            AbsenceFormView {
                showingAdd = false
                Task { await loadAbsences() }
            }
        }
        .task { await loadAbsences() }
    }

    private func loadAbsences() async {
        isLoading = true
        do {
            absences = try await APIClient.shared.request(.absences)
        } catch {
            absences = []
        }
        isLoading = false
    }
}

private struct AbsenceRow: View {
    let absence: UserAbsence

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(absence.type.capitalized)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                if absence.isActive {
                    Text("Activa")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.15))
                        .foregroundStyle(.green)
                        .clipShape(Capsule())
                }
                if absence.documentsGeneratedAt != nil {
                    Image(systemName: "doc.text.fill")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
            }
            Text("\(absence.startDate) al \(absence.endDate)")
                .font(.caption)
                .foregroundStyle(.secondary)
            if let sub = absence.substituteName {
                Label("Sustituto: \(sub)", systemImage: "person")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

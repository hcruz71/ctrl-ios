import SwiftUI

struct ObjectivesView: View {
    @StateObject private var vm = ObjectivesViewModel()
    @State private var showingAdd = false
    @State private var newTitle = ""
    @State private var newKeyResult = ""
    @State private var newArea = "Personal"
    @State private var newHorizon = "mes"

    private let areas = ["SSFF", "BanCoppel", "Afore", "Omnicanal", "Personal"]
    private let horizons = ["semana", "mes", "trimestre", "año"]

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading && vm.objectives.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if vm.objectives.isEmpty {
                    EmptyStateView(
                        icon: "target",
                        title: "Sin objetivos",
                        message: "Agrega tu primer objetivo para comenzar."
                    )
                } else {
                    List {
                        ForEach(vm.objectives) { objective in
                            ObjectiveRowView(objective: objective)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        Task { await vm.delete(id: objective.id) }
                                    } label: {
                                        Label("Eliminar", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .listStyle(.plain)
                    .refreshable { await vm.fetchObjectives() }
                }
            }
            .navigationTitle("Objetivos")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingAdd = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .withProfileButton()
            .sheet(isPresented: $showingAdd) {
                addObjectiveSheet
            }
            .task { await vm.fetchObjectives() }
            .alert("Error", isPresented: .constant(vm.errorMessage != nil)) {
                Button("OK") { vm.errorMessage = nil }
            } message: {
                Text(vm.errorMessage ?? "")
            }
        }
    }

    private var addObjectiveSheet: some View {
        NavigationStack {
            Form {
                Section("Objetivo") {
                    TextField("Título", text: $newTitle)
                    TextField("Resultado clave", text: $newKeyResult)
                }
                Section("Clasificación") {
                    Picker("Área", selection: $newArea) {
                        ForEach(areas, id: \.self) { Text($0) }
                    }
                    Picker("Horizonte", selection: $newHorizon) {
                        ForEach(horizons, id: \.self) { Text($0) }
                    }
                }
            }
            .navigationTitle("Nuevo objetivo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { showingAdd = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        let body = CreateObjectiveBody(
                            title: newTitle,
                            keyResult: newKeyResult.isEmpty ? nil : newKeyResult,
                            area: newArea,
                            horizon: newHorizon
                        )
                        Task {
                            await vm.create(body)
                            showingAdd = false
                            newTitle = ""
                            newKeyResult = ""
                        }
                    }
                    .disabled(newTitle.isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    ObjectivesView()
}

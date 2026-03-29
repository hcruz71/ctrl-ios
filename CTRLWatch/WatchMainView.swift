import SwiftUI
import WatchKit

struct WatchMainView: View {
    @EnvironmentObject var connectivity: WatchConnectivityManager
    @State private var dictationText = ""
    @State private var showingDictation = false

    var body: some View {
        VStack(spacing: 10) {
            // Status
            Text(statusLabel)
                .font(.caption2)
                .foregroundStyle(statusColor)

            Spacer()

            // Mic button — taps to open native dictation
            Button {
                showingDictation = true
            } label: {
                Circle()
                    .fill(buttonColor)
                    .frame(width: 80, height: 80)
                    .overlay {
                        if connectivity.state == .processing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: buttonIcon)
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                    }
            }
            .buttonStyle(.plain)
            .disabled(connectivity.state == .processing)
            // Native dictation sheet — Apple's built-in voice input for watchOS
            .sheet(isPresented: $showingDictation) {
                DictationView(text: $dictationText) {
                    showingDictation = false
                    if !dictationText.isEmpty {
                        connectivity.sendDictatedText(dictationText)
                        dictationText = ""
                    }
                }
            }

            Spacer()

            // Last response
            if !connectivity.lastResponse.isEmpty {
                Text(connectivity.lastResponse)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(4)
                    .multilineTextAlignment(.center)
            }
            // Connection indicator
            HStack(spacing: 4) {
                Circle()
                    .fill(WatchAPIService.shared.isAuthenticated ? Color.green : Color.yellow)
                    .frame(width: 6, height: 6)
                Text(WatchAPIService.shared.isAuthenticated ? "Directo" : "Via iPhone")
                    .font(.system(size: 8))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 4)
        .navigationTitle("VERA")
    }

    private var statusLabel: String {
        switch connectivity.state {
        case .idle:       return "Toca para hablar"
        case .listening:  return "Escuchando..."
        case .processing: return "Procesando..."
        case .responding: return "Respondiendo..."
        }
    }

    private var statusColor: Color {
        switch connectivity.state {
        case .idle:       return .secondary
        case .listening:  return .green
        case .processing: return .orange
        case .responding: return .blue
        }
    }

    private var buttonColor: Color {
        switch connectivity.state {
        case .idle:       return .purple
        case .listening:  return .green
        case .processing: return .orange
        case .responding: return .blue
        }
    }

    private var buttonIcon: String {
        switch connectivity.state {
        case .idle:       return "mic"
        case .listening:  return "waveform"
        case .processing: return "ellipsis"
        case .responding: return "speaker.wave.2.fill"
        }
    }
}

// MARK: - Native Dictation View for watchOS

private struct DictationView: View {
    @Binding var text: String
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text("Habla tu comando")
                .font(.headline)

            TextField("Dicta aqui...", text: $text)
                .multilineTextAlignment(.center)

            Button("Enviar") {
                onDone()
            }
            .buttonStyle(.borderedProminent)
            .disabled(text.isEmpty)
        }
        .padding()
    }
}

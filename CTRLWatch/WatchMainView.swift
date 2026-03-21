import SwiftUI
import WatchKit

struct WatchMainView: View {
    @EnvironmentObject var connectivity: WatchConnectivityManager
    @State private var isPressed = false

    var body: some View {
        VStack(spacing: 12) {
            // Status
            Text(statusLabel)
                .font(.caption2)
                .foregroundStyle(statusColor)
                .frame(maxWidth: .infinity, alignment: .center)

            Spacer()

            // Push-to-talk button
            Button {
                // Tap action handled by long press
            } label: {
                Circle()
                    .fill(buttonColor)
                    .frame(width: 80, height: 80)
                    .overlay {
                        Image(systemName: buttonIcon)
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .scaleEffect(isPressed ? 1.15 : 1.0)
            }
            .buttonStyle(.plain)
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.1)
                    .onChanged { _ in
                        guard connectivity.state == .idle else { return }
                        isPressed = true
                        WKInterfaceDevice.current().play(.start)
                        connectivity.startDictation()
                    }
            )
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { _ in
                        if isPressed {
                            isPressed = false
                            connectivity.stopDictation()
                        }
                    }
            )

            Spacer()

            // Response text
            if !connectivity.lastResponse.isEmpty {
                Text(connectivity.lastResponse)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 8)
        .navigationTitle("CTRL")
    }

    private var statusLabel: String {
        switch connectivity.state {
        case .idle:       return "Manten presionado para hablar"
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
        case .idle:       return .gray
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

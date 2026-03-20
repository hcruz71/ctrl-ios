import SwiftUI

struct AssistantView: View {
    @StateObject private var viewModel = AssistantViewModel()
    @State private var isButtonPressed = false
    @State private var pulseAnimation = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.messages) { message in
                                MessageBubbleView(message: message)
                                    .id(message.id)
                            }

                            // Live transcript preview
                            if !viewModel.liveTranscript.isEmpty {
                                HStack {
                                    Spacer(minLength: 60)
                                    Text(viewModel.liveTranscript)
                                        .font(.body)
                                        .foregroundStyle(.white.opacity(0.7))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .background(Color.ctrlPurple.opacity(0.5))
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                }
                                .padding(.horizontal)
                                .id("transcript")
                            }

                            if viewModel.isLoading {
                                HStack {
                                    ProgressView()
                                        .tint(Color.ctrlPurple)
                                    Text("Pensando…")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                }
                                .padding(.horizontal)
                                .id("loading")
                            }
                        }
                        .padding(.vertical, 12)
                    }
                    .onChange(of: viewModel.messages.count) { _ in
                        withAnimation {
                            proxy.scrollTo(
                                viewModel.messages.last?.id.uuidString ?? "loading",
                                anchor: .bottom
                            )
                        }
                    }
                    .onChange(of: viewModel.liveTranscript) { _ in
                        withAnimation {
                            if viewModel.liveTranscript.isEmpty {
                                proxy.scrollTo(
                                    viewModel.messages.last?.id.uuidString ?? "loading",
                                    anchor: .bottom
                                )
                            } else {
                                proxy.scrollTo("transcript", anchor: .bottom)
                            }
                        }
                    }
                }

                Divider()

                // Push-to-talk area
                VStack(spacing: 10) {
                    // State label
                    Text(stateLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(height: 16)

                    // Big circular button
                    ZStack {
                        // Pulse ring — listening
                        if viewModel.voiceState == .listening {
                            Circle()
                                .stroke(Color.ctrlPurple.opacity(0.4), lineWidth: 3)
                                .frame(width: 100, height: 100)
                                .scaleEffect(pulseAnimation ? 1.4 : 1.0)
                                .opacity(pulseAnimation ? 0.0 : 0.8)
                                .animation(
                                    .easeOut(duration: 1.2)
                                        .repeatForever(autoreverses: false),
                                    value: pulseAnimation
                                )
                        }

                        // Pulse ring — speaking
                        if viewModel.voiceState == .speaking {
                            Circle()
                                .fill(Color.green.opacity(0.15))
                                .frame(width: 100, height: 100)
                                .scaleEffect(pulseAnimation ? 1.15 : 0.95)
                                .animation(
                                    .easeInOut(duration: 0.7)
                                        .repeatForever(autoreverses: true),
                                    value: pulseAnimation
                                )
                        }

                        // Main circle
                        Circle()
                            .fill(buttonColor)
                            .frame(width: 80, height: 80)
                            .shadow(color: buttonColor.opacity(0.4), radius: 8, y: 4)
                            .scaleEffect(isButtonPressed ? 0.9 : 1.0)
                            .animation(.easeInOut(duration: 0.1), value: isButtonPressed)

                        // Icon / spinner
                        Group {
                            if viewModel.voiceState == .processing {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(1.3)
                            } else {
                                Image(systemName: buttonIcon)
                                    .font(.system(size: 30, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    .frame(width: 110, height: 110)
                    .contentShape(Circle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                guard !isButtonPressed else { return }
                                isButtonPressed = true
                                viewModel.handleButtonPress()
                            }
                            .onEnded { _ in
                                isButtonPressed = false
                                viewModel.handleButtonRelease()
                            }
                    )

                    // Hint
                    Text(hintLabel)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .frame(height: 14)
                }
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(.bar)
                .onAppear {
                    pulseAnimation = true
                    viewModel.startSession()
                }
            }
            .navigationTitle("Asistente")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(Color.ctrlPurple)
                        Text("Asistente CTRL")
                            .font(.headline)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.toggleMicMode()
                        }
                    } label: {
                        Image(systemName: viewModel.micMode == .pushToTalk
                              ? "hand.tap.fill"
                              : "waveform.circle.fill")
                            .foregroundStyle(viewModel.micMode == .continuousListening
                                             ? .green : .secondary)
                            .font(.system(size: 18))
                    }
                    .help(viewModel.micMode == .pushToTalk
                          ? "Cambiar a escucha continua"
                          : "Cambiar a bajo demanda")
                }
            }
            .withProfileButton()
            .alert("Error", isPresented: .init(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    // MARK: - Button appearance

    private var buttonColor: Color {
        switch viewModel.voiceState {
        case .idle:       return .gray
        case .listening:  return Color.ctrlPurple
        case .processing: return .orange
        case .speaking:   return .green
        }
    }

    private var buttonIcon: String {
        switch viewModel.voiceState {
        case .idle:       return "mic"
        case .listening:  return "waveform"
        case .processing: return "ellipsis"
        case .speaking:   return "speaker.wave.2.fill"
        }
    }

    private var stateLabel: String {
        switch viewModel.voiceState {
        case .idle:       return ""
        case .listening:  return "Escuchando…"
        case .processing: return "Enviando a Claude…"
        case .speaking:   return "Claude está respondiendo"
        }
    }

    private var hintLabel: String {
        switch viewModel.voiceState {
        case .idle:
            return viewModel.micMode == .pushToTalk
                ? "Mantén presionado para hablar"
                : "Escucha continua activa"
        case .listening:
            return viewModel.micMode == .pushToTalk
                ? "Suelta para enviar"
                : "Toca para enviar ahora"
        case .processing: return ""
        case .speaking:   return "Toca para interrumpir"
        }
    }
}

#Preview {
    AssistantView()
}

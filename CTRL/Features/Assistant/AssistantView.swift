import SwiftUI

struct AssistantView: View {
    @StateObject private var viewModel = AssistantViewModel()
    @State private var isButtonPressed = false
    @State private var pulseAnimation = false
    @State private var usageSummary: UsageSummary?
    @State private var showingUsage = false

    // Thinking messages
    private let thinkingMessages = [
        "Pensando...",
        "Consultando tus datos...",
        "Analizando...",
        "Preparando respuesta..."
    ]
    @State private var thinkingIndex = 0
    @State private var thinkingTimer: Timer?

    // Mic toast
    @State private var showMicToast = false
    @State private var micToastMessage = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Usage warning banner
                if let s = usageSummary {
                    if s.percentageUsed >= 90 && s.interactionsRemaining > 0 {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text("Quedan \(s.interactionsRemaining) interacciones")
                            Spacer()
                        }
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.orange)
                    } else if s.interactionsRemaining <= 0 {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                            Text("Limite alcanzado")
                            Spacer()
                            Button("Ver plan") { showingUsage = true }
                                .font(.caption.bold())
                        }
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.red)
                    }
                }

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
                                HStack(spacing: 8) {
                                    ThinkingDotsView()
                                    Text(thinkingMessages[thinkingIndex])
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .animation(.easeInOut(duration: 0.3), value: thinkingIndex)
                                    Spacer()
                                }
                                .padding(.horizontal)
                                .id("loading")
                                .onAppear { startThinkingTimer() }
                                .onDisappear { stopThinkingTimer() }
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
                    if hasByokKey {
                        Text("Ilimitado")
                            .font(.caption.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.15))
                            .foregroundStyle(.green)
                            .clipShape(Capsule())
                    } else if let s = usageSummary {
                        Button {
                            showingUsage = true
                        } label: {
                            Text("\(s.interactionsUsed)/\(s.interactionsLimit)")
                                .font(.caption.bold().monospacedDigit())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(usageBadgeColor(s.percentageUsed).opacity(0.15))
                                .foregroundStyle(usageBadgeColor(s.percentageUsed))
                                .clipShape(Capsule())
                        }
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
            .sheet(isPresented: $showingUsage) {
                NavigationStack {
                    UsageView()
                }
            }
            .task {
                do {
                    usageSummary = try await APIClient.shared.request(.usageSummary)
                } catch { }
            }
            // Mic toast overlay
            .overlay(alignment: .top) {
                if showMicToast {
                    Text(micToastMessage)
                        .font(.caption)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, 8)
                }
            }
            .onChange(of: viewModel.micStatus) { status in
                guard let status else { return }
                micToastMessage = status
                withAnimation { showMicToast = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation { showMicToast = false }
                    viewModel.micStatus = nil
                }
            }
            // Network error retry banner
            .overlay(alignment: .bottom) {
                if viewModel.networkError {
                    HStack {
                        Image(systemName: "wifi.slash")
                        Text(LanguageManager.shared.t("assistant.no_connection"))
                            .font(.subheadline)
                        Spacer()
                        Button(LanguageManager.shared.t("assistant.retry")) {
                            viewModel.retryLastMessage()
                        }
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.ctrlPurple)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .transition(.move(edge: .bottom))
                }
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
        case .paused:     return .yellow
        }
    }

    private var buttonIcon: String {
        switch viewModel.voiceState {
        case .idle:       return "mic"
        case .listening:  return "waveform"
        case .processing: return "ellipsis"
        case .speaking:   return "speaker.wave.2.fill"
        case .paused:     return "pause.fill"
        }
    }

    private var stateLabel: String {
        if viewModel.isWaitingToSend {
            return "Enviando en un momento…"
        }
        switch viewModel.voiceState {
        case .idle:       return ""
        case .listening:  return "Escuchando…"
        case .processing: return "Enviando a Claude…"
        case .speaking:   return "Claude está respondiendo"
        case .paused:     return "Pausado"
        }
    }

    private var hasByokKey: Bool {
        KeychainHelper.getAnthropicKey()?.isEmpty == false
    }

    private func usageBadgeColor(_ pct: Int) -> Color {
        if pct >= 90 { return .red }
        if pct >= 70 { return .orange }
        return .green
    }

    // MARK: - Thinking timer

    private func startThinkingTimer() {
        thinkingIndex = 0
        thinkingTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            DispatchQueue.main.async {
                thinkingIndex = (thinkingIndex + 1) % thinkingMessages.count
            }
        }
    }

    private func stopThinkingTimer() {
        thinkingTimer?.invalidate()
        thinkingTimer = nil
        thinkingIndex = 0
    }

    private var hintLabel: String {
        if viewModel.isWaitingToSend {
            return "Presiona para seguir hablando"
        }
        switch viewModel.voiceState {
        case .idle:
            return viewModel.micMode == MicMode.pushToTalk
                ? "Mantén presionado para hablar"
                : "Escucha continua activa"
        case .listening:
            return viewModel.micMode == MicMode.pushToTalk
                ? "Suelta para enviar"
                : "Toca para pausar"
        case .processing: return ""
        case .speaking:
            return viewModel.micMode == MicMode.pushToTalk
                ? "Toca para interrumpir"
                : "Toca para pausar"
        case .paused:     return "Toca para continuar"
        }
    }
}

// MARK: - Thinking Dots Animation

struct ThinkingDotsView: View {
    @State private var dotPhase = 0.0

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.ctrlPurple)
                    .frame(width: 6, height: 6)
                    .scaleEffect(dotScale(for: index))
                    .opacity(dotOpacity(for: index))
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                dotPhase = 1.0
            }
        }
    }

    private func dotScale(for index: Int) -> Double {
        let offset = Double(index) * 0.3
        let phase = (dotPhase + offset).truncatingRemainder(dividingBy: 1.5)
        return 0.6 + phase * 0.4
    }

    private func dotOpacity(for index: Int) -> Double {
        let offset = Double(index) * 0.3
        let phase = (dotPhase + offset).truncatingRemainder(dividingBy: 1.5)
        return 0.4 + phase * 0.6
    }
}

#Preview {
    AssistantView()
}

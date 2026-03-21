import SwiftUI
import SwiftData

struct TimerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.marginTheme) private var theme
    @Query private var tips: [WritingTip]
    @ScaledMetric(relativeTo: .largeTitle) private var timerFontSize: Double = 56

    @State private var vm = TimerViewModel()
    @State private var tipService: TipRotationService?
    @State private var audioEngine = TypewriterAudioEngine()
    @State private var showLogSession = false
    @State private var colonVisible = true
    @State private var bellHapticTrigger = 0
    @State private var carriageHapticTrigger = 0
    @State private var savedWordCount: Int?

    var onSave: ((Int) -> Void)?

    var body: some View {
        NavigationStack {
            ZStack {
                theme.background.ignoresSafeArea()

                VStack(spacing: 32) {
                    Spacer()

                    VStack(spacing: 4) {
                        Text(vm.state == .paused ? "PAUSED" : "WRITING")
                            .font(.literata(10, weight: .medium))
                            .foregroundStyle(theme.textFaint)
                            .tracking(2)

                        timerDisplay
                    }

                    HStack(spacing: 24) {
                        switch vm.state {
                        case .ready:
                            TimerButton(label: "Start", icon: "play.fill", tint: theme.amber, action: vm.start)
                        case .running:
                            TimerButton(label: "Pause", icon: "pause.fill", tint: theme.amber, action: vm.pause)
                            TimerButton(label: "Stop", icon: "stop.fill", tint: Color(hex: 0x7A5C50), action: vm.stop)
                        case .paused:
                            TimerButton(label: "Resume", icon: "play.fill", tint: theme.amber, action: vm.resume)
                            TimerButton(label: "Stop", icon: "stop.fill", tint: Color(hex: 0x7A5C50), action: vm.stop)
                        case .stopped:
                            EmptyView()
                        }
                    }

                    // Typewriter mechanism: paper feed (above) → carriage rail → platen (below)
                    if vm.showMechanism {
                        typewriterMechanism
                            .padding(.horizontal, 12)
                            .transition(.opacity)
                    }

                    Spacer()
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(theme.textDim)
                }
            }
        }
        .onAppear {
            let service = TipRotationService(tips: tips)
            tipService = service
            vm.loadTip(service.nextTip())

            // Wire up audio + haptic callbacks
            vm.onKeyStrike = { [audioEngine] in
                if !audioEngine.isMuted { audioEngine.playKeyStrike() }
            }
            vm.onBellDing = { [audioEngine] in
                if !audioEngine.isMuted { audioEngine.playBell() }
                bellHapticTrigger += 1
            }
            vm.onCarriageReturn = { [audioEngine] in
                if !audioEngine.isMuted { audioEngine.playCarriageReturn() }
                carriageHapticTrigger += 1
            }

            vm.start()
        }
        .onDisappear {
            audioEngine.shutdown()
        }
        .task {
            // Colon pulse animation
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(530))
                withAnimation(.easeInOut(duration: 0.15)) {
                    colonVisible.toggle()
                }
            }
        }
        .onChange(of: vm.state) { _, newState in
            if newState == .stopped {
                showLogSession = true
            }
        }
        .sheet(isPresented: $showLogSession, onDismiss: {
            if let wordCount = savedWordCount {
                savedWordCount = nil
                onSave?(wordCount)
            }
            dismiss()
        }) {
            LogSessionView(
                prefilledDuration: vm.elapsedSeconds,
                onSave: { wordCount in
                    savedWordCount = wordCount
                }
            )
        }
    }

    // MARK: - Typewriter Mechanism

    /// Layout: paper feed (text rises above) → carriage rail + slider → platen/roller
    private var typewriterMechanism: some View {
        VStack(spacing: 0) {
            // Paper feed — text accumulates upward out of the machine
            paperFeed
                .offset(y: 5)

            // Carriage rail + slider
            carriageRail
                .padding(.horizontal, 16)

            // Platen/roller
            platen
                .padding(.top, 5)
        }
        .sensoryFeedback(.impact(flexibility: .rigid), trigger: bellHapticTrigger)
        .sensoryFeedback(.impact(weight: .light), trigger: carriageHapticTrigger)
    }

    /// Paper emerging above the platen — completed lines at top, current line at bottom (strike point)
    private var paperFeed: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Completed lines — oldest at top, paper has risen
            ForEach(Array(vm.completedLines.enumerated()), id: \.offset) { lineIndex, line in
                let globalOffset = vm.completedLines[0..<lineIndex].reduce(0) { $0 + $1.count }
                TypewriterText(
                    text: line,
                    fontSize: 14,
                    inkIndices: inkSlice(from: globalOffset, count: line.count)
                )
                .padding(.vertical, 2)
            }

            // Current line — the strike point, fixed just above the platen
            if !vm.currentLine.isEmpty {
                strikePointLine
            }

            // Attribution after tip completes
            if !vm.attributionText.isEmpty {
                Text(vm.attributionText)
                    .font(.literata(12))
                    .italic()
                    .foregroundStyle(MarginTheme.inkLight.opacity(0.5))
                    .padding(.top, 8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 100)
        .paperSurface(ruledLines: true, redMargin: true)
    }

    /// The current line being typed — each new character gets strike animation on insertion
    private var strikePointLine: some View {
        HStack(spacing: 0) {
            let chars = Array(vm.currentLine)
            let globalOffset = vm.completedLines.reduce(0) { $0 + $1.count }
            ForEach(Array(chars.enumerated()), id: \.offset) { index, char in
                let inkIdx = inkIndex(at: globalOffset + index)
                Text(String(char))
                    .font(.typewriter(14))
                    .foregroundStyle(MarginTheme.inkVariation[inkIdx])
                    .rotationEffect(.degrees(jitterRotation(for: globalOffset + index)))
                    .offset(y: jitterY(for: globalOffset + index))
                    .transition(.asymmetric(
                        insertion: .modifier(
                            active: StrikeModifier(scale: 1.12, offsetY: -1),
                            identity: StrikeModifier(scale: 1.0, offsetY: 0)
                        ),
                        removal: .identity
                    ))
            }
        }
        .animation(.easeOut(duration: 0.05), value: vm.currentLine.count)
        .padding(.vertical, 2)
    }

    // MARK: - Carriage Rail

    private var carriageRail: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Rail track
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(LinearGradient(
                        colors: [Color(hex: 0x4A4540), Color(hex: 0x8A8070), Color(hex: 0x4A4540)],
                        startPoint: .top, endPoint: .bottom
                    ))
                    .frame(height: 3)

                // Slider block
                RoundedRectangle(cornerRadius: 2)
                    .fill(LinearGradient(
                        colors: [Color(hex: 0x8A8070), Color(hex: 0x6A6055), Color(hex: 0x4A4540)],
                        startPoint: .top, endPoint: .bottom
                    ))
                    .frame(width: 20, height: 15)
                    .shadow(color: .black.opacity(0.4), radius: 2, y: 1)
                    .overlay(alignment: .top) {
                        // Amber print-guide dot — points UP toward paper/strike point
                        Circle()
                            .fill(theme.amber)
                            .frame(width: 3, height: 3)
                            .shadow(color: theme.amber.opacity(0.4), radius: 2)
                            .offset(y: -3)
                    }
                    .offset(x: vm.carriagePosition * (geo.size.width - 20))
                    .animation(
                        vm.carriagePosition == 0
                            ? .easeIn(duration: 0.08)
                            : .none, // Step-locked, discrete — no transition
                        value: vm.carriagePosition
                    )
            }
            .frame(height: 15)
        }
        .frame(height: 15)
    }

    // MARK: - Platen

    private var platen: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(LinearGradient(
                colors: [
                    Color(hex: 0x1A1714), Color(hex: 0x2E2822),
                    Color(hex: 0x3A342C), Color(hex: 0x2E2822),
                    Color(hex: 0x1A1714)
                ],
                startPoint: .top, endPoint: .bottom
            ))
            .frame(height: 24)
            .shadow(color: .black.opacity(0.4), radius: 4, y: 2)
            .overlay {
                HStack {
                    platenKnob.offset(x: -3)
                    Spacer()
                    platenKnob.offset(x: 3)
                }
            }
    }

    private var platenKnob: some View {
        Circle()
            .fill(RadialGradient(
                colors: [Color(hex: 0x8A8070), Color(hex: 0x4A4540)],
                center: UnitPoint(x: 0.4, y: 0.35),
                startRadius: 0, endRadius: 8
            ))
            .frame(width: 14, height: 14)
            .shadow(color: .black.opacity(0.3), radius: 1, y: 1)
    }

    // MARK: - Timer Display

    private var timerDisplay: some View {
        HStack(spacing: 0) {
            let parts = vm.formattedTime.split(separator: ":", omittingEmptySubsequences: false)
            ForEach(Array(parts.enumerated()), id: \.offset) { index, part in
                if index > 0 {
                    Text(":")
                        .font(.mono(timerFontSize))
                        .foregroundStyle(theme.text)
                        .monospacedDigit()
                        .opacity(vm.state == .running ? (colonVisible ? 1 : 0.2) : 1)
                }
                Text(part)
                    .font(.mono(timerFontSize))
                    .foregroundStyle(theme.text)
                    .monospacedDigit()
            }
        }
    }

    // MARK: - Ink & Jitter Helpers

    private func inkIndex(at globalIndex: Int) -> Int {
        guard globalIndex < vm.inkWeights.count else { return 0 }
        return vm.inkWeights[globalIndex]
    }

    private func inkSlice(from offset: Int, count: Int) -> [Int] {
        let end = min(offset + count, vm.inkWeights.count)
        guard offset < end else { return [] }
        return Array(vm.inkWeights[offset..<end])
    }

    private func jitterY(for index: Int) -> Double {
        let seed = Double(index * 7 + 3)
        return sin(seed) * 0.5
    }

    private func jitterRotation(for index: Int) -> Double {
        let seed = Double(index * 13 + 7)
        return sin(seed) * 0.4
    }
}

// MARK: - Strike Animation Modifier

/// Animates character appearance: scale(1.12)→1.0, translateY(-1px)→0
private struct StrikeModifier: ViewModifier {
    let scale: Double
    let offsetY: Double

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .offset(y: offsetY)
    }
}

import SwiftUI
import SwiftData

struct TimerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.marginTheme) private var theme
    @Query private var tips: [WritingTip]
    @ScaledMetric(relativeTo: .largeTitle) private var timerFontSize: Double = 56

    @State private var vm = TimerViewModel()
    @State private var tipService: TipRotationService?
    @State private var showLogSession = false

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

                        Text(vm.formattedTime)
                            .font(.mono(timerFontSize))
                            .foregroundStyle(theme.text)
                            .monospacedDigit()
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

                    // Typewriter carriage mechanism + paper feed
                    if !vm.typedText.isEmpty || vm.state == .running {
                        VStack(spacing: 0) {
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 1.5)
                                        .fill(LinearGradient(
                                            colors: [Color(hex: 0x4A4540), Color(hex: 0x8A8070), Color(hex: 0x4A4540)],
                                            startPoint: .top, endPoint: .bottom
                                        ))
                                        .frame(height: 3)
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(LinearGradient(
                                            colors: [Color(hex: 0x8A8070), Color(hex: 0x6A6055), Color(hex: 0x4A4540)],
                                            startPoint: .top, endPoint: .bottom
                                        ))
                                        .frame(width: 20, height: 15)
                                        .shadow(color: .black.opacity(0.4), radius: 2, y: 1)
                                        .overlay(alignment: .bottom) {
                                            Circle()
                                                .fill(theme.amber)
                                                .frame(width: 3, height: 3)
                                                .shadow(color: theme.amber.opacity(0.4), radius: 2)
                                                .offset(y: 3)
                                        }
                                        .offset(x: vm.carriagePosition * (geo.size.width - 20))
                                        .animation(.linear(duration: 0.1), value: vm.carriagePosition)
                                }
                                .frame(height: 15)
                            }
                            .frame(height: 15)
                            .padding(.horizontal, 16)

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
                                        Circle()
                                            .fill(RadialGradient(
                                                colors: [Color(hex: 0x8A8070), Color(hex: 0x4A4540)],
                                                center: UnitPoint(x: 0.4, y: 0.35),
                                                startRadius: 0, endRadius: 8
                                            ))
                                            .frame(width: 14, height: 14)
                                            .shadow(color: .black.opacity(0.3), radius: 1, y: 1)
                                            .offset(x: -3)
                                        Spacer()
                                        Circle()
                                            .fill(RadialGradient(
                                                colors: [Color(hex: 0x8A8070), Color(hex: 0x4A4540)],
                                                center: UnitPoint(x: 0.4, y: 0.35),
                                                startRadius: 0, endRadius: 8
                                            ))
                                            .frame(width: 14, height: 14)
                                            .shadow(color: .black.opacity(0.3), radius: 1, y: 1)
                                            .offset(x: 3)
                                    }
                                }
                                .padding(.top, 5)

                            VStack(alignment: .leading) {
                                TypewriterText(text: vm.typedText, fontSize: 14)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .frame(minHeight: 120)
                            .paperSurface(ruledLines: true, redMargin: true)
                            .offset(y: -5)
                        }
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
            vm.start()
        }
        .onChange(of: vm.state) { _, newState in
            if newState == .stopped {
                showLogSession = true
            }
        }
        .sheet(isPresented: $showLogSession, onDismiss: { dismiss() }) {
            LogSessionView(prefilledDuration: vm.elapsedSeconds)
        }
    }
}

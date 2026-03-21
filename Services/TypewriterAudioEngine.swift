import AVFoundation

@MainActor
final class TypewriterAudioEngine {
    private let engine = AVAudioEngine()
    private var keyStrikeBuffer: AVAudioPCMBuffer?
    private var bellBuffer: AVAudioPCMBuffer?
    private var carriageReturnBuffer: AVAudioPCMBuffer?
    private var playerPool: [AVAudioPlayerNode] = []
    private var nextPlayerIndex = 0
    private let poolSize = 4
    private var isRunning = false

    init() {
        setupEngine()
    }

    private func setupEngine() {
        // Configure audio session for playback — required on iOS/Simulator
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // Audio session setup failed; engine will not start
        }

        keyStrikeBuffer = loadBuffer(named: "key-strike")
        bellBuffer = loadBuffer(named: "bell")
        carriageReturnBuffer = loadBuffer(named: "carriage-return")

        // Need at least one buffer's format to connect players
        let format = keyStrikeBuffer?.format ?? bellBuffer?.format ?? carriageReturnBuffer?.format
        guard let format else {
            return
        }

        for _ in 0..<poolSize {
            let player = AVAudioPlayerNode()
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: format)
            playerPool.append(player)
        }

        do {
            try engine.start()
            isRunning = true
        } catch {
            isRunning = false
        }
    }

    private func loadBuffer(named name: String) -> AVAudioPCMBuffer? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "caf", subdirectory: "Audio"),
              let file = try? AVAudioFile(forReading: url),
              let buffer = AVAudioPCMBuffer(
                  pcmFormat: file.processingFormat,
                  frameCapacity: AVAudioFrameCount(file.length)
              ) else { return nil }
        try? file.read(into: buffer)
        return buffer
    }

    func playKeyStrike() {
        guard isRunning, let buffer = keyStrikeBuffer else { return }
        let player = playerPool[nextPlayerIndex % poolSize]
        nextPlayerIndex += 1
        if player.isPlaying { player.stop() }
        player.volume = Float.random(in: 0.7...1.0)
        player.rate = Float.random(in: 0.94...1.08)
        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        player.play()
    }

    func playBell() {
        guard isRunning, let buffer = bellBuffer else { return }
        let player = playerPool[nextPlayerIndex % poolSize]
        nextPlayerIndex += 1
        if player.isPlaying { player.stop() }
        player.volume = 0.8
        player.rate = 1.0
        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        player.play()
    }

    func playCarriageReturn() {
        guard isRunning, let buffer = carriageReturnBuffer else { return }
        let player = playerPool[nextPlayerIndex % poolSize]
        nextPlayerIndex += 1
        if player.isPlaying { player.stop() }
        player.volume = 0.85
        player.rate = 1.3
        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        player.play()
    }

    func shutdown() {
        playerPool.forEach { $0.stop() }
        engine.stop()
        isRunning = false
    }

    var isMuted: Bool {
        UserDefaults.standard.bool(forKey: "typewriterSoundMuted")
    }
}

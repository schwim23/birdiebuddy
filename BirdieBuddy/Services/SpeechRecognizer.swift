import Foundation
import Speech
import AVFoundation
import Observation

enum SpeechRecognizerState {
    case idle
    case listening
    case unavailable
}

/// Wraps SFSpeechRecognizer for three modes:
///   • Score entry   — `startListening(par:onScore:)` — fires callback on first valid score, then stops.
///   • Free text     — `startListeningForText()` — streams `lastHeardText` until `stopListening()` is called.
///   • Multi-score   — `startListeningForMultiScore(players:par:onScores:)` — streams until silence, then
///                     parses all player scores from the full utterance and fires callback.
///
/// All @Observable property mutations are dispatched to the main actor.
/// Audio engine and AVAudioSession work happens on the calling thread (always main in practice).
@Observable
final class SpeechRecognizer {
    private(set) var state: SpeechRecognizerState = .idle
    var lastHeardText: String = ""

    // MARK: - Private state

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var silenceTimer: Timer?

    /// Seconds of inactivity before the listening session auto-cancels.
    private static let scoreTimeout:      TimeInterval = 10
    private static let textTimeout:       TimeInterval = 20
    private static let multiScoreTimeout: TimeInterval = 15

    // MARK: - Permissions

    func requestPermissions() async -> Bool {
        let speechStatus = await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { cont.resume(returning: $0) }
        }
        guard speechStatus == .authorized else {
            await MainActor.run { state = .unavailable }
            return false
        }
        let micGranted = await AVAudioApplication.requestRecordPermission()
        if !micGranted { await MainActor.run { state = .unavailable } }
        return micGranted
    }

    var isAvailable: Bool {
        state != .unavailable && (recognizer?.isAvailable ?? false)
    }

    // MARK: - Listening

    /// Listens for a valid golf score. Stops automatically when a score is parsed or
    /// after `scoreTimeout` seconds of silence. Calls `onScore` on the main actor.
    func startListening(par: Int, onScore: @escaping @MainActor (Int) -> Void) {
        guard isAvailable, state == .idle else { return }
        do {
            try beginScoreSession(par: par, onScore: onScore)
            state = .listening
        } catch {
            state = .idle
        }
    }

    /// Listens for all players' scores in a single utterance.
    /// Resets the silence timer on each partial result. When silence is detected,
    /// parses the full utterance via `MultiScoreParser` and fires `onScores` on the main actor.
    func startListeningForMultiScore(players: [Player], par: Int,
                                     onScores: @escaping @MainActor ([MultiScoreParser.ParsedScore]) -> Void) {
        guard isAvailable, state == .idle else { return }
        do {
            try beginMultiScoreSession(players: players, par: par, onScores: onScores)
            state = .listening
        } catch {
            state = .idle
        }
    }

    /// Listens continuously, streaming transcription into `lastHeardText`.
    /// Stops automatically after `textTimeout` seconds of silence, or when the
    /// caller invokes `stopListening()`.
    func startListeningForText() {
        guard isAvailable, state == .idle else { return }
        do {
            try beginTextSession()
            state = .listening
        } catch {
            state = .idle
        }
    }

    func stopListening() {
        silenceTimer?.invalidate()
        silenceTimer = nil
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        if state == .listening { state = .idle }
    }

    // MARK: - Private: audio engine setup

    private func makeRequest(contextual: [String]) throws -> SFSpeechAudioBufferRecognitionRequest {
        recognitionTask?.cancel()
        recognitionTask = nil

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.contextualStrings = contextual

        // Prefer on-device recognition (lower latency, no network dependency).
        // Falls back to server if the device doesn't support it.
        if #available(iOS 13, *) {
            request.requiresOnDeviceRecognition = recognizer?.supportsOnDeviceRecognition ?? false
        }

        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: format) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        audioEngine.prepare()
        try audioEngine.start()
        return request
    }

    // MARK: - Private: score session

    private func beginScoreSession(par: Int, onScore: @escaping @MainActor (Int) -> Void) throws {
        let request = try makeRequest(contextual: ScoreParser.contextualStrings)

        scheduleTimeout(Self.scoreTimeout)

        recognitionTask = recognizer?.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }

            if let result {
                let text = result.bestTranscription.formattedString
                DispatchQueue.main.async { self.lastHeardText = text }

                if let score = ScoreParser.parse(text, par: par) {
                    self.stopListening()
                    Task { await MainActor.run { onScore(score) } }
                    return
                }
            }

            if error != nil || result?.isFinal == true {
                DispatchQueue.main.async { self.stopListening() }
            }
        }
    }

    // MARK: - Private: multi-score session

    private func beginMultiScoreSession(players: [Player], par: Int,
                                        onScores: @escaping @MainActor ([MultiScoreParser.ParsedScore]) -> Void) throws {
        let playerHints = players.compactMap { $0.name.components(separatedBy: " ").first?.lowercased() }
        let request = try makeRequest(contextual: ScoreParser.contextualStrings + playerHints)

        scheduleMultiScoreTimeout(players: players, par: par, onScores: onScores)

        recognitionTask = recognizer?.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }

            if let result {
                let text = result.bestTranscription.formattedString
                DispatchQueue.main.async {
                    self.lastHeardText = text
                    // Reset timeout on each partial — user may still be speaking
                    self.scheduleMultiScoreTimeout(players: players, par: par, onScores: onScores)
                }
            }

            if let error = error as NSError?, error.code != 203 {
                DispatchQueue.main.async { self.stopListening() }
            }
        }
    }

    // MARK: - Private: free-text session

    private func beginTextSession() throws {
        let request = try makeRequest(contextual: [])

        scheduleTimeout(Self.textTimeout)

        recognitionTask = recognizer?.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }

            if let result {
                let text = result.bestTranscription.formattedString
                DispatchQueue.main.async {
                    self.lastHeardText = text
                    // Reset timeout on each new partial result (user is still speaking)
                    self.scheduleTimeout(Self.textTimeout)
                }
            }

            // For free-text mode, don't auto-stop on isFinal — the user taps to finish.
            // Only stop on hard error.
            if let error = error as NSError?, error.code != 203 {
                // code 203 = recognition cancelled, which we trigger ourselves
                DispatchQueue.main.async { self.stopListening() }
            }
        }
    }

    // MARK: - Silence timeout

    private func scheduleTimeout(_ interval: TimeInterval) {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            self?.stopListening()
        }
    }

    private func scheduleMultiScoreTimeout(players: [Player], par: Int,
                                           onScores: @escaping @MainActor ([MultiScoreParser.ParsedScore]) -> Void) {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: Self.multiScoreTimeout, repeats: false) { [weak self] _ in
            guard let self else { return }
            let text = self.lastHeardText
            self.stopListening()
            let scores = MultiScoreParser.parse(text, players: players, par: par)
            guard !scores.isEmpty else { return }
            Task { await MainActor.run { onScores(scores) } }
        }
    }
}

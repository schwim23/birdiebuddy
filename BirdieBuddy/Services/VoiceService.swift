
import Foundation
import Speech
import AVFoundation

@MainActor
@Observable
final class VoiceService {
    var isListening: Bool = false
    var transcript: String = ""
    var parsedIntent: VoiceIntent?
    var errorMessage: String?
    var audioLevel: Float = 0.0

    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine: AVAudioEngine?

    init() { speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")) }

    func requestPermissions() async -> Bool {
        let speech = await withCheckedContinuation { c in
            SFSpeechRecognizer.requestAuthorization { s in c.resume(returning: s == .authorized) }
        }
        let audio = await AVAudioApplication.requestRecordPermission()
        return speech && audio
    }

    func startListening(players: [RoundPlayer], currentHole: Int, holePar: Int) {
        guard let sr = speechRecognizer, sr.isAvailable else {
            errorMessage = "Speech recognition not available"; return
        }
        stopListening()

        let engine = AVAudioEngine()
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true

        do {
            try AVAudioSession.sharedInstance().setCategory(.record, mode: .measurement, options: .duckOthers)
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "Audio session error"; return
        }

        let node = engine.inputNode
        let fmt = node.outputFormat(forBus: 0)
        node.installTap(onBus: 0, bufferSize: 1024, format: fmt) { [weak self] buf, _ in
            request.append(buf)
            if let ch = buf.floatChannelData?[0] {
                let n = Int(buf.frameLength)
                var s: Float = 0
                for i in 0..<n { s += abs(ch[i]) }
                let avg = s / Float(max(n, 1))
                Task { @MainActor in self?.audioLevel = avg * 10 }
            }
        }

        let task = sr.recognitionTask(with: request) { [weak self] result, error in
            if let r = result {
                let text = r.bestTranscription.formattedString
                Task { @MainActor in
                    self?.transcript = text
                    self?.parsedIntent = VoiceIntentParser.parse(text: text, players: players, currentHole: currentHole, holePar: holePar)
                }
            }
            if error != nil || (result?.isFinal ?? false) {
                Task { @MainActor in self?.stopListening() }
            }
        }

        do {
            engine.prepare()
            try engine.start()
            self.audioEngine = engine
            self.recognitionRequest = request
            self.recognitionTask = task
            self.isListening = true
        } catch {
            errorMessage = "Audio engine error"
        }
    }

    func stopListening() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        audioEngine = nil
        isListening = false
        audioLevel = 0
    }

    func reset() { transcript = ""; parsedIntent = nil; errorMessage = nil }
}

struct VoiceIntent: Sendable {
    var playerName: String
    var playerId: UUID?
    var score: Int?
    var holeNumber: Int
    var scoreLabel: String
    var description: String { "\(playerName) → \(scoreLabel) (\(score ?? 0)) → Hole \(holeNumber)" }
}

enum VoiceIntentParser {
    static func parse(text: String, players: [RoundPlayer], currentHole: Int, holePar: Int) -> VoiceIntent? {
        let lower = text.lowercased()
        var matched: RoundPlayer?
        for p in players {
            let first = p.displayName.split(separator: " ").first.map(String.init) ?? ""
            if lower.contains(p.displayName.lowercased()) || (!first.isEmpty && lower.contains(first.lowercased())) {
                matched = p; break
            }
        }
        guard let player = matched else { return nil }

        let terms: [(String, Int)] = [
            ("double eagle", holePar-3), ("albatross", holePar-3), ("eagle", holePar-2),
            ("birdie", holePar-1), ("par", holePar), ("bogey", holePar+1),
            ("double bogey", holePar+2), ("double", holePar+2),
            ("triple bogey", holePar+3), ("triple", holePar+3),
            ("quad", holePar+4), ("ace", 1), ("hole in one", 1),
        ]
        var score: Int?; var label = ""
        for (t, v) in terms {
            if lower.contains(t) { score = v; label = t.capitalized; break }
        }
        if score == nil {
            let nums: [String: Int] = ["one":1,"two":2,"three":3,"four":4,"five":5,"six":6,"seven":7,"eight":8,"nine":9,"ten":10]
            for w in lower.split(separator: " ") {
                if let n = Int(w), (1...15).contains(n) { score = n; label = "\(n)"; break }
                if let n = nums[String(w)] { score = n; label = "\(n)"; break }
            }
        }
        guard score != nil else { return nil }
        return VoiceIntent(playerName: player.displayName, playerId: player.playerId, score: score, holeNumber: currentHole, scoreLabel: label)
    }
}

import Foundation
import Speech
import AVFoundation
import Observation

enum SpeechRecognizerState {
    case idle
    case listening
    case unavailable
}

@Observable
final class SpeechRecognizer {
    private(set) var state: SpeechRecognizerState = .idle
    var lastHeardText: String = ""

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    // MARK: — Permissions

    /// Returns true if both speech recognition and microphone are authorized.
    func requestPermissions() async -> Bool {
        let speechStatus = await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { cont.resume(returning: $0) }
        }
        guard speechStatus == .authorized else {
            state = .unavailable
            return false
        }
        let micGranted = await AVAudioApplication.requestRecordPermission()
        if !micGranted { state = .unavailable }
        return micGranted
    }

    var isAvailable: Bool {
        state != .unavailable && (recognizer?.isAvailable ?? false)
    }

    // MARK: — Listening

    func startListening(par: Int, onScore: @escaping (Int) -> Void) {
        guard isAvailable, state == .idle else { return }
        do {
            try beginSession(par: par, onScore: onScore)
            state = .listening
        } catch {
            state = .idle
        }
    }

    /// Listen continuously, updating lastHeardText, until stopListening() is called.
    /// Use for free-form voice input (e.g. player setup) where the caller decides when to stop.
    func startListeningForText() {
        guard isAvailable, state == .idle else { return }
        do {
            try beginSessionForText()
            state = .listening
        } catch {
            state = .idle
        }
    }

    func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        if state == .listening { state = .idle }
    }

    // MARK: — Private

    private func setupAudioEngine() throws -> SFSpeechAudioBufferRecognitionRequest {
        recognitionTask?.cancel()
        recognitionTask = nil

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()
        return request
    }

    private func beginSessionForText() throws {
        let request = try setupAudioEngine()
        recognitionTask = recognizer?.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            if let result {
                self.lastHeardText = result.bestTranscription.formattedString
            }
            if error != nil || result?.isFinal == true {
                self.stopListening()
            }
        }
    }

    private func beginSession(par: Int, onScore: @escaping (Int) -> Void) throws {
        let request = try setupAudioEngine()
        recognitionTask = recognizer?.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }

            if let result {
                let text = result.bestTranscription.formattedString
                self.lastHeardText = text

                if let score = ScoreParser.parse(text, par: par) {
                    self.stopListening()
                    onScore(score)
                }
            }

            if error != nil || result?.isFinal == true {
                self.stopListening()
            }
        }
    }
}

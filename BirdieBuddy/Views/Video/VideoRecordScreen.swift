
import SwiftUI
import AVFoundation
import SwiftData

struct VideoRecordScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let round: GolfRound
    let currentHole: Int
    @State private var isRecording = false
    @State private var selectedPlayer: RoundPlayer?
    @State private var taggedHole: Int
    @State private var recordingDuration: TimeInterval = 0
    @State private var timer: Timer?

    init(round: GolfRound, currentHole: Int) {
        self.round = round
        self.currentHole = currentHole
        _taggedHole = State(initialValue: currentHole)
    }

    var body: some View {
        ZStack {
            // Camera placeholder
            Color.black.ignoresSafeArea()

            VStack {
                // Top bar - hole and player tags
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(round.course?.name ?? "Course")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                        HStack(spacing: 8) {
                            Picker("Hole", selection: $taggedHole) {
                                ForEach(1...round.holeCount, id: \.self) { h in
                                    Text("Hole \(h)").tag(h)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(.white)
                        }
                    }
                    Spacer()
                    if isRecording {
                        HStack(spacing: 4) {
                            Circle().fill(.red).frame(width: 8, height: 8)
                            Text(formattedDuration)
                                .font(.caption.monospaced())
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.red.opacity(0.3))
                        .clipShape(Capsule())
                    }
                }
                .padding()
                .background(.black.opacity(0.5))

                Spacer()

                // Camera preview placeholder
                VStack(spacing: 12) {
                    Image(systemName: "video.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.white.opacity(0.5))
                    Text("Camera Preview")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.5))
                    Text("Camera access required for recording")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.3))
                }

                Spacer()

                // Player picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(round.players) { player in
                            Button {
                                selectedPlayer = player
                            } label: {
                                Text(player.displayName)
                                    .font(.caption.bold())
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedPlayer?.id == player.id ? Theme.primaryGreen : .white.opacity(0.2))
                                    .foregroundStyle(.white)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // Record button
                HStack(spacing: 40) {
                    Button { dismiss() } label: {
                        Text("Cancel")
                            .font(.subheadline)
                            .foregroundStyle(.white)
                    }

                    Button {
                        if isRecording {
                            stopRecording()
                        } else {
                            startRecording()
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .stroke(.white, lineWidth: 4)
                                .frame(width: 70, height: 70)
                            if isRecording {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(.red)
                                    .frame(width: 28, height: 28)
                            } else {
                                Circle()
                                    .fill(.red)
                                    .frame(width: 56, height: 56)
                            }
                        }
                    }

                    Button {
                        // Placeholder: flip camera
                    } label: {
                        Image(systemName: "camera.rotate")
                            .font(.title2)
                            .foregroundStyle(.white)
                    }
                }
                .padding(.bottom, 30)
            }
        }
        .navigationBarHidden(true)
    }

    private var formattedDuration: String {
        let mins = Int(recordingDuration) / 60
        let secs = Int(recordingDuration) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    private func startRecording() {
        isRecording = true
        recordingDuration = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            recordingDuration += 1
        }
    }

    private func stopRecording() {
        isRecording = false
        timer?.invalidate()
        timer = nil

        // Save video metadata
        let video = ShotVideo(
            videoURL: URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(UUID().uuidString).mov"),
            playerId: selectedPlayer?.playerId ?? UUID(),
            courseId: round.course?.id,
            holeNumber: taggedHole,
            playerName: selectedPlayer?.displayName ?? "Unknown"
        )
        video.round = round
        round.videos.append(video)
        modelContext.insert(video)
        try? modelContext.save()

        dismiss()
    }
}

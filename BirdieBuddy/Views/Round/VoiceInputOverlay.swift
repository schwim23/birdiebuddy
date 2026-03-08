
import SwiftUI
import SwiftData

struct VoiceInputOverlay: View {
    let vm: ScorecardViewModel
    @Bindable var voiceService: VoiceService
    let modelContext: ModelContext
    @Environment(\.dismiss) private var dismiss
    @State private var permissionGranted = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 24) {
                Spacer()

                Text("Voice Score Entry").font(.title2.bold()).foregroundStyle(Theme.textPrimary)
                Text("Hole \(vm.currentHole) • Par \(vm.currentHolePar)").font(.subheadline).foregroundStyle(Theme.textSecondary)

                // Waveform
                HStack(spacing: 3) {
                    ForEach(0..<20, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Theme.primaryGreen)
                            .frame(width: 4, height: CGFloat.random(in: 5...max(5, CGFloat(voiceService.audioLevel) * 8 + 5)))
                            .animation(.easeInOut(duration: 0.1), value: voiceService.audioLevel)
                    }
                }.frame(height: 60)

                // Transcript
                Text(voiceService.transcript.isEmpty ? "Listening..." : voiceService.transcript)
                    .font(.body).foregroundStyle(Theme.textPrimary)
                    .padding().frame(maxWidth: .infinity, minHeight: 60)
                    .background(Theme.cardBackground).clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
                    .padding(.horizontal)

                // Parsed intent
                if let intent = voiceService.parsedIntent {
                    VStack(spacing: 8) {
                        Text("Understood:").font(.caption).foregroundStyle(Theme.textSecondary)
                        Text(intent.description).font(.headline).foregroundStyle(Theme.primaryGreen)
                    }
                    .padding().background(Theme.lightGreen).clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
                    .padding(.horizontal)

                    HStack(spacing: 16) {
                        Button {
                            vm.applyVoiceIntent(intent, modelContext: modelContext)
                            voiceService.stopListening(); voiceService.reset(); dismiss()
                        } label: { Label("Confirm", systemImage: "checkmark").primaryButtonStyle() }

                        Button {
                            voiceService.reset()
                            voiceService.startListening(players: vm.round.players, currentHole: vm.currentHole, holePar: vm.currentHolePar)
                        } label: { Label("Retry", systemImage: "arrow.counterclockwise").secondaryButtonStyle() }
                    }.padding(.horizontal)
                }

                Spacer()

                // Mic button
                Button {
                    if voiceService.isListening { voiceService.stopListening() }
                    else {
                        voiceService.reset()
                        voiceService.startListening(players: vm.round.players, currentHole: vm.currentHole, holePar: vm.currentHolePar)
                    }
                } label: {
                    Image(systemName: voiceService.isListening ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.system(size: 70))
                        .foregroundStyle(voiceService.isListening ? Theme.destructive : Theme.primaryGreen)
                }

                Button("Cancel") { voiceService.stopListening(); dismiss() }
                    .foregroundStyle(Theme.textSecondary).padding(.bottom, 20)

                if let err = voiceService.errorMessage {
                    Text(err).font(.caption).foregroundStyle(Theme.destructive)
                }
            }
        }
        .task {
            permissionGranted = await voiceService.requestPermissions()
            if permissionGranted {
                voiceService.startListening(players: vm.round.players, currentHole: vm.currentHole, holePar: vm.currentHolePar)
            }
        }
        .onDisappear { voiceService.stopListening() }
    }
}

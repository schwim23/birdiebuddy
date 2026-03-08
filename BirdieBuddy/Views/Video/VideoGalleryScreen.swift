
import SwiftUI
import SwiftData

struct VideoGalleryScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ShotVideo.recordedAt, order: .reverse) private var videos: [ShotVideo]
    @State private var filterHole: Int?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                if videos.isEmpty {
                    EmptyStateView(icon: "video.fill", message: "No shot videos yet.\nRecord videos during a round to see them here!")
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Filter
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    FilterChip(label: "All", isSelected: filterHole == nil) {
                                        filterHole = nil
                                    }
                                    ForEach(uniqueHoles, id: \.self) { hole in
                                        FilterChip(label: "Hole \(hole)", isSelected: filterHole == hole) {
                                            filterHole = hole
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }

                            // Grid
                            let filtered = filteredVideos
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(filtered) { video in
                                    VideoThumbnailCard(video: video)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Shot Videos")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var uniqueHoles: [Int] {
        Array(Set(videos.compactMap { $0.holeNumber })).sorted()
    }

    private var filteredVideos: [ShotVideo] {
        guard let hole = filterHole else { return videos }
        return videos.filter { $0.holeNumber == hole }
    }
}

private struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Theme.primaryGreen : Theme.cardBackground)
                .foregroundStyle(isSelected ? .white : Theme.textPrimary)
                .clipShape(Capsule())
                .overlay {
                    Capsule().stroke(isSelected ? Theme.primaryGreen : .gray.opacity(0.2))
                }
        }
    }
}

private struct VideoThumbnailCard: View {
    let video: ShotVideo

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Thumbnail placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Theme.darkGreen.opacity(0.3))
                    .aspectRatio(16/9, contentMode: .fit)
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.white.opacity(0.8))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(video.playerName)
                    .font(.caption.bold())
                    .foregroundStyle(Theme.textPrimary)
                HStack(spacing: 4) {
                    if let hole = video.holeNumber {
                        Text("Hole \(hole)")
                            .font(.caption2)
                            .foregroundStyle(Theme.primaryGreen)
                    }
                    Text(video.recordedAt.shortFormatted)
                        .font(.caption2)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .padding(8)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}

import Combine
import SwiftUI

private struct PlayableSource: Identifiable {
    let label: String
    let url: URL
    var id: String { label }
}

struct MediaDetailView: View {
    let item: MediaItem
    @StateObject private var vm: DetailViewModel
    @EnvironmentObject private var library: LibraryStore
    @State private var playerSource: PlayableSource?
    @State private var selectedSeason: TVSeason?
    @State private var selectedEpisode: TVEpisode?
    @State private var scrollToSavedEpisode = false

    init(item: MediaItem) {
        self.item = item
        _vm = StateObject(wrappedValue: DetailViewModel(item: item))
    }

    var mediaType: String { item.resolvedMediaType }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                    AsyncImage(url: item.backdropURL) { img in
                        img.resizable().scaledToFill()
                    } placeholder: { Color.gray.opacity(0.2) }
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.displayTitle).font(.title2.bold()).foregroundColor(.white)
                        HStack {
                            Text(String(item.displayDate.prefix(4))).foregroundColor(.gray)
                            Text("⭐ \(String(format: "%.1f", item.voteAverage))").foregroundColor(.yellow)
                        }.font(.subheadline)
                        Text(item.overview).foregroundColor(.gray).font(.body)
                        if mediaType == "tv", let place = library.place(for: item) {
                            Text("Last watched \(place.label)")
                                .font(.subheadline)
                                .foregroundColor(.purple)
                        }
                    }.padding(.horizontal)

                    Button(action: { library.toggle(item) }) {
                        Label(
                            library.contains(item) ? "In Library" : "Add to Library",
                            systemImage: library.contains(item) ? "bookmark.fill" : "bookmark"
                        )
                        .font(.subheadline.bold())
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.12))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Stream Source").font(.headline).foregroundColor(.white).padding(.horizontal)
                        if sources.isEmpty {
                            Text(mediaType == "tv"
                                 ? "Choose an episode to start playback."
                                 : "No stream sources available.")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                        } else {
                            sourceButtons
                        }
                    }

                    if mediaType == "tv" {
                        if let details = vm.tvDetails {
                            TVSeasonPicker(
                                details: details,
                                resumeSeason: library.place(for: item)?.seasonNumber,
                                resumeEpisode: library.place(for: item)?.episodeNumber,
                                selectedSeason: $selectedSeason,
                                selectedEpisode: $selectedEpisode
                            )
                        } else if vm.isLoading {
                            ProgressView()
                                .tint(.white)
                                .padding(.horizontal)
                        } else if let message = vm.errorMessage {
                            Text(message)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                        }
                    }
                }
                .padding(.bottom, 40)
                }
                .onChange(of: selectedEpisode?.id) { _, episodeID in
                    guard scrollToSavedEpisode, let episodeID else { return }
                    scrollToSavedEpisode = false
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 150_000_000)
                        withAnimation { proxy.scrollTo(episodeID, anchor: .center) }
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            scrollToSavedEpisode = library.place(for: item) != nil
            await vm.load()
        }
        .fullScreenCover(item: $playerSource) { source in
            PlayerView(url: source.url)
        }
    }

    private var sourceButtons: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(sources) { src in
                    Button(action: {
                        rememberPlace()
                        playerSource = src
                    }) {
                        Text(src.label)
                            .font(.subheadline.bold())
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            }.padding(.horizontal)
        }
    }

    private var sources: [PlayableSource] {
        let season = selectedSeason?.seasonNumber
        let episode = selectedEpisode?.episodeNumber
        let candidates: [(String, URL?)] = [
            ("VidSrc", StreamSources.vidsrc(mediaType: mediaType, id: item.id, season: season, episode: episode)),
            ("Videasy", StreamSources.videasy(mediaType: mediaType, id: item.id, season: season, episode: episode)),
            ("Vidking", StreamSources.vidking(mediaType: mediaType, id: item.id, season: season, episode: episode))
        ]
        return candidates.compactMap { label, url in
            url.map { PlayableSource(label: label, url: $0) }
        }
    }

    private func rememberPlace() {
        guard mediaType == "tv",
              let season = selectedSeason?.seasonNumber,
              let episode = selectedEpisode else { return }
        library.rememberPlace(
            item: item,
            season: season,
            episode: episode.episodeNumber,
            episodeName: episode.name
        )
    }
}

@MainActor
class DetailViewModel: ObservableObject {
    @Published var tvDetails: TVDetails?
    @Published var isLoading = false
    @Published var errorMessage: String?
    let item: MediaItem
    private var loadID = 0

    init(item: MediaItem) { self.item = item }

    func load() async {
        guard item.resolvedMediaType == "tv" else { return }
        loadID += 1
        let token = loadID
        isLoading = true
        errorMessage = nil
        defer {
            if token == loadID { isLoading = false }
        }
        do {
            let details = try await TMDBService.shared.tvDetails(id: item.id)
            guard !Task.isCancelled else { return }
            tvDetails = details
        } catch {
            guard !Task.isCancelled else { return }
            errorMessage = error.localizedDescription
        }
    }
}

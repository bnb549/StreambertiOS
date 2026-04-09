import SwiftUI

struct MediaDetailView: View {
    let item: MediaItem
    @StateObject private var vm: DetailViewModel
    @State private var showPlayer = false
    @State private var selectedSource: URL?
    @State private var selectedSeason: TVSeason?
    @State private var selectedEpisode: TVEpisode?

    init(item: MediaItem) {
        self.item = item
        _vm = StateObject(wrappedValue: DetailViewModel(item: item))
    }

    var mediaType: String { item.mediaType ?? (item.title != nil ? "movie" : "tv") }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Backdrop
                    AsyncImage(url: item.backdropURL) { img in
                        img.resizable().scaledToFill()
                    } placeholder: { Color.gray.opacity(0.2) }
                    .frame(height: 220)
                    .clipped()
                    .cornerRadius(12)

                    // Title & Info
                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.displayTitle).font(.title2.bold()).foregroundColor(.white)
                        HStack {
                            Text(String(item.displayDate.prefix(4))).foregroundColor(.gray)
                            Text("⭐ \(String(format: "%.1f", item.voteAverage))").foregroundColor(.yellow)
                        }.font(.subheadline)
                        Text(item.overview).foregroundColor(.gray).font(.body)
                    }.padding(.horizontal)

                    // Stream Source Buttons
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Stream Source").font(.headline).foregroundColor(.white).padding(.horizontal)
                        sourceButtons
                    }

                    // TV Season/Episode picker
                    if mediaType == "tv", let details = vm.tvDetails {
                        TVSeasonPicker(
                            details: details,
                            selectedSeason: $selectedSeason,
                            selectedEpisode: $selectedEpisode
                        )
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.load() }
        .sheet(isPresented: $showPlayer) {
            if let url = selectedSource {
                PlayerView(url: url)
            }
        }
    }

    private var sourceButtons: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(sources, id: \.label) { src in
                    Button(action: {
                        selectedSource = src.url
                        showPlayer = true
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

    private var sources: [(label: String, url: URL)] {
        let s = selectedSeason?.seasonNumber
        let e = selectedEpisode?.episodeNumber
        return [
            ("VidSrc",    StreamSources.vidsrc(mediaType: mediaType, id: item.id, season: s, episode: e)),
            ("Videasy",   StreamSources.videasy(mediaType: mediaType, id: item.id, season: s, episode: e)),
            ("2Embed",    StreamSources.twoEmbed(mediaType: mediaType, id: item.id, season: s, episode: e))
        ]
    }
}

@MainActor
class DetailViewModel: ObservableObject {
    @Published var tvDetails: TVDetails?
    let item: MediaItem

    init(item: MediaItem) { self.item = item }

    func load() async {
        let mediaType = item.mediaType ?? (item.title != nil ? "movie" : "tv")
        if mediaType == "tv" {
            tvDetails = try? await TMDBService.shared.tvDetails(id: item.id)
        }
    }
}

import SwiftUI

struct TVSeasonPicker: View {
    let details: TVDetails
    @Binding var selectedSeason: TVSeason?
    @Binding var selectedEpisode: TVEpisode?
    @StateObject private var vm = SeasonViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Episodes").font(.headline).foregroundColor(.white).padding(.horizontal)

            // Season picker
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(details.seasons.filter { $0.seasonNumber > 0 }) { season in
                        Button(action: {
                            selectedSeason = season
                            Task { await vm.loadEpisodes(tvID: details.id, season: season.seasonNumber) }
                        }) {
                            Text(season.name)
                                .font(.caption.bold())
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(selectedSeason?.id == season.id ? Color.purple : Color.gray.opacity(0.3))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                }.padding(.horizontal)
            }

            // Episode list
            if !vm.episodes.isEmpty {
                ForEach(vm.episodes) { episode in
                    Button(action: { selectedEpisode = episode }) {
                        HStack(spacing: 12) {
                            AsyncImage(url: episode.stillURL) { img in
                                img.resizable().scaledToFill()
                            } placeholder: { Color.gray.opacity(0.3) }
                            .frame(width: 100, height: 60)
                            .cornerRadius(8)
                            .clipped()

                            VStack(alignment: .leading, spacing: 4) {
                                Text("E\(episode.episodeNumber): \(episode.name)")
                                    .font(.subheadline.bold())
                                    .foregroundColor(selectedEpisode?.id == episode.id ? .purple : .white)
                                Text(episode.overview)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .lineLimit(2)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
    }
}

@MainActor
class SeasonViewModel: ObservableObject {
    @Published var episodes: [TVEpisode] = []

    func loadEpisodes(tvID: Int, season: Int) async {
        episodes = (try? await TMDBService.shared.seasonEpisodes(tvID: tvID, season: season)) ?? []
    }
}

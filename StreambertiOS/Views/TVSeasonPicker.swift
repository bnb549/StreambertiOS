import Combine
import SwiftUI

struct TVSeasonPicker: View {
    let details: TVDetails
    var resumeSeason: Int?
    var resumeEpisode: Int?
    @Binding var selectedSeason: TVSeason?
    @Binding var selectedEpisode: TVEpisode?
    @StateObject private var vm = SeasonViewModel()

    private var seasons: [TVSeason] {
        let regular = details.seasons
            .filter { $0.seasonNumber > 0 }
            .sorted { $0.seasonNumber < $1.seasonNumber }
        if !regular.isEmpty { return regular }
        return details.seasons.sorted { $0.seasonNumber < $1.seasonNumber }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Episodes").font(.headline).foregroundColor(.white).padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(seasons) { season in
                        Button(action: { Task { await select(season) } }) {
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

            if vm.isLoading && vm.episodes.isEmpty {
                ProgressView()
                    .tint(.white)
                    .padding(.horizontal)
            } else if let message = vm.errorMessage, vm.episodes.isEmpty {
                Text(message)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
            } else {
                ForEach(vm.episodes) { episode in
                    Button(action: { selectedEpisode = episode }) {
                        HStack(spacing: 12) {
                            AsyncImage(url: episode.stillURL) { img in
                                img.resizable().scaledToFill()
                            } placeholder: { Color.gray.opacity(0.3) }
                            .frame(width: 100, height: 60)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                            VStack(alignment: .leading, spacing: 4) {
                                Text("E\(episode.episodeNumber): \(episode.name)")
                                    .font(.subheadline.bold())
                                    .foregroundColor(selectedEpisode?.id == episode.id ? .purple : .white)
                                    .multilineTextAlignment(.leading)
                                Text(episode.overview)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .id(episode.id)
                }
            }
        }
        .task(id: details.id) {
            guard selectedSeason == nil else { return }
            let match = seasons.first { $0.seasonNumber == resumeSeason }
            guard let season = match ?? seasons.first else { return }
            let preferred = match == nil ? nil : resumeEpisode
            await select(season, preferredEpisode: preferred)
        }
    }

    private func select(_ season: TVSeason, preferredEpisode: Int? = nil) async {
        selectedSeason = season
        selectedEpisode = nil
        let episodes = await vm.loadEpisodes(tvID: details.id, season: season.seasonNumber)
        guard selectedSeason?.id == season.id, !episodes.isEmpty else { return }
        if let preferredEpisode, let saved = episodes.first(where: { $0.episodeNumber == preferredEpisode }) {
            selectedEpisode = saved
        } else {
            selectedEpisode = episodes.first
        }
    }
}

@MainActor
class SeasonViewModel: ObservableObject {
    @Published var episodes: [TVEpisode] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    private var requestID = 0

    func loadEpisodes(tvID: Int, season: Int) async -> [TVEpisode] {
        requestID += 1
        let token = requestID
        isLoading = true
        errorMessage = nil
        defer {
            if token == requestID { isLoading = false }
        }

        do {
            let loaded = try await TMDBService.shared.seasonEpisodes(tvID: tvID, season: season)
            guard token == requestID else { return [] }
            episodes = loaded
            return loaded
        } catch {
            guard token == requestID else { return [] }
            episodes = []
            errorMessage = error.localizedDescription
            return []
        }
    }
}

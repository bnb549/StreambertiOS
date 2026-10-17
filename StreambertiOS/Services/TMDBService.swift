import Foundation

enum TMDBError: LocalizedError {
    case missingAPIKey
    case unauthorized
    case requestFailed

    var errorDescription: String? {
        switch self {
        case .missingAPIKey, .unauthorized:
            return "TMDB rejected the token. Paste the API Read Access Token (the long value that starts with eyJ) in Settings."
        case .requestFailed:
            return "Couldn't reach TMDB. Check your connection and try again."
        }
    }
}

final class TMDBService {
    static let shared = TMDBService()
    private let base = "https://api.themoviedb.org/3"

    private var apiKey: String {
        UserDefaults.standard.string(forKey: "tmdb_key") ?? ""
    }

    func fetchTrending(mediaType: String = "all", timeWindow: String = "day") async throws -> [MediaItem] {
        guard let url = URL(string: "\(base)/trending/\(mediaType)/\(timeWindow)") else {
            throw TMDBError.requestFailed
        }
        return try await get(url: url)
    }

    func search(query: String) async throws -> [MediaItem] {
        var comps = URLComponents(string: "\(base)/search/multi")
        comps?.queryItems = [URLQueryItem(name: "query", value: query)]
        guard let url = comps?.url else { throw TMDBError.requestFailed }
        return try await get(url: url)
    }

    func movieDetails(id: Int) async throws -> MediaItem {
        guard let url = URL(string: "\(base)/movie/\(id)") else { throw TMDBError.requestFailed }
        let data = try await authorizedRequest(url: url)
        let dto = try JSONDecoder().decode(MediaDTO.self, from: data)
        guard let item = makeItem(from: dto) else { throw TMDBError.requestFailed }
        return item
    }

    func tvDetails(id: Int) async throws -> TVDetails {
        guard let url = URL(string: "\(base)/tv/\(id)") else { throw TMDBError.requestFailed }
        let data = try await authorizedRequest(url: url)
        let dto = try JSONDecoder().decode(TVDetailsDTO.self, from: data)
        return makeDetails(from: dto)
    }

    func seasonEpisodes(tvID: Int, season: Int) async throws -> [TVEpisode] {
        guard let url = URL(string: "\(base)/tv/\(tvID)/season/\(season)") else { throw TMDBError.requestFailed }
        let data = try await authorizedRequest(url: url)
        let dto = try JSONDecoder().decode(SeasonEpisodesDTO.self, from: data)
        return dto.episodes.map(makeEpisode(from:))
    }

    private func get(url: URL) async throws -> [MediaItem] {
        let data = try await authorizedRequest(url: url)
        let decoded = try JSONDecoder().decode(ResultsDTO.self, from: data)
        return unique(decoded.results.compactMap(makeItem(from:)))
    }

    private func unique(_ items: [MediaItem]) -> [MediaItem] {
        var seen = Set<String>()
        return items.filter { seen.insert($0.rowID).inserted }
    }

    /// Setup asks for the v4 Read Access Token. That token only works as a Bearer
    /// header. A short v3 key still works as an `api_key` query item.
    private func authorizedRequest(url: URL) async throws -> Data {
        let token = normalizedToken(apiKey)
        guard !token.isEmpty else { throw TMDBError.missingAPIKey }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if isReadAccessToken(token) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            guard var comps = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                throw TMDBError.requestFailed
            }
            var items = comps.queryItems ?? []
            items.append(URLQueryItem(name: "api_key", value: token))
            comps.queryItems = items
            guard let authed = comps.url else { throw TMDBError.requestFailed }
            request.url = authed
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw TMDBError.requestFailed }
        switch http.statusCode {
        case 200...299:
            return data
        case 401, 403:
            throw TMDBError.unauthorized
        default:
            throw TMDBError.requestFailed
        }
    }

    private func normalizedToken(_ raw: String) -> String {
        var token = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let bearer = "bearer "
        if token.lowercased().hasPrefix(bearer) {
            token = String(token.dropFirst(bearer.count)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return token
    }

    private func isReadAccessToken(_ token: String) -> Bool {
        token.split(separator: ".").count == 3
    }

    private func makeItem(from dto: MediaDTO) -> MediaItem? {
        let type: String
        if let mediaType = dto.mediaType {
            guard mediaType == "movie" || mediaType == "tv" else { return nil }
            type = mediaType
        } else if dto.title != nil {
            type = "movie"
        } else if dto.name != nil {
            type = "tv"
        } else {
            return nil
        }

        return MediaItem(
            id: dto.id,
            title: dto.title,
            name: dto.name,
            overview: dto.overview ?? "",
            posterPath: dto.posterPath,
            backdropPath: dto.backdropPath,
            releaseDate: dto.releaseDate,
            firstAirDate: dto.firstAirDate,
            voteAverage: dto.voteAverage ?? 0,
            mediaType: type
        )
    }

    private func makeDetails(from dto: TVDetailsDTO) -> TVDetails {
        let seasons = dto.seasons.map { season in
            TVSeason(
                id: season.id,
                seasonNumber: season.seasonNumber,
                name: season.name ?? "Season \(season.seasonNumber)",
                episodeCount: season.episodeCount ?? 0
            )
        }
        return TVDetails(id: dto.id, name: dto.name ?? "Unknown", seasons: seasons)
    }

    private func makeEpisode(from dto: EpisodeDTO) -> TVEpisode {
        TVEpisode(
            id: dto.id,
            episodeNumber: dto.episodeNumber,
            name: dto.name ?? "Episode \(dto.episodeNumber)",
            overview: dto.overview ?? "",
            stillPath: dto.stillPath
        )
    }
}

// DTOs stay off the default main-actor isolation so JSONDecoder can decode them.
// Trending "all" and multi-search mix in people, and several string fields are null.

nonisolated private struct OptionalDecode<T: Decodable>: Decodable {
    let value: T?
    init(from decoder: Decoder) throws {
        value = try? T(from: decoder)
    }
}

nonisolated private struct ResultsDTO: Decodable {
    let results: [MediaDTO]

    enum CodingKeys: String, CodingKey { case results }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let wrapped = try container.decodeIfPresent([OptionalDecode<MediaDTO>].self, forKey: .results) ?? []
        results = wrapped.compactMap(\.value)
    }
}

nonisolated private struct MediaDTO: Decodable {
    let id: Int
    let title: String?
    let name: String?
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: String?
    let firstAirDate: String?
    let voteAverage: Double?
    let mediaType: String?

    enum CodingKeys: String, CodingKey {
        case id, title, name, overview
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case releaseDate = "release_date"
        case firstAirDate = "first_air_date"
        case voteAverage = "vote_average"
        case mediaType = "media_type"
    }
}

nonisolated private struct TVDetailsDTO: Decodable {
    let id: Int
    let name: String?
    let seasons: [TVSeasonDTO]

    enum CodingKeys: String, CodingKey { case id, name, seasons }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        let wrapped = try container.decodeIfPresent([OptionalDecode<TVSeasonDTO>].self, forKey: .seasons) ?? []
        seasons = wrapped.compactMap(\.value)
    }
}

nonisolated private struct TVSeasonDTO: Decodable {
    let id: Int
    let seasonNumber: Int
    let name: String?
    let episodeCount: Int?

    enum CodingKeys: String, CodingKey {
        case id, name
        case seasonNumber = "season_number"
        case episodeCount = "episode_count"
    }
}

nonisolated private struct SeasonEpisodesDTO: Decodable {
    let episodes: [EpisodeDTO]

    enum CodingKeys: String, CodingKey { case episodes }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let wrapped = try container.decodeIfPresent([OptionalDecode<EpisodeDTO>].self, forKey: .episodes) ?? []
        episodes = wrapped.compactMap(\.value)
    }
}

nonisolated private struct EpisodeDTO: Decodable {
    let id: Int
    let episodeNumber: Int
    let name: String?
    let overview: String?
    let stillPath: String?

    enum CodingKeys: String, CodingKey {
        case id, name, overview
        case episodeNumber = "episode_number"
        case stillPath = "still_path"
    }
}

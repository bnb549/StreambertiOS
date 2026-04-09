import Foundation

class TMDBService {
    static let shared = TMDBService()
    private let base = "https://api.themoviedb.org/3"

    private var apiKey: String {
        UserDefaults.standard.string(forKey: "tmdb_key") ?? ""
    }

    // MARK: - Trending
    func fetchTrending(mediaType: String = "all", timeWindow: String = "day") async throws -> [MediaItem] {
        let url = URL(string: "\(base)/trending/\(mediaType)/\(timeWindow)")!
        return try await get(url: url)
    }

    // MARK: - Search
    func search(query: String) async throws -> [MediaItem] {
        var comps = URLComponents(string: "\(base)/search/multi")!
        comps.queryItems = [URLQueryItem(name: "query", value: query)]
        return try await get(url: comps.url!)
    }

    // MARK: - Movie Details
    func movieDetails(id: Int) async throws -> MediaItem {
        let url = URL(string: "\(base)/movie/\(id)")!
        return try await getSingle(url: url)
    }

    // MARK: - TV Details
    func tvDetails(id: Int) async throws -> TVDetails {
        let url = URL(string: "\(base)/tv/\(id)")!
        let (data, _) = try await authorizedRequest(url: url)
        return try JSONDecoder().decode(TVDetails.self, from: data)
    }

    func seasonEpisodes(tvID: Int, season: Int) async throws -> [TVEpisode] {
        let url = URL(string: "\(base)/tv/\(tvID)/season/\(season)")!
        let (data, _) = try await authorizedRequest(url: url)
        let resp = try JSONDecoder().decode(SeasonResponse.self, from: data)
        return resp.episodes
    }

    // MARK: - Private helpers
    private func get(url: URL) async throws -> [MediaItem] {
        let (data, _) = try await authorizedRequest(url: url)
        let resp = try JSONDecoder().decode(MediaResponse.self, from: data)
        return resp.results
    }

    private func getSingle(url: URL) async throws -> MediaItem {
        let (data, _) = try await authorizedRequest(url: url)
        return try JSONDecoder().decode(MediaItem.self, from: data)
    }

    private func authorizedRequest(url: URL) async throws -> (Data, URLResponse) {
        var comps = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        var items = comps.queryItems ?? []
        items.append(URLQueryItem(name: "api_key", value: apiKey))
        comps.queryItems = items
        let req = URLRequest(url: comps.url!)
        return try await URLSession.shared.data(for: req)
    }
}

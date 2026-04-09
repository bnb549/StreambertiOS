import Foundation

struct TVSeason: Identifiable, Codable {
    let id: Int
    let seasonNumber: Int
    let name: String
    let episodeCount: Int

    enum CodingKeys: String, CodingKey {
        case id, name
        case seasonNumber = "season_number"
        case episodeCount = "episode_count"
    }
}

struct TVEpisode: Identifiable, Codable {
    let id: Int
    let episodeNumber: Int
    let name: String
    let overview: String
    let stillPath: String?

    enum CodingKeys: String, CodingKey {
        case id, name, overview
        case episodeNumber = "episode_number"
        case stillPath = "still_path"
    }

    var stillURL: URL? {
        guard let path = stillPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w300\(path)")
    }
}

struct SeasonResponse: Codable {
    let episodes: [TVEpisode]
}

struct TVDetails: Codable {
    let id: Int
    let name: String
    let seasons: [TVSeason]
}

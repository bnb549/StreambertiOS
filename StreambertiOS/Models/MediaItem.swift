import Foundation

struct MediaItem: Identifiable, Codable {
    let id: Int
    let title: String?
    let name: String?          // TV shows use 'name'
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: String?
    let firstAirDate: String?
    let voteAverage: Double
    let mediaType: String?     // "movie" or "tv"

    enum CodingKeys: String, CodingKey {
        case id, title, name, overview
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case releaseDate = "release_date"
        case firstAirDate = "first_air_date"
        case voteAverage = "vote_average"
        case mediaType = "media_type"
    }

    var displayTitle: String { title ?? name ?? "Unknown" }
    var displayDate: String  { releaseDate ?? firstAirDate ?? "" }

    /// Movie and TV ids overlap, so lists and the watchlist key off both.
    var resolvedMediaType: String {
        if let mediaType, mediaType == "movie" || mediaType == "tv" {
            return mediaType
        }
        if title != nil { return "movie" }
        if name != nil { return "tv" }
        return "movie"
    }

    var rowID: String { "\(resolvedMediaType)-\(id)" }

    var posterURL: URL? {
        guard let path = posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(path)")
    }
    var backdropURL: URL? {
        guard let path = backdropPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w1280\(path)")
    }
}

struct MediaResponse: Codable {
    let results: [MediaItem]
}

import Foundation

/// Embed URLs for the sources the Streambert desktop app uses.
/// A TV title needs a season and episode. Returning a movie URL for a show
/// sends the player to the wrong title.
struct StreamSources {

    static func vidsrc(mediaType: String, id: Int, season: Int? = nil, episode: Int? = nil) -> URL? {
        if mediaType == "tv" {
            guard let season, let episode else { return nil }
            return URL(string: "https://vsembed.su/embed/tv/\(id)/\(season)/\(episode)")
        }
        return URL(string: "https://vsembed.su/embed/movie/\(id)")
    }

    static func videasy(mediaType: String, id: Int, season: Int? = nil, episode: Int? = nil) -> URL? {
        if mediaType == "tv" {
            guard let season, let episode else { return nil }
            return URL(string: "https://player.videasy.to/tv/\(id)/\(season)/\(episode)?overlay=true")
        }
        return URL(string: "https://player.videasy.to/movie/\(id)?overlay=true")
    }

    static func vidking(mediaType: String, id: Int, season: Int? = nil, episode: Int? = nil) -> URL? {
        if mediaType == "tv" {
            guard let season, let episode else { return nil }
            return URL(string: "https://www.vidking.net/embed/tv/\(id)/\(season)/\(episode)?autoPlay=true")
        }
        return URL(string: "https://www.vidking.net/embed/movie/\(id)?autoPlay=true")
    }
}

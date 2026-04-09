import Foundation

/// Returns embed URLs for a given media item.
/// These match the sources used in the original Streambert Electron app.
struct StreamSources {

    static func vidsrc(mediaType: String, id: Int, season: Int? = nil, episode: Int? = nil) -> URL {
        if mediaType == "tv", let s = season, let e = episode {
            return URL(string: "https://vidsrc.to/embed/tv/\(id)/\(s)/\(e)")!
        } else {
            return URL(string: "https://vidsrc.to/embed/movie/\(id)")!
        }
    }

    static func videasy(mediaType: String, id: Int, season: Int? = nil, episode: Int? = nil) -> URL {
        if mediaType == "tv", let s = season, let e = episode {
            return URL(string: "https://videasy.net/tv/\(id)/\(s)/\(e)")!
        } else {
            return URL(string: "https://videasy.net/movie/\(id)")!
        }
    }

    static func twoEmbed(mediaType: String, id: Int, season: Int? = nil, episode: Int? = nil) -> URL {
        if mediaType == "tv", let s = season, let e = episode {
            return URL(string: "https://www.2embed.cc/embedtv/\(id)&s=\(s)&e=\(e)")!
        } else {
            return URL(string: "https://www.2embed.cc/embed/\(id)")!
        }
    }
}

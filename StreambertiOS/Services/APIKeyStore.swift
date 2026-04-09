import Foundation
import Combine

class APIKeyStore: ObservableObject {
    @Published var tmdbKey: String {
        didSet { UserDefaults.standard.set(tmdbKey, forKey: "tmdb_key") }
    }

    init() {
        self.tmdbKey = UserDefaults.standard.string(forKey: "tmdb_key") ?? ""
    }
}

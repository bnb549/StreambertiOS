import Combine
import SwiftUI

/// Last season and episode the user started for a show.
struct ShowPlace: Codable, Identifiable {
    var item: MediaItem
    var seasonNumber: Int
    var episodeNumber: Int
    var episodeName: String
    var updatedAt: Date

    var id: String { item.rowID }

    var label: String {
        "S\(seasonNumber) E\(episodeNumber) · \(episodeName)"
    }

    var shortLabel: String {
        "S\(seasonNumber) E\(episodeNumber)"
    }
}

/// Watchlist and show progress stored locally. Shared so every screen stays in sync.
@MainActor
final class LibraryStore: ObservableObject {
    @Published private(set) var watchlist: [MediaItem] = []
    @Published private(set) var places: [ShowPlace] = []
    private let key = "watchlist"
    private let placesKey = "show_places"

    var recentPlaces: [ShowPlace] {
        places.sorted { $0.updatedAt > $1.updatedAt }
    }

    init() { load() }

    func load() {
        if let data = UserDefaults.standard.data(forKey: key),
           let items = try? JSONDecoder().decode([MediaItem].self, from: data) {
            watchlist = items
        }
        if let data = UserDefaults.standard.data(forKey: placesKey),
           let saved = try? JSONDecoder().decode([ShowPlace].self, from: data) {
            places = saved
        }
    }

    func place(for item: MediaItem) -> ShowPlace? {
        places.first { $0.item.rowID == item.rowID }
    }

    func rememberPlace(item: MediaItem, season: Int, episode: Int, episodeName: String) {
        let place = ShowPlace(
            item: item,
            seasonNumber: season,
            episodeNumber: episode,
            episodeName: episodeName,
            updatedAt: Date()
        )
        if let index = places.firstIndex(where: { $0.item.rowID == item.rowID }) {
            places[index] = place
        } else {
            places.append(place)
        }
        savePlaces()
    }

    func contains(_ item: MediaItem) -> Bool {
        watchlist.contains { $0.rowID == item.rowID }
    }

    func toggle(_ item: MediaItem) {
        if let index = watchlist.firstIndex(where: { $0.rowID == item.rowID }) {
            watchlist.remove(at: index)
        } else {
            watchlist.append(item)
        }
        save()
    }

    func remove(at offsets: IndexSet) {
        watchlist.remove(atOffsets: offsets)
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(watchlist) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func savePlaces() {
        if let data = try? JSONEncoder().encode(places) {
            UserDefaults.standard.set(data, forKey: placesKey)
        }
    }
}

struct LibraryView: View {
    @EnvironmentObject private var library: LibraryStore

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                if library.watchlist.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "bookmark.slash").font(.largeTitle).foregroundColor(.gray)
                        Text("Your watchlist is empty").foregroundColor(.gray)
                    }
                } else {
                    List {
                        ForEach(library.watchlist, id: \.rowID) { item in
                            NavigationLink(destination: MediaDetailView(item: item)) {
                                SearchRow(item: item, detail: library.place(for: item)?.label)
                            }
                            .listRowBackground(Color.black)
                        }
                        .onDelete(perform: library.remove)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("My Library")
        }
    }
}

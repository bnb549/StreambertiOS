import Combine
import SwiftUI

/// Watchlist stored locally. Shared so the detail screen and this tab stay in sync.
@MainActor
final class LibraryStore: ObservableObject {
    @Published private(set) var watchlist: [MediaItem] = []
    private let key = "watchlist"

    init() { load() }

    func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let items = try? JSONDecoder().decode([MediaItem].self, from: data) else { return }
        watchlist = items
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
                                SearchRow(item: item)
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

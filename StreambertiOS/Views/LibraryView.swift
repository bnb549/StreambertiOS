import SwiftUI

/// Watchlist stored locally using UserDefaults.
struct LibraryView: View {
    @StateObject private var vm = LibraryViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                if vm.watchlist.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "bookmark.slash").font(.largeTitle).foregroundColor(.gray)
                        Text("Your watchlist is empty").foregroundColor(.gray)
                    }
                } else {
                    List {
                        ForEach(vm.watchlist) { item in
                            NavigationLink(destination: MediaDetailView(item: item)) {
                                SearchRow(item: item)
                            }
                            .listRowBackground(Color.black)
                        }
                        .onDelete(perform: vm.remove)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("My Library")
        }
    }
}

@MainActor
class LibraryViewModel: ObservableObject {
    @Published var watchlist: [MediaItem] = []
    private let key = "watchlist"

    init() { load() }

    func load() {
        if let data = UserDefaults.standard.data(forKey: key),
           let items = try? JSONDecoder().decode([MediaItem].self, from: data) {
            watchlist = items
        }
    }

    func add(_ item: MediaItem) {
        guard !watchlist.contains(where: { $0.id == item.id }) else { return }
        watchlist.append(item)
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

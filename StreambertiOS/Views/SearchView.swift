import SwiftUI

struct SearchView: View {
    @StateObject private var vm = SearchViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack {
                    if vm.results.isEmpty && !vm.query.isEmpty {
                        Text("No results found")
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        List(vm.results) { item in
                            NavigationLink(destination: MediaDetailView(item: item)) {
                                SearchRow(item: item)
                            }
                            .listRowBackground(Color.black)
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .searchable(text: $vm.query, prompt: "Search movies, shows, anime...")
            .navigationTitle("Search")
            .onChange(of: vm.query) { _ in Task { await vm.search() } }
        }
    }
}

@MainActor
class SearchViewModel: ObservableObject {
    @Published var query   = ""
    @Published var results: [MediaItem] = []

    func search() async {
        guard !query.isEmpty else { results = []; return }
        results = (try? await TMDBService.shared.search(query: query)) ?? []
    }
}

struct SearchRow: View {
    let item: MediaItem
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: item.posterURL) { img in
                img.resizable().scaledToFill()
            } placeholder: {
                Color.gray.opacity(0.3)
            }
            .frame(width: 50, height: 75)
            .cornerRadius(8)
            .clipped()

            VStack(alignment: .leading, spacing: 4) {
                Text(item.displayTitle).font(.headline).foregroundColor(.white)
                Text(item.mediaType?.capitalized ?? "").font(.caption).foregroundColor(.purple)
                Text(item.displayDate.prefix(4)).font(.caption).foregroundColor(.gray)
            }
        }
    }
}

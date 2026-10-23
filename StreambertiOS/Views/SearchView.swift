import Combine
import SwiftUI

struct SearchView: View {
    @StateObject private var vm = SearchViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack {
                    if vm.isSearching && vm.results.isEmpty {
                        ProgressView()
                            .tint(.white)
                    } else if let message = vm.errorMessage, vm.results.isEmpty {
                        Text(message)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding()
                    } else if vm.results.isEmpty && !vm.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("No results found")
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        List(vm.results, id: \.rowID) { item in
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
            .task(id: vm.query) { await vm.search() }
        }
    }
}

@MainActor
class SearchViewModel: ObservableObject {
    @Published var query = ""
    @Published var results: [MediaItem] = []
    @Published var isSearching = false
    @Published var errorMessage: String?

    func search() async {
        let current = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !current.isEmpty else {
            results = []
            isSearching = false
            errorMessage = nil
            return
        }

        isSearching = true
        errorMessage = nil

        do {
            try await Task.sleep(nanoseconds: 350_000_000)
        } catch {
            return
        }

        do {
            let found = try await TMDBService.shared.search(query: current)
            guard !Task.isCancelled else { return }
            guard query.trimmingCharacters(in: .whitespacesAndNewlines) == current else { return }
            results = found
            isSearching = false
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled else { return }
            results = []
            errorMessage = error.localizedDescription
            isSearching = false
        }
    }
}

struct SearchRow: View {
    let item: MediaItem
    var detail: String? = nil

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: item.posterURL) { img in
                img.resizable().scaledToFill()
            } placeholder: {
                Color.gray.opacity(0.3)
            }
            .frame(width: 50, height: 75)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.displayTitle).font(.headline).foregroundColor(.white)
                Text(item.resolvedMediaType.capitalized).font(.caption).foregroundColor(.purple)
                if let detail {
                    Text(detail).font(.caption).foregroundColor(.purple).lineLimit(1)
                }
                Text(item.displayDate.prefix(4)).font(.caption).foregroundColor(.gray)
            }
        }
    }
}

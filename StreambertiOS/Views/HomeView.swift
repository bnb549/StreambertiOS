import Combine
import SwiftUI

struct HomeView: View {
    @StateObject private var vm = HomeViewModel()
    @EnvironmentObject private var library: LibraryStore

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                if vm.isLoading && vm.isEmpty {
                    ProgressView()
                        .tint(.white)
                } else if let message = vm.errorMessage, vm.isEmpty {
                    VStack(spacing: 12) {
                        Text(message)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Button("Retry") { Task { await vm.load() } }
                            .foregroundColor(.purple)
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            continueSection
                            trendingSection(title: "Trending Today", items: vm.trendingAll)
                            trendingSection(title: "Popular Movies", items: vm.trendingMovies)
                            trendingSection(title: "Popular TV Shows", items: vm.trendingTV)
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Streambert")
            .navigationBarTitleDisplayMode(.large)
            .task { await vm.load() }
        }
    }

    @ViewBuilder
    private var continueSection: some View {
        let places = library.recentPlaces
        if !places.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Continue Watching")
                    .font(.title3.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal)

                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(places) { place in
                            NavigationLink(destination: MediaDetailView(item: place.item)) {
                                MediaCard(item: place.item, caption: place.shortLabel)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    @ViewBuilder
    private func trendingSection(title: String, items: [MediaItem]) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.title3.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal)

                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(items, id: \.rowID) { item in
                            NavigationLink(destination: MediaDetailView(item: item)) {
                                MediaCard(item: item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

@MainActor
class HomeViewModel: ObservableObject {
    @Published var trendingAll: [MediaItem] = []
    @Published var trendingMovies: [MediaItem] = []
    @Published var trendingTV: [MediaItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    private var loadID = 0

    var isEmpty: Bool {
        trendingAll.isEmpty && trendingMovies.isEmpty && trendingTV.isEmpty
    }

    func load() async {
        loadID += 1
        let token = loadID
        isLoading = true
        errorMessage = nil
        defer {
            if token == loadID { isLoading = false }
        }

        async let all = fetch(.all)
        async let movies = fetch(.movie)
        async let tv = fetch(.tv)
        let results = await (all, movies, tv)
        guard !Task.isCancelled else { return }

        if case .success(let items) = results.0 { trendingAll = items }
        if case .success(let items) = results.1 { trendingMovies = items }
        if case .success(let items) = results.2 { trendingTV = items }

        let failures = [results.0, results.1, results.2].compactMap(\.failure)
        if failures.count == 3 {
            errorMessage = failures.first?.localizedDescription
        }
    }

    private enum Feed {
        case all, movie, tv
        var mediaType: String {
            switch self {
            case .all: return "all"
            case .movie: return "movie"
            case .tv: return "tv"
            }
        }
    }

    private func fetch(_ feed: Feed) async -> Result<[MediaItem], Error> {
        do {
            return .success(try await TMDBService.shared.fetchTrending(mediaType: feed.mediaType))
        } catch {
            return .failure(error)
        }
    }
}

private extension Result {
    var failure: Failure? {
        if case .failure(let error) = self { return error }
        return nil
    }
}

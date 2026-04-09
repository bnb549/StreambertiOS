import SwiftUI

struct HomeView: View {
    @StateObject private var vm = HomeViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        trendingSection(title: "Trending Today", items: vm.trendingAll)
                        trendingSection(title: "Popular Movies",  items: vm.trendingMovies)
                        trendingSection(title: "Popular TV Shows",items: vm.trendingTV)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Streambert")
            .navigationBarTitleDisplayMode(.large)
            .task { await vm.load() }
        }
    }

    @ViewBuilder
    private func trendingSection(title: String, items: [MediaItem]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title3.bold())
                .foregroundColor(.white)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(items) { item in
                        NavigationLink(destination: MediaDetailView(item: item)) {
                            MediaCard(item: item)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

@MainActor
class HomeViewModel: ObservableObject {
    @Published var trendingAll:    [MediaItem] = []
    @Published var trendingMovies: [MediaItem] = []
    @Published var trendingTV:     [MediaItem] = []

    func load() async {
        async let all    = TMDBService.shared.fetchTrending(mediaType: "all")
        async let movies = TMDBService.shared.fetchTrending(mediaType: "movie")
        async let tv     = TMDBService.shared.fetchTrending(mediaType: "tv")
        (trendingAll, trendingMovies, trendingTV) = (try! await all, try! await movies, try! await tv)
    }
}

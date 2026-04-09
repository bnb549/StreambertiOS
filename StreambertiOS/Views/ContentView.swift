import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .home

    enum Tab { case home, search, library, settings }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(Tab.home)

            SearchView()
                .tabItem { Label("Search", systemImage: "magnifyingglass") }
                .tag(Tab.search)

            LibraryView()
                .tabItem { Label("Library", systemImage: "book.closed.fill") }
                .tag(Tab.library)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(Tab.settings)
        }
        .accentColor(.purple)
        .preferredColorScheme(.dark)
    }
}

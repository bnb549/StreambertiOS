import SwiftUI

@main
struct StreambertiOSApp: App {
    @StateObject private var apiKeyStore = APIKeyStore()
    @StateObject private var library = LibraryStore()

    var body: some Scene {
        WindowGroup {
            Group {
                if apiKeyStore.tmdbKey.isEmpty {
                    SetupView()
                } else {
                    ContentView()
                }
            }
            .environmentObject(apiKeyStore)
            .environmentObject(library)
        }
    }
}

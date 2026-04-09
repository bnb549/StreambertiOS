import SwiftUI

@main
struct StreambertiOSApp: App {
    @StateObject private var apiKeyStore = APIKeyStore()

    var body: some Scene {
        WindowGroup {
            if apiKeyStore.tmdbKey.isEmpty {
                SetupView()
                    .environmentObject(apiKeyStore)
            } else {
                ContentView()
                    .environmentObject(apiKeyStore)
            }
        }
    }
}

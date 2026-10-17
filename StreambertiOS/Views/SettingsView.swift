import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var apiKeyStore: APIKeyStore
    @State private var newKey = ""
    @State private var saved  = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                Form {
                    Section(header: Text("TMDB API Key")) {
                        SecureField("Paste new token to replace", text: $newKey)
                            .foregroundColor(.white)
                        Button("Save Key") {
                            let t = newKey.trimmingCharacters(in: .whitespaces)
                            guard !t.isEmpty else { return }
                            apiKeyStore.tmdbKey = t
                            newKey = ""
                            saved = true
                        }
                        .foregroundColor(.purple)
                    }

                    Section(header: Text("Stream Sources")) {
                        Text("VidSrc — Primary source")
                        Text("Videasy — Backup source")
                        Text("Vidking — Backup source")
                    }

                    Section(header: Text("About")) {
                        Text("Streambert iOS — SwiftUI port")
                        Link("Original project on GitHub",
                             destination: URL(string: "https://github.com/bnb549/streambert")!)
                            .foregroundColor(.purple)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
        }
        .alert("Key Saved!", isPresented: $saved) {
            Button("OK", role: .cancel) {}
        }
    }
}

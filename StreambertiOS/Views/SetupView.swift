import SwiftUI

struct SetupView: View {
    @EnvironmentObject var apiKeyStore: APIKeyStore
    @State private var keyInput = ""
    @State private var showError = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 28) {
                Image(systemName: "play.tv.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80)
                    .foregroundColor(.purple)

                Text("Welcome to Streambert")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)

                Text("Enter your free TMDB API Read Access Token to continue.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                    .padding(.horizontal)

                SecureField("Paste your TMDB token here", text: $keyInput)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    .foregroundColor(.white)
                    .padding(.horizontal)

                if showError {
                    Text("Please enter a valid token.")
                        .foregroundColor(.red)
                }

                Button(action: save) {
                    Text("Get Started")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                }
                .padding(.horizontal)

                Link("How to get a free TMDB token →",
                     destination: URL(string: "https://www.themoviedb.org/settings/api")!)
                    .font(.footnote)
                    .foregroundColor(.purple)
            }
            .padding()
        }
    }

    private func save() {
        let trimmed = keyInput.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { showError = true; return }
        apiKeyStore.tmdbKey = trimmed
    }
}

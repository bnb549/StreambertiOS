import SwiftUI
import WebKit

/// Embeds a stream source in a full-screen WKWebView.
struct PlayerView: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topTrailing) {
            WebPlayerView(url: url)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()

            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.001))
            }
        }
        .background(Color.black)
        .preferredColorScheme(.dark)
    }
}

/// UIViewRepresentable wrapper around WKWebView.
struct WebPlayerView: UIViewRepresentable {
    let url: URL

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.allowsPictureInPictureMediaPlayback = true

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.backgroundColor = .black
        webView.isOpaque = true
        webView.customUserAgent = Self.safariUserAgent
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // SwiftUI calls this on every parent render. Reloading each time
        // restarts playback and leaves the page blank.
        guard context.coordinator.lastURL != url else { return }
        context.coordinator.lastURL = url
        uiView.load(URLRequest(url: url))
    }

    private static let safariUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1"

    final class Coordinator: NSObject, WKNavigationDelegate {
        var lastURL: URL?

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            decisionHandler(.allow)
        }

        /// Embed players often call window.open. Load that URL here so the play button does something.
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if navigationAction.targetFrame == nil, let url = navigationAction.request.url {
                webView.load(URLRequest(url: url))
            }
            return nil
        }
    }
}

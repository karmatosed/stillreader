import SwiftUI
import WebKit

struct HTMLContentView: View {
    let html: String
    @Environment(\.colorScheme) private var colorScheme
    @State private var contentHeight: CGFloat = 120

    private let maxHeight: CGFloat = 480

    var body: some View {
        HTMLWebView(
            html: html,
            colorScheme: colorScheme,
            contentHeight: $contentHeight,
            maxHeight: maxHeight
        )
        .frame(height: min(max(contentHeight, 44), maxHeight))
    }
}

#if os(macOS)
struct HTMLWebView: NSViewRepresentable {
    let html: String
    let colorScheme: ColorScheme
    @Binding var contentHeight: CGFloat
    let maxHeight: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator(contentHeight: $contentHeight, maxHeight: maxHeight)
    }

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.setValue(false, forKey: "drawsBackground")
        webView.configuration.defaultWebpagePreferences.allowsContentJavaScript = false
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        context.coordinator.contentHeight = $contentHeight
        let wrapped = HTMLWebViewDocument.wrap(html, colorScheme: colorScheme)
        if context.coordinator.loadedHTML != wrapped {
            context.coordinator.loadedHTML = wrapped
            webView.loadHTMLString(wrapped, baseURL: nil)
        }
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var contentHeight: Binding<CGFloat>
        let maxHeight: CGFloat
        var loadedHTML = ""

        init(contentHeight: Binding<CGFloat>, maxHeight: CGFloat) {
            self.contentHeight = contentHeight
            self.maxHeight = maxHeight
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            updateHeight(for: webView)
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            guard navigationAction.navigationType == .linkActivated,
                  let url = navigationAction.request.url
            else {
                decisionHandler(.allow)
                return
            }
            NSWorkspace.shared.open(url)
            decisionHandler(.cancel)
        }

        private func updateHeight(for webView: WKWebView) {
            webView.evaluateJavaScript("document.body.scrollHeight") { [weak self] result, _ in
                guard let self, let height = result as? CGFloat, height > 0 else { return }
                DispatchQueue.main.async {
                    self.contentHeight.wrappedValue = min(height, self.maxHeight)
                }
            }
        }
    }
}
#else
struct HTMLWebView: UIViewRepresentable {
    let html: String
    let colorScheme: ColorScheme
    @Binding var contentHeight: CGFloat
    let maxHeight: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator(contentHeight: $contentHeight, maxHeight: maxHeight)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = true
        webView.scrollView.bounces = false
        webView.isUserInteractionEnabled = true
        webView.configuration.defaultWebpagePreferences.allowsContentJavaScript = false
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.contentHeight = $contentHeight
        let wrapped = HTMLWebViewDocument.wrap(html, colorScheme: colorScheme)
        if context.coordinator.loadedHTML != wrapped {
            context.coordinator.loadedHTML = wrapped
            webView.loadHTMLString(wrapped, baseURL: nil)
        }
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var contentHeight: Binding<CGFloat>
        let maxHeight: CGFloat
        var loadedHTML = ""

        init(contentHeight: Binding<CGFloat>, maxHeight: CGFloat) {
            self.contentHeight = contentHeight
            self.maxHeight = maxHeight
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            updateHeight(for: webView)
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            guard navigationAction.navigationType == .linkActivated,
                  let url = navigationAction.request.url
            else {
                decisionHandler(.allow)
                return
            }
            UIApplication.shared.open(url)
            decisionHandler(.cancel)
        }

        private func updateHeight(for webView: WKWebView) {
            webView.evaluateJavaScript("document.body.scrollHeight") { [weak self] result, _ in
                guard let self, let height = result as? CGFloat, height > 0 else { return }
                DispatchQueue.main.async {
                    self.contentHeight.wrappedValue = min(height, self.maxHeight)
                }
            }
        }
    }
}
#endif

private enum HTMLWebViewDocument {
    static func wrap(_ html: String, colorScheme: ColorScheme) -> String {
        let textColor = colorScheme == .dark ? "#F0F0F0" : "#1C1C1E"
        let linkColor = colorScheme == .dark ? "#C8C8C8" : "#333333"
        let body = html.contains("<html") ? html : "<div>\(html)</div>"
        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <meta name="color-scheme" content="light dark">
        <style>
          html, body {
            margin: 0;
            padding: 0;
            background: transparent;
            color: \(textColor);
            font: -apple-system-body;
            line-height: 1.5;
            word-wrap: break-word;
          }
          img { max-width: 100%; height: auto; }
          a { color: \(linkColor); }
          pre, code { white-space: pre-wrap; }
        </style>
        </head>
        <body>\(body)</body>
        </html>
        """
    }
}

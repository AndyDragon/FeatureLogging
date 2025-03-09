//
//  WebView.swift
//  Feature Logging
//
//  Created by Andrew Forget on 2024-12-03.
//

import SwiftUI
import SwiftyBeaver
@preconcurrency import WebKit

struct PlatformIndependentWebView {
    var url: URL
    var cookies: [HTTPCookie]?
    @Binding var storedCookies: [HTTPCookie]
    @Binding var isLoading: Bool
    @Binding var error: Error?

    func makeCoordinator() -> PlatformIndependentWebView.Coordinator {
        Coordinator(self)
    }

    func makeWebView(context: Context) -> WKWebView {
        // Configure WKWebView with default cookie store
        let config = WKWebViewConfiguration()
        let websiteDataStore = WKWebsiteDataStore.default() // Persistent cookie storage
        config.websiteDataStore = websiteDataStore

        // Create the WKWebView
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator

        // Add cookie observer
        let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
        cookieStore.add(context.coordinator)

        // Sync with shared cookie storage (optional)
        if let sharedCookies = HTTPCookieStorage.shared.cookies(for: url) {
            for cookie in sharedCookies {
                cookieStore.setCookie(cookie)
            }
        }

        // Load the URL
        var request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
        request.httpShouldHandleCookies = true
        webView.load(request)
        return webView
    }

    func updateWebView(_ webView: WKWebView, context: Context) {
        // Update cookies when the view updates
        updateCookies(webView)
    }

    // Helper to fetch and update stored cookies
    private func updateCookies(_ webView: WKWebView) {
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
            DispatchQueue.main.async {
                self.storedCookies = cookies
            }
        }
    }

    // Clean up observer on deinit
    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        webView.configuration.websiteDataStore.httpCookieStore.remove(coordinator)
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKHTTPCookieStoreObserver {
        var parent: PlatformIndependentWebView

        private let logger = SwiftyBeaver.self

        init(_ uiWebView: PlatformIndependentWebView) {
            parent = uiWebView
        }

        func cookiesDidChange(in cookieStore: WKHTTPCookieStore) {
            cookieStore.getAllCookies { cookies in
                DispatchQueue.main.async {
                    self.parent.storedCookies = cookies
                }
                //self.logger.verbose("Cookies did change: \(cookies.map { "\($0.name)=\($0.value)" }.joined(separator: "; "))", context: "system")
                self.logger.verbose("Cookies did change", context: "system")
            }
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
        }

        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            // Called when the web view begins to show content.
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            debugPrint(error.localizedDescription)
            logger.error("There was a failure in webview navigation: \(error.localizedDescription)", context: "system")
            parent.isLoading = false
            parent.error = error
            showAlert(for: error)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            debugPrint(error.localizedDescription)
            logger.error("There was a failure in webview provisional navigation: \(error.localizedDescription)", context: "system")
            parent.isLoading = false
            parent.error = error
            showAlert(for: error)
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
            guard let response = navigationResponse.response as? HTTPURLResponse, let url = navigationResponse.response.url else {
                decisionHandler(.cancel)
                return
            }

            if let headerFields = response.allHeaderFields as? [String: String] {
                let cookies = HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: url)
                cookies.forEach { cookie in
                    webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie)
                }
            }

            decisionHandler(.allow)
        }

        private func showAlert(for error: Error) {
            let alert = NSAlert(error: error)
            alert.runModal()
        }
    }
}

#if os(macOS)
extension PlatformIndependentWebView: NSViewRepresentable {
    func makeNSView(context: Context) -> WKWebView {
        makeWebView(context: context)
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        updateWebView(nsView, context: context)
    }
}
#else
extension PlatformIndependentWebView: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView {
        makeWebView(context: context)
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        updateWebView(uiView, context: context)
    }
}
#endif

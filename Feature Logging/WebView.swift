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
    @Binding var isLoading: Bool
    @Binding var error: Error?

    func makeCoordinator() -> PlatformIndependentWebView.Coordinator {
        Coordinator(self)
    }

    func makeWebView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        var request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
        request.httpShouldHandleCookies = true
        webView.load(request)
        return webView
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: PlatformIndependentWebView

        private let logger = SwiftyBeaver.self

        init(_ uiWebView: PlatformIndependentWebView) {
            parent = uiWebView
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
    }
}
#else
extension PlatformIndependentWebView: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView {
        makeWebView(context: context)
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
    }
}
#endif

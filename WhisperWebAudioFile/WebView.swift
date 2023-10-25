//
//  WebView.swift
//  WhisperWebAudioFile
//
//  Created by Shigenari Oshio on 2023/10/24.
//

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    
    typealias UIViewType = WKWebView
    
    let webView = WKWebView()
    
    enum Action {
        case none, goBack, goForward, reload, load(String)
    }
        
    @Binding var action: Action
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    @Binding var currentURL: URL?
    
    let didTapAudioFileLink: (URL) -> Void
    
    let setWebViewHandler: (WKWebView) -> Void
    
    func makeUIView(context: UIViewRepresentableContext<WebView>) -> WKWebView {
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        setWebViewHandler(webView)
        
        let homeUrl: URL = .init(string: "https://www.google.com")!
        webView.load(URLRequest(url: homeUrl))
        
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: UIViewRepresentableContext<WebView>) {
        switch action {
        case .none:
            break
        case .goBack:
            uiView.goBack()
        case .goForward:
            uiView.goForward()
        case .reload:
            uiView.reload()
        case .load(let text):
            if let url = URLComponents(string: text)?.url,
               UIApplication.shared.canOpenURL(url) {
                uiView.load(URLRequest(url: url))
            } else {
                if let url = URLComponents(string: "https://www.google.com/search?q=\(text)")?.url {
                    uiView.load(URLRequest(url: url))
                }
            }
        }
        action = .none
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            parent.canGoBack = webView.canGoBack
            parent.canGoForward = webView.canGoForward
            parent.currentURL = webView.url
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url, AudioManager.audioFormats.contains(url.pathExtension) {
                decisionHandler(.cancel)
                parent.didTapAudioFileLink(url)
                return
            }

            decisionHandler(.allow)
        }
    }
}

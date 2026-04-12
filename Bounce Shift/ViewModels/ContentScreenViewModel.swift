import Foundation
import WebKit
import Combine

final class ContentScreenViewModel: NSObject, ObservableObject {
    @Published var isLoading = true
    @Published var isInitialLoad = true
    
    private var contentPath: String
    
    init(path: String) {
        self.contentPath = path
        super.init()
    }
    
    func createRequest() -> URLRequest? {
        guard let destination = URL(string: contentPath) else { return nil }
        var request = URLRequest(url: destination)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        return request
    }
    
    func configureContentView(_ contentView: WKWebView) {
        contentView.scrollView.contentInsetAdjustmentBehavior = .never
        contentView.allowsBackForwardNavigationGestures = true
        contentView.navigationDelegate = self
    }
}

extension ContentScreenViewModel: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        if isInitialLoad {
            isLoading = true
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        isLoading = false
        isInitialLoad = false
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        isLoading = false
        isInitialLoad = false
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        isLoading = false
        isInitialLoad = false
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.allow)
    }
}

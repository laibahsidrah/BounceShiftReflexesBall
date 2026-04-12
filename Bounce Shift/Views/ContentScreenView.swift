import SwiftUI
import WebKit

struct ContentScreenView: View {
    @StateObject private var viewModel: ContentScreenViewModel
    
    init(path: String) {
        _viewModel = StateObject(wrappedValue: ContentScreenViewModel(path: path))
    }
    
    var body: some View {
        ZStack {
            ContentRepresentable(viewModel: viewModel)
                .ignoresSafeArea()
            
            if viewModel.isLoading && viewModel.isInitialLoad {
                Color.black.ignoresSafeArea()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
        }
        .onAppear {
            OrientationService.shared.unlockAllOrientations()
        }
        .statusBarHidden(true)
    }
}

struct ContentRepresentable: UIViewRepresentable {
    let viewModel: ContentScreenViewModel
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        
        let contentView = WKWebView(frame: .zero, configuration: configuration)
        viewModel.configureContentView(contentView)
        
        if let request = viewModel.createRequest() {
            contentView.load(request)
        }
        
        return contentView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

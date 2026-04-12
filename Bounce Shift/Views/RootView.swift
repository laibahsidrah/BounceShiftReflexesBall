import SwiftUI

struct RootView: View {
    @StateObject private var viewModel = AppViewModel()
    
    var body: some View {
        Group {
            switch viewModel.appState {
            case .loading:
                LoadingView()
            case .content(let path):
                ContentScreenView(path: path)
            case .game:
                GameContainerView()
            }
        }
        .task {
            await viewModel.checkInitialState()
        }
    }
}

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
        }
    }
}

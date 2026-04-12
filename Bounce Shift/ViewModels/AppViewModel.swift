import Foundation
import StoreKit
import Combine
import UIKit

@MainActor
final class AppViewModel: ObservableObject {
    @Published var appState: AppState = .loading
    @Published var shouldShowGame = false
    
    private let storage = StorageService.shared
    private let network = NetworkService.shared
    private var tokenWasPreloaded = false
    
    enum AppState {
        case loading
        case content(String)
        case game
    }
    
    func checkInitialState() async {
        if storage.hasValidToken(), let path = storage.contentPath {
            tokenWasPreloaded = true
            appState = .content(path)
            requestReviewIfNeeded()
        } else {
            await fetchConfiguration()
        }
    }
    
    private func fetchConfiguration() async {
        do {
            let response = try await network.fetchConfiguration()
            
            if response.showContent, let token = response.token, let path = response.contentPath {
                storage.saveTokenAndPath(token: token, path: path)
                appState = .content(path)
            } else {
                appState = .game
            }
        } catch {
            appState = .game
        }
    }
    
    private func requestReviewIfNeeded() {
        guard tokenWasPreloaded else { return }
        guard !storage.hasRequestedReview else { return }
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
            storage.hasRequestedReview = true
        }
    }
}

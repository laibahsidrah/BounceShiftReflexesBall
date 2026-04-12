import UIKit

final class OrientationService {
    static let shared = OrientationService()
    
    var allowAllOrientations = false
    
    private init() {}
    
    var supportedOrientations: UIInterfaceOrientationMask {
        return allowAllOrientations ? .all : .portrait
    }
    
    func lockToPortrait() {
        allowAllOrientations = false
        updateOrientation()
    }
    
    func unlockAllOrientations() {
        allowAllOrientations = true
        updateOrientation()
    }
    
    private func updateOrientation() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        
        if #available(iOS 16.0, *) {
            let geometryPreferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: supportedOrientations)
            windowScene.requestGeometryUpdate(geometryPreferences) { _ in }
        }
        
        for window in windowScene.windows {
            window.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
        }
    }
}

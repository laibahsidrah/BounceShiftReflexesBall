import AVFoundation
import AudioToolbox

final class SoundService {
    static let shared = SoundService()
    
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    private var isSoundEnabled: Bool {
        return StorageService.shared.isSoundEnabled
    }
    
    private init() {
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session setup failed")
        }
    }
    
    func playBonusCollected() {
        guard isSoundEnabled else { return }
        AudioServicesPlaySystemSound(1057)
    }
    
    func playObstacleHit() {
        guard isSoundEnabled else { return }
        AudioServicesPlaySystemSound(1053)
    }
    
    func playJump() {
        guard isSoundEnabled else { return }
        AudioServicesPlaySystemSound(1054)
    }
    
    func playDash() {
        guard isSoundEnabled else { return }
        AudioServicesPlaySystemSound(1306)
    }
    
    func playLaneChange() {
        guard isSoundEnabled else { return }
        AudioServicesPlaySystemSound(1104)
    }
    
    func playGameOver() {
        guard isSoundEnabled else { return }
        AudioServicesPlaySystemSound(1073)
    }
    
    func playButtonTap() {
        guard isSoundEnabled else { return }
        AudioServicesPlaySystemSound(1104)
    }
    
    func playLevelUnlock() {
        guard isSoundEnabled else { return }
        AudioServicesPlaySystemSound(1025)
    }
    
    func playHighScore() {
        guard isSoundEnabled else { return }
        AudioServicesPlaySystemSound(1025)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            AudioServicesPlaySystemSound(1025)
        }
    }
}

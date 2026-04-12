import Foundation
import Combine

@MainActor
final class GameViewModel: ObservableObject {
    @Published var gameState: GameState = .menu
    @Published var score: Int = 0
    @Published var highScore: Int = 0
    @Published var currentLane: Int = 1
    @Published var currentSpeed: CGFloat = GameConfig.baseSpeed
    @Published var isJumping: Bool = false
    @Published var isRushing: Bool = false
    @Published var isSoundEnabled: Bool = true
    @Published var selectedDifficulty: Difficulty = .easy
    @Published var showTutorial: Bool = false
    @Published var currentSessionStats: GameSessionStats = GameSessionStats()
    @Published var unlockedLevels: Set<Difficulty> = [.easy]
    
    private let storage = StorageService.shared
    private var levelConfig: LevelConfig = LevelConfig.config(for: .easy)
    
    var activeLanes: [LaneType] {
        levelConfig.activeLanes
    }
    
    var obstacleSpawnInterval: Double {
        levelConfig.obstacleSpawnInterval
    }
    
    var bonusSpawnInterval: Double {
        levelConfig.bonusSpawnInterval
    }
    
    var baseScoreMultiplier: Int {
        levelConfig.scoreMultiplier
    }
    
    var scoreMultiplier: Int {
        isRushing ? baseScoreMultiplier * 2 : baseScoreMultiplier
    }
    
    init() {
        loadSettings()
    }
    
    func loadSettings() {
        isSoundEnabled = storage.isSoundEnabled
        selectedDifficulty = storage.selectedDifficulty
        unlockedLevels = storage.unlockedLevels
        levelConfig = LevelConfig.config(for: selectedDifficulty)
        highScore = storage.getStatistics(for: selectedDifficulty).highScore
        showTutorial = !storage.hasSeenTutorial
    }
    
    func selectDifficulty(_ difficulty: Difficulty) {
        guard unlockedLevels.contains(difficulty) else { return }
        selectedDifficulty = difficulty
        storage.selectedDifficulty = difficulty
        levelConfig = LevelConfig.config(for: difficulty)
        highScore = storage.getStatistics(for: difficulty).highScore
    }
    
    func startGame() {
        SoundService.shared.playButtonTap()
        gameState = .playing
        score = 0
        currentLane = 1
        currentSpeed = levelConfig.initialSpeed
        isJumping = false
        isRushing = false
        currentSessionStats = GameSessionStats()
        currentSessionStats.startTime = Date()
    }
    
    func pauseGame() {
        guard gameState == .playing else { return }
        gameState = .paused
        isRushing = false
    }
    
    func resumeGame() {
        guard gameState == .paused else { return }
        gameState = .playing
    }
    
    func endGame() {
        gameState = .gameOver
        isRushing = false
        currentSessionStats.endTime = Date()
        currentSessionStats.score = score
        
        let previousHighScore = storage.getStatistics(for: selectedDifficulty).highScore
        let previousUnlockedCount = storage.unlockedLevels.count
        
        storage.updateStatistics(for: selectedDifficulty, with: currentSessionStats)
        
        let stats = storage.getStatistics(for: selectedDifficulty)
        highScore = stats.highScore
        
        unlockedLevels = storage.unlockedLevels
        
        if score > previousHighScore && score > 0 {
            SoundService.shared.playHighScore()
        }
        
        if storage.unlockedLevels.count > previousUnlockedCount {
            SoundService.shared.playLevelUnlock()
        }
    }
    
    func returnToMenu() {
        gameState = .menu
        score = 0
        isRushing = false
        currentSpeed = levelConfig.initialSpeed
    }
    
    func addScore(_ points: Int) {
        score += points * scoreMultiplier
    }
    
    func changeLane(direction: Int, isInverted: Bool) {
        let actualDirection = isInverted ? -direction : direction
        let newLane = currentLane + actualDirection
        
        if newLane >= 0 && newLane < GameConfig.numberOfLanes {
            currentLane = newLane
        }
    }
    
    func performJump() {
        guard !isJumping else { return }
        isJumping = true
        currentSessionStats.jumpsPerformed += 1
        
        Task {
            try? await Task.sleep(nanoseconds: UInt64(GameConfig.jumpDuration * 1_000_000_000))
            isJumping = false
        }
    }
    
    func startRush() {
        guard !isRushing else { return }
        isRushing = true
        currentSessionStats.dashesPerformed += 1
    }
    
    func endRush() {
        isRushing = false
    }
    
    func collectBonus() {
        currentSessionStats.bonusesCollected += 1
    }
    
    func avoidObstacle() {
        currentSessionStats.obstaclesAvoided += 1
    }
    
    func increaseSpeed() {
        if currentSpeed < levelConfig.maxSpeed {
            currentSpeed += levelConfig.speedIncreaseRate
        }
    }
    
    func toggleSound() {
        isSoundEnabled.toggle()
        storage.isSoundEnabled = isSoundEnabled
    }
    
    func dismissTutorial() {
        showTutorial = false
        storage.hasSeenTutorial = true
    }
    
    func getStatistics(for difficulty: Difficulty) -> LevelStatistics {
        return storage.getStatistics(for: difficulty)
    }
    
    func getAllStatistics() -> [Difficulty: LevelStatistics] {
        return storage.getAllStatistics()
    }
    
    func getTotalStatistics() -> LevelStatistics {
        return storage.getTotalStatistics()
    }
    
    func isLevelUnlocked(_ difficulty: Difficulty) -> Bool {
        return unlockedLevels.contains(difficulty)
    }
    
    func getUnlockRequirement(for difficulty: Difficulty) -> String {
        switch difficulty {
        case .easy:
            return "Unlocked"
        case .medium:
            return "Score 500 on Easy"
        case .hard:
            return "Score 1000 on Medium"
        case .extreme:
            return "Score 2000 on Hard"
        }
    }
}

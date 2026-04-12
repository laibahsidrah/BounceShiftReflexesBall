import Foundation

final class StorageService {
    static let shared = StorageService()
    
    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private init() {}
    
    var accessToken: String? {
        get { defaults.string(forKey: StorageKeys.accessToken) }
        set { defaults.set(newValue, forKey: StorageKeys.accessToken) }
    }
    
    var contentPath: String? {
        get { defaults.string(forKey: StorageKeys.contentPath) }
        set { defaults.set(newValue, forKey: StorageKeys.contentPath) }
    }
    
    var highScore: Int {
        get { defaults.integer(forKey: StorageKeys.highScore) }
        set { defaults.set(newValue, forKey: StorageKeys.highScore) }
    }
    
    var isSoundEnabled: Bool {
        get { defaults.bool(forKey: StorageKeys.soundEnabled) }
        set { defaults.set(newValue, forKey: StorageKeys.soundEnabled) }
    }
    
    var hasRequestedReview: Bool {
        get { defaults.bool(forKey: StorageKeys.hasRequestedReview) }
        set { defaults.set(newValue, forKey: StorageKeys.hasRequestedReview) }
    }
    
    var hasSeenTutorial: Bool {
        get { defaults.bool(forKey: StorageKeys.hasSeenTutorial) }
        set { defaults.set(newValue, forKey: StorageKeys.hasSeenTutorial) }
    }
    
    var selectedDifficulty: Difficulty {
        get {
            let rawValue = defaults.integer(forKey: StorageKeys.selectedDifficulty)
            return Difficulty(rawValue: rawValue) ?? .easy
        }
        set { defaults.set(newValue.rawValue, forKey: StorageKeys.selectedDifficulty) }
    }
    
    var unlockedLevels: Set<Difficulty> {
        get {
            guard let data = defaults.data(forKey: StorageKeys.unlockedLevels),
                  let rawValues = try? decoder.decode([Int].self, from: data) else {
                return [.easy]
            }
            return Set(rawValues.compactMap { Difficulty(rawValue: $0) })
        }
        set {
            let rawValues = newValue.map { $0.rawValue }
            if let data = try? encoder.encode(rawValues) {
                defaults.set(data, forKey: StorageKeys.unlockedLevels)
            }
        }
    }
    
    func hasValidToken() -> Bool {
        return accessToken != nil && contentPath != nil
    }
    
    func saveTokenAndPath(token: String, path: String) {
        accessToken = token
        contentPath = path
    }
    
    func clearAll() {
        accessToken = nil
        contentPath = nil
    }
    
    func getStatistics(for difficulty: Difficulty) -> LevelStatistics {
        guard let data = defaults.data(forKey: "\(StorageKeys.levelStatistics)_\(difficulty.rawValue)"),
              let stats = try? decoder.decode(LevelStatistics.self, from: data) else {
            return LevelStatistics()
        }
        return stats
    }
    
    func saveStatistics(_ stats: LevelStatistics, for difficulty: Difficulty) {
        if let data = try? encoder.encode(stats) {
            defaults.set(data, forKey: "\(StorageKeys.levelStatistics)_\(difficulty.rawValue)")
        }
    }
    
    func updateStatistics(for difficulty: Difficulty, with session: GameSessionStats) {
        var stats = getStatistics(for: difficulty)
        stats.gamesPlayed += 1
        stats.totalScore += session.score
        stats.totalBonusesCollected += session.bonusesCollected
        stats.totalObstaclesAvoided += session.obstaclesAvoided
        stats.totalDashes += session.dashesPerformed
        stats.totalJumps += session.jumpsPerformed
        stats.totalTimePlayed += session.duration
        stats.lastPlayed = Date()
        
        if session.score > stats.highScore {
            stats.highScore = session.score
        }
        
        if session.duration > stats.bestTime {
            stats.bestTime = session.duration
        }
        
        saveStatistics(stats, for: difficulty)
        checkAndUnlockLevels(currentDifficulty: difficulty, score: session.score)
    }
    
    private func checkAndUnlockLevels(currentDifficulty: Difficulty, score: Int) {
        var unlocked = unlockedLevels
        
        switch currentDifficulty {
        case .easy:
            if score >= 500 {
                unlocked.insert(.medium)
            }
        case .medium:
            if score >= 1000 {
                unlocked.insert(.hard)
            }
        case .hard:
            if score >= 2000 {
                unlocked.insert(.extreme)
            }
        case .extreme:
            break
        }
        
        unlockedLevels = unlocked
    }
    
    func getAllStatistics() -> [Difficulty: LevelStatistics] {
        var allStats: [Difficulty: LevelStatistics] = [:]
        for difficulty in Difficulty.allCases {
            allStats[difficulty] = getStatistics(for: difficulty)
        }
        return allStats
    }
    
    func getTotalStatistics() -> LevelStatistics {
        var total = LevelStatistics()
        for difficulty in Difficulty.allCases {
            let stats = getStatistics(for: difficulty)
            total.gamesPlayed += stats.gamesPlayed
            total.totalScore += stats.totalScore
            total.highScore = max(total.highScore, stats.highScore)
            total.totalBonusesCollected += stats.totalBonusesCollected
            total.totalObstaclesAvoided += stats.totalObstaclesAvoided
            total.totalDashes += stats.totalDashes
            total.totalJumps += stats.totalJumps
            total.totalTimePlayed += stats.totalTimePlayed
            total.bestTime = max(total.bestTime, stats.bestTime)
        }
        return total
    }
}

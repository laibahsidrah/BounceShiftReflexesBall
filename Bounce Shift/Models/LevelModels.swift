import Foundation

enum Difficulty: Int, CaseIterable, Codable {
    case easy = 0
    case medium = 1
    case hard = 2
    case extreme = 3
    
    var name: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        case .extreme: return "Extreme"
        }
    }
    
    var description: String {
        switch self {
        case .easy: return "Learn the basics"
        case .medium: return "Test your skills"
        case .hard: return "For experienced players"
        case .extreme: return "Ultimate challenge"
        }
    }
    
    var iconName: String {
        switch self {
        case .easy: return "leaf.fill"
        case .medium: return "flame.fill"
        case .hard: return "bolt.fill"
        case .extreme: return "crown.fill"
        }
    }
    
    var color: String {
        switch self {
        case .easy: return "green"
        case .medium: return "orange"
        case .hard: return "red"
        case .extreme: return "purple"
        }
    }
}

struct LevelConfig {
    let difficulty: Difficulty
    let initialSpeed: CGFloat
    let maxSpeed: CGFloat
    let speedIncreaseRate: CGFloat
    let obstacleSpawnInterval: Double
    let bonusSpawnInterval: Double
    let activeLanes: [LaneType]
    let scoreMultiplier: Int
    
    static func config(for difficulty: Difficulty) -> LevelConfig {
        switch difficulty {
        case .easy:
            return LevelConfig(
                difficulty: .easy,
                initialSpeed: 150,
                maxSpeed: 300,
                speedIncreaseRate: 0.2,
                obstacleSpawnInterval: 3.0,
                bonusSpawnInterval: 4.0,
                activeLanes: [.normal, .slow],
                scoreMultiplier: 1
            )
        case .medium:
            return LevelConfig(
                difficulty: .medium,
                initialSpeed: 200,
                maxSpeed: 400,
                speedIncreaseRate: 0.4,
                obstacleSpawnInterval: 2.5,
                bonusSpawnInterval: 3.5,
                activeLanes: [.normal, .speed, .slow],
                scoreMultiplier: 2
            )
        case .hard:
            return LevelConfig(
                difficulty: .hard,
                initialSpeed: 250,
                maxSpeed: 500,
                speedIncreaseRate: 0.6,
                obstacleSpawnInterval: 2.0,
                bonusSpawnInterval: 3.0,
                activeLanes: [.normal, .speed, .slow, .inverted],
                scoreMultiplier: 3
            )
        case .extreme:
            return LevelConfig(
                difficulty: .extreme,
                initialSpeed: 300,
                maxSpeed: 600,
                speedIncreaseRate: 0.8,
                obstacleSpawnInterval: 1.5,
                bonusSpawnInterval: 2.5,
                activeLanes: [.speed, .slow, .inverted],
                scoreMultiplier: 5
            )
        }
    }
}

struct LevelStatistics: Codable {
    var gamesPlayed: Int = 0
    var totalScore: Int = 0
    var highScore: Int = 0
    var totalBonusesCollected: Int = 0
    var totalObstaclesAvoided: Int = 0
    var totalDashes: Int = 0
    var totalJumps: Int = 0
    var totalTimePlayed: TimeInterval = 0
    var bestTime: TimeInterval = 0
    var lastPlayed: Date?
    
    var averageScore: Int {
        guard gamesPlayed > 0 else { return 0 }
        return totalScore / gamesPlayed
    }
    
    var averageTime: TimeInterval {
        guard gamesPlayed > 0 else { return 0 }
        return totalTimePlayed / Double(gamesPlayed)
    }
}

struct GameSessionStats {
    var score: Int = 0
    var bonusesCollected: Int = 0
    var obstaclesAvoided: Int = 0
    var dashesPerformed: Int = 0
    var jumpsPerformed: Int = 0
    var startTime: Date = Date()
    var endTime: Date?
    
    var duration: TimeInterval {
        let end = endTime ?? Date()
        return end.timeIntervalSince(startTime)
    }
}

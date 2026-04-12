import Foundation
import SpriteKit

enum LaneType: Int, CaseIterable {
    case slow = 0
    case inverted = 1
    case normal = 2
    case speed = 3
    
    var color: SKColor {
        switch self {
        case .normal: return .systemBlue
        case .speed: return .systemRed
        case .slow: return .systemGreen
        case .inverted: return .systemPurple
        }
    }
    
    var speedMultiplier: CGFloat {
        switch self {
        case .normal: return 1.0
        case .speed: return 1.5
        case .slow: return 0.6
        case .inverted: return 1.0
        }
    }
    
    var isInverted: Bool {
        return self == .inverted
    }
    
    static func laneOrder() -> [LaneType] {
        return [.slow, .inverted, .normal, .speed]
    }
}

struct Lane {
    let type: LaneType
    let yPosition: CGFloat
    let height: CGFloat
}

struct Obstacle {
    let position: CGPoint
    let size: CGSize
    let laneIndex: Int
}

struct Bonus {
    let position: CGPoint
    let laneIndex: Int
    var isCollected: Bool = false
}

enum GameState {
    case menu
    case playing
    case paused
    case gameOver
}

enum InputAction {
    case tap
    case doubleTap
    case longPress
    case none
}

struct GameConfig {
    static let numberOfLanes = 4
    static let baseSpeed: CGFloat = 200
    static let maxSpeed: CGFloat = 500
    static let speedIncreaseRate: CGFloat = 0.5
    static let ballRadius: CGFloat = 20
    static let obstacleWidth: CGFloat = 60
    static let obstacleHeight: CGFloat = 30
    static let bonusSize: CGFloat = 25
    static let rushDistance: CGFloat = 100
    static let jumpDuration: TimeInterval = 0.6
}

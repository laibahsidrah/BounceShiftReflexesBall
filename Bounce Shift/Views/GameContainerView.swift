import SwiftUI
import SpriteKit

struct GameContainerView: View {
    @StateObject private var viewModel = GameViewModel()
    
    var body: some View {
        ZStack {
            switch viewModel.gameState {
            case .menu:
                MainMenuView(viewModel: viewModel)
            case .playing, .paused:
                GameSceneView(viewModel: viewModel)
            case .gameOver:
                GameOverView(viewModel: viewModel)
            }
        }
        .onAppear {
            OrientationService.shared.lockToPortrait()
        }
    }
}

struct GameSceneView: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        ZStack {
            SpriteView(scene: createScene())
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Score: \(viewModel.score)")
                            .font(.title3.bold())
                            .foregroundColor(.white)
                        
                        HStack(spacing: 8) {
                            Text("Best: \(viewModel.highScore)")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.6))
                            
                            HStack(spacing: 3) {
                                Image(systemName: viewModel.selectedDifficulty.iconName)
                                    .font(.system(size: 9))
                                Text(viewModel.selectedDifficulty.name)
                                    .font(.system(size: 10, weight: .medium))
                            }
                            .foregroundColor(difficultyColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(difficultyColor.opacity(0.2))
                            )
                        }
                    }
                    .padding(.leading, 16)
                    
                    Spacer()
                    
                    VStack(spacing: 0) {
                        Text("x\(viewModel.scoreMultiplier)")
                            .font(.title2.bold())
                            .foregroundColor(viewModel.isRushing ? .orange : .yellow)
                        Text(viewModel.isRushing ? "RUSH!" : "Multiplier")
                            .font(.system(size: 9))
                            .foregroundColor(viewModel.isRushing ? .orange.opacity(0.8) : .white.opacity(0.4))
                    }
                    .frame(width: 65)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(viewModel.isRushing ? Color.orange.opacity(0.2) : Color.clear)
                    )
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.pauseGame()
                    }) {
                        Image(systemName: "pause.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Circle().fill(Color.black.opacity(0.3)))
                    }
                    .padding(.trailing, 16)
                }
                .padding(.top, 8)
                
                Spacer()
            }
            
            VStack {
                Spacer()
                HStack(spacing: 24) {
                    StatItem(icon: "star.fill", value: viewModel.currentSessionStats.bonusesCollected, label: "Bonus", color: .yellow)
                    
                    Rectangle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 1, height: 30)
                    
                    StatItem(icon: "arrow.up.circle.fill", value: viewModel.currentSessionStats.jumpsPerformed, label: "Jumps", color: .orange)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.7))
                )
                .padding(.bottom, 16)
            }
            
            if viewModel.gameState == .paused {
                PauseOverlay(viewModel: viewModel)
            }
        }
    }
    
    var difficultyColor: Color {
        switch viewModel.selectedDifficulty.color {
        case "green": return .green
        case "orange": return .orange
        case "red": return .red
        case "purple": return .purple
        default: return .blue
        }
    }
    
    private func createScene() -> SKScene {
        let scene = GameScene(viewModel: viewModel)
        scene.scaleMode = .resizeFill
        return scene
    }
}

struct StatItem: View {
    let icon: String
    let value: Int
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
            VStack(alignment: .leading, spacing: 0) {
                Text("\(value)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Text(label)
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
    }
}

struct PauseOverlay: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()
            
            VStack(spacing: 30) {
                Text("Paused")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                
                VStack(spacing: 8) {
                    Text("Score: \(viewModel.score)")
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 20) {
                        StatPill(icon: "star.fill", value: viewModel.currentSessionStats.bonusesCollected)
                        StatPill(icon: "arrow.right.circle.fill", value: viewModel.currentSessionStats.dashesPerformed)
                        StatPill(icon: "arrow.up.circle.fill", value: viewModel.currentSessionStats.jumpsPerformed)
                    }
                }
                
                Button(action: {
                    viewModel.resumeGame()
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Resume")
                    }
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 15)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.blue)
                    )
                }
                
                Button(action: {
                    viewModel.returnToMenu()
                }) {
                    HStack {
                        Image(systemName: "house.fill")
                        Text("Menu")
                    }
                    .font(.title3)
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white, lineWidth: 2)
                    )
                }
            }
        }
    }
}

struct StatPill: View {
    let icon: String
    let value: Int
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text("\(value)")
                .font(.caption.bold())
        }
        .foregroundColor(.white.opacity(0.8))
    }
}

struct GameOverView: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var showDetailedStats = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.purple.opacity(0.8), Color.black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 25) {
                    Text("Game Over")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(.white)
                    
                    DifficultyBadge(difficulty: viewModel.selectedDifficulty)
                    
                    VStack(spacing: 8) {
                        Text("\(viewModel.score)")
                            .font(.system(size: 56, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("SCORE")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        
                        if viewModel.score >= viewModel.highScore && viewModel.score > 0 {
                            HStack {
                                Image(systemName: "crown.fill")
                                Text("New High Score!")
                            }
                            .font(.headline)
                            .foregroundColor(.yellow)
                            .padding(.top, 4)
                        }
                    }
                    
                    VStack(spacing: 12) {
                        Text("Session Stats")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.8))
                        
                        HStack(spacing: 15) {
                            GameOverStatBox(
                                icon: "clock.fill",
                                title: "Time",
                                value: formatTime(viewModel.currentSessionStats.duration)
                            )
                            GameOverStatBox(
                                icon: "star.fill",
                                title: "Bonuses",
                                value: "\(viewModel.currentSessionStats.bonusesCollected)"
                            )
                        }
                        
                        HStack(spacing: 15) {
                            GameOverStatBox(
                                icon: "arrow.right.circle.fill",
                                title: "Dashes",
                                value: "\(viewModel.currentSessionStats.dashesPerformed)"
                            )
                            GameOverStatBox(
                                icon: "arrow.up.circle.fill",
                                title: "Jumps",
                                value: "\(viewModel.currentSessionStats.jumpsPerformed)"
                            )
                        }
                        
                        HStack(spacing: 15) {
                            GameOverStatBox(
                                icon: "xmark.octagon.fill",
                                title: "Avoided",
                                value: "\(viewModel.currentSessionStats.obstaclesAvoided)"
                            )
                            GameOverStatBox(
                                icon: "multiply.circle.fill",
                                title: "Multiplier",
                                value: "x\(viewModel.scoreMultiplier)"
                            )
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.1))
                    )
                    
                    if checkUnlockedNewLevel() {
                        UnlockBanner()
                    }
                    
                    VStack(spacing: 12) {
                        Button(action: {
                            viewModel.startGame()
                        }) {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Play Again")
                            }
                            .font(.title2.bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.blue)
                            )
                        }
                        
                        HStack(spacing: 12) {
                            Button(action: {
                                showDetailedStats = true
                            }) {
                                HStack {
                                    Image(systemName: "chart.bar.fill")
                                    Text("Stats")
                                }
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                                )
                            }
                            
                            Button(action: {
                                viewModel.returnToMenu()
                            }) {
                                HStack {
                                    Image(systemName: "house.fill")
                                    Text("Menu")
                                }
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding()
            }
        }
        .sheet(isPresented: $showDetailedStats) {
            AllStatsView(viewModel: viewModel)
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func checkUnlockedNewLevel() -> Bool {
        let score = viewModel.score
        let difficulty = viewModel.selectedDifficulty
        
        switch difficulty {
        case .easy:
            return score >= 500 && !viewModel.unlockedLevels.contains(.medium)
        case .medium:
            return score >= 1000 && !viewModel.unlockedLevels.contains(.hard)
        case .hard:
            return score >= 2000 && !viewModel.unlockedLevels.contains(.extreme)
        case .extreme:
            return false
        }
    }
}

struct GameOverStatBox: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.title3.bold())
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

struct UnlockBanner: View {
    var body: some View {
        HStack {
            Image(systemName: "lock.open.fill")
                .foregroundColor(.yellow)
            Text("New Level Unlocked!")
                .font(.headline)
                .foregroundColor(.yellow)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.yellow.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.yellow.opacity(0.5), lineWidth: 1)
                )
        )
    }
}

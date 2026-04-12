import SwiftUI

struct MainMenuView: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var animateTitle = false
    @State private var showHowToPlay = false
    @State private var showLevelSelect = false
    @State private var showStatistics = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            LanesBackground()
            
            VStack(spacing: 30) {
                Spacer()
                
                VStack(spacing: 10) {
                    Text("Bounce")
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Shift")
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.cyan, .purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                .scaleEffect(animateTitle ? 1.05 : 1.0)
                .animation(
                    .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                    value: animateTitle
                )
                
                DifficultyBadge(difficulty: viewModel.selectedDifficulty)
                
                if viewModel.highScore > 0 {
                    Text("Best: \(viewModel.highScore)")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                VStack(spacing: 16) {
                    Button(action: {
                        viewModel.startGame()
                    }) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Play")
                        }
                        .font(.title.bold())
                        .foregroundColor(.white)
                        .frame(width: 220)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .shadow(color: .purple.opacity(0.5), radius: 10, x: 0, y: 5)
                    }
                    
                    Button(action: {
                        showLevelSelect = true
                    }) {
                        HStack {
                            Image(systemName: "square.stack.3d.up.fill")
                            Text("Levels")
                        }
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 220)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.white.opacity(0.2))
                        )
                    }
                    
                    Button(action: {
                        showHowToPlay = true
                    }) {
                        HStack {
                            Image(systemName: "questionmark.circle")
                            Text("How to Play")
                        }
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .frame(width: 220)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.5), lineWidth: 1)
                        )
                    }
                    
                    Button(action: {
                        showStatistics = true
                    }) {
                        HStack {
                            Image(systemName: "chart.bar.fill")
                            Text("Statistics")
                        }
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .frame(width: 220)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.5), lineWidth: 1)
                        )
                    }
                    
                    Button(action: {
                        viewModel.toggleSound()
                    }) {
                        HStack {
                            Image(systemName: viewModel.isSoundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                            Text(viewModel.isSoundEnabled ? "Sound On" : "Sound Off")
                        }
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.top, 8)
                }
                
                Spacer()
            }
            .padding()
        }
        .onAppear {
            animateTitle = true
        }
        .sheet(isPresented: $showHowToPlay) {
            HowToPlayView()
        }
        .sheet(isPresented: $showLevelSelect) {
            LevelSelectView(viewModel: viewModel)
        }
        .sheet(isPresented: $showStatistics) {
            AllStatsView(viewModel: viewModel)
        }
    }
}

struct DifficultyBadge: View {
    let difficulty: Difficulty
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: difficulty.iconName)
                .font(.caption)
            Text(difficulty.name)
                .font(.caption.bold())
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(colorForDifficulty.opacity(0.8))
        )
    }
    
    var colorForDifficulty: Color {
        switch difficulty.color {
        case "green": return .green
        case "orange": return .orange
        case "red": return .red
        case "purple": return .purple
        default: return .blue
        }
    }
}

struct LanesBackground: View {
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                ForEach((0..<4).reversed(), id: \.self) { index in
                    Rectangle()
                        .fill(laneColor(for: index).opacity(0.15))
                        .frame(height: geometry.size.height / 4)
                }
            }
        }
    }
    
    private func laneColor(for index: Int) -> Color {
        switch index {
        case 0: return .green
        case 1: return .purple
        case 2: return .blue
        case 3: return .red
        default: return .blue
        }
    }
}

struct HowToPlayView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    Section {
                        Text("Control your ball through color-shifting lanes. Each lane changes the physics!")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    Section {
                        VStack(alignment: .leading, spacing: 15) {
                            LaneInfoRow(color: .blue, title: "Blue Lane", description: "Normal speed - standard gameplay", icon: "circle.fill")
                            LaneInfoRow(color: .red, title: "Red Lane", description: "Speed boost - everything moves faster!", icon: "hare.fill")
                            LaneInfoRow(color: .green, title: "Green Lane", description: "Slow down - take your time", icon: "tortoise.fill")
                            LaneInfoRow(color: .purple, title: "Purple Lane", description: "Inverted controls - up is down!", icon: "arrow.up.arrow.down")
                        }
                    } header: {
                        Text("Lanes")
                            .font(.headline)
                    }
                    
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            ControlInfoRow(
                                icon: "hand.tap",
                                title: "Tap",
                                description: "Change lane - tap above or below your ball to move"
                            )
                            ControlInfoRow(
                                icon: "hand.tap.fill",
                                title: "Double Tap",
                                description: "Jump - leap over obstacles without changing lanes"
                            )
                            ControlInfoRow(
                                icon: "hand.point.up.left.fill",
                                title: "Hold",
                                description: "Rush mode - move forward for x2 points, but closer to danger!"
                            )
                        }
                    } header: {
                        Text("Controls")
                            .font(.headline)
                    }
                    
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            TipRow(text: "Avoid red obstacles")
                            TipRow(text: "Collect yellow bonuses for 50 points")
                            TipRow(text: "Use rush mode to get x2 points")
                            TipRow(text: "Jump when you can't switch lanes in time")
                            TipRow(text: "Watch for purple lanes - controls flip!")
                            TipRow(text: "Speed increases over time - stay focused")
                        }
                    } header: {
                        Text("Tips")
                            .font(.headline)
                    }
                    
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            UnlockRow(level: "Medium", requirement: "Score 500 on Easy")
                            UnlockRow(level: "Hard", requirement: "Score 1000 on Medium")
                            UnlockRow(level: "Extreme", requirement: "Score 2000 on Hard")
                        }
                    } header: {
                        Text("Unlock Levels")
                            .font(.headline)
                    }
                }
                .padding()
            }
            .navigationTitle("How to Play")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct LaneInfoRow: View {
    let color: Color
    let title: String
    let description: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct ControlInfoRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct TipRow: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "lightbulb.fill")
                .font(.caption)
                .foregroundColor(.yellow)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

struct UnlockRow: View {
    let level: String
    let requirement: String
    
    var body: some View {
        HStack {
            Image(systemName: "lock.open.fill")
                .font(.caption)
                .foregroundColor(.green)
            Text(level)
                .font(.subheadline.bold())
            Text("→")
                .foregroundColor(.secondary)
            Text(requirement)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

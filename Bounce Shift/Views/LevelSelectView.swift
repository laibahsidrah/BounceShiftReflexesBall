import SwiftUI

struct LevelSelectView: View {
    @ObservedObject var viewModel: GameViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(Difficulty.allCases, id: \.rawValue) { difficulty in
                        LevelCard(
                            difficulty: difficulty,
                            isSelected: viewModel.selectedDifficulty == difficulty,
                            isUnlocked: viewModel.isLevelUnlocked(difficulty),
                            unlockRequirement: viewModel.getUnlockRequirement(for: difficulty),
                            statistics: viewModel.getStatistics(for: difficulty),
                            onSelect: {
                                viewModel.selectDifficulty(difficulty)
                            }
                        )
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Select Level")
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

struct LevelCard: View {
    let difficulty: Difficulty
    let isSelected: Bool
    let isUnlocked: Bool
    let unlockRequirement: String
    let statistics: LevelStatistics
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: {
            if isUnlocked {
                onSelect()
            }
        }) {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: difficulty.iconName)
                        .font(.title)
                        .foregroundColor(colorForDifficulty)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(difficulty.name)
                            .font(.title2.bold())
                            .foregroundColor(isUnlocked ? .primary : .secondary)
                        
                        Text(difficulty.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if isSelected && isUnlocked {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    } else if !isUnlocked {
                        Image(systemName: "lock.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                
                if isUnlocked {
                    Divider()
                    
                    StatisticsSection(statistics: statistics, difficulty: difficulty)
                        .padding()
                } else {
                    Divider()
                    
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.orange)
                        Text(unlockRequirement)
                            .font(.subheadline)
                            .foregroundColor(.orange)
                    }
                    .padding()
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected && isUnlocked ? Color.blue : Color.clear, lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .opacity(isUnlocked ? 1 : 0.7)
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

struct StatisticsSection: View {
    let statistics: LevelStatistics
    let difficulty: Difficulty
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                StatBox(title: "Games", value: "\(statistics.gamesPlayed)", icon: "gamecontroller.fill")
                StatBox(title: "High Score", value: "\(statistics.highScore)", icon: "trophy.fill")
                StatBox(title: "Avg Score", value: "\(statistics.averageScore)", icon: "chart.bar.fill")
            }
            
            HStack {
                StatBox(title: "Bonuses", value: "\(statistics.totalBonusesCollected)", icon: "star.fill")
                StatBox(title: "Dashes", value: "\(statistics.totalDashes)", icon: "arrow.right.circle.fill")
                StatBox(title: "Jumps", value: "\(statistics.totalJumps)", icon: "arrow.up.circle.fill")
            }
            
            HStack {
                StatBox(title: "Best Time", value: formatTime(statistics.bestTime), icon: "clock.fill")
                StatBox(title: "Total Time", value: formatTime(statistics.totalTimePlayed), icon: "hourglass")
                StatBox(title: "Multiplier", value: "x\(LevelConfig.config(for: difficulty).scoreMultiplier)", icon: "multiply.circle.fill")
            }
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
    }
}

struct AllStatsView: View {
    @ObservedObject var viewModel: GameViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Overall Statistics") {
                    let total = viewModel.getTotalStatistics()
                    
                    StatRow(title: "Total Games", value: "\(total.gamesPlayed)")
                    StatRow(title: "Total Score", value: "\(total.totalScore)")
                    StatRow(title: "Best Score", value: "\(total.highScore)")
                    StatRow(title: "Total Bonuses", value: "\(total.totalBonusesCollected)")
                    StatRow(title: "Total Dashes", value: "\(total.totalDashes)")
                    StatRow(title: "Total Jumps", value: "\(total.totalJumps)")
                    StatRow(title: "Total Play Time", value: formatTime(total.totalTimePlayed))
                    StatRow(title: "Best Survival Time", value: formatTime(total.bestTime))
                }
                
                ForEach(Difficulty.allCases, id: \.rawValue) { difficulty in
                    if viewModel.isLevelUnlocked(difficulty) {
                        let stats = viewModel.getStatistics(for: difficulty)
                        
                        Section("\(difficulty.name) Level") {
                            StatRow(title: "Games Played", value: "\(stats.gamesPlayed)")
                            StatRow(title: "High Score", value: "\(stats.highScore)")
                            StatRow(title: "Average Score", value: "\(stats.averageScore)")
                            StatRow(title: "Bonuses Collected", value: "\(stats.totalBonusesCollected)")
                            StatRow(title: "Dashes Used", value: "\(stats.totalDashes)")
                            StatRow(title: "Jumps Used", value: "\(stats.totalJumps)")
                            StatRow(title: "Best Time", value: formatTime(stats.bestTime))
                            StatRow(title: "Avg Time", value: formatTime(stats.averageTime))
                            
                            if let lastPlayed = stats.lastPlayed {
                                StatRow(title: "Last Played", value: formatDate(lastPlayed))
                            }
                        }
                    }
                }
            }
            .navigationTitle("Statistics")
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
    
    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60
        
        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

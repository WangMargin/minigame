import SwiftUI

// MARK: - 单个游戏卡片
struct GameCardView: View {
    let gameType: GameType
    var highScore: Int?

    var body: some View {
        HStack(spacing: 16) {
            // 左侧图标
            ZStack {
                Circle()
                    .fill(gameType.backgroundColor.opacity(0.25))
                    .frame(width: 72, height: 72)

                Image(systemName: gameType.icon)
                    .font(.system(size: 36))
                    .foregroundColor(gameType.backgroundColor)
            }

            // 右侧文字
            VStack(alignment: .leading, spacing: 6) {
                Text(gameType.title)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text(gameType.description)
                    .font(.system(size: 15, design: .rounded))
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                if let score = highScore {
                    HStack(spacing: 4) {
                        Image(systemName: "trophy.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text("最高分: \(score)")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(.orange)
                    }
                    .padding(.top, 2)
                }
            }

            Spacer()

            Image(systemName: "chevron.right.circle.fill")
                .font(.system(size: 28))
                .foregroundColor(gameType.backgroundColor.opacity(0.6))
        }
        .padding(20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
        .contentShape(RoundedRectangle(cornerRadius: 22))
    }
}

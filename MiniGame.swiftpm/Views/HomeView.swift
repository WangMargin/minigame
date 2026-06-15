import SwiftUI

// MARK: - 主页 — 游戏选择 + 年龄切换
struct HomeView: View {
    var onSelectGame: (GameType) -> Void
    var onOpenParentZone: () -> Void
    @EnvironmentObject var gameVM: GameViewModel

    private let columns = [
        GridItem(.adaptive(minimum: 260, maximum: 380), spacing: 20)
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: AgeAdaptiveHelper.backgroundGradient(for: gameVM.selectedAgeGroup),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // 顶部区域
                headerSection
                    .padding(.horizontal, 28)
                    .padding(.top, 20)

                // 年龄选择器
                ageSelector
                    .padding(.horizontal, 28)
                    .padding(.top, 16)

                // 统计栏
                statsBar
                    .padding(.horizontal, 28)
                    .padding(.top, 12)

                // 游戏卡片列表
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        // 可用游戏
                        availableGamesSection
                            .padding(.top, 16)

                        // 不可用游戏 (年龄不够)
                        if lockedGames.count > 0 {
                            lockedGamesSection
                                .padding(.top, 20)
                        }
                    }
                    .padding(.horizontal, 28)
                    .padding(.bottom, 30)
                }

                // 底部家长区入口
                parentZoneButton
                    .padding(.horizontal, 28)
                    .padding(.bottom, 12)
            }
        }
        .overlay(alignment: .top) {
            // 时间超限提醒
            if gameVM.isTimeLimitExceeded {
                timeLimitBanner
            }
        }
        .animation(.easeInOut, value: gameVM.selectedAgeGroup)
    }

    // MARK: - 顶部标题
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\u{1F3AE} 小天才乐园")
                    .font(.system(
                        size: AgeAdaptiveHelper.titleFontSize(for: gameVM.selectedAgeGroup),
                        weight: .bold, design: .rounded
                    ))
                    .foregroundColor(.purple)

                Text(gameVM.selectedAgeGroup.description)
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.gray)
            }
            Spacer()

            // 时间环
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 6)
                    .frame(width: 52, height: 52)

                Circle()
                    .trim(from: 0, to: min(gameVM.todayPlayTime / gameVM.dailyTimeLimit, 1.0))
                    .stroke(
                        gameVM.todayPlayTime > gameVM.dailyTimeLimit * 0.8 ? Color.orange : Color.green,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 52, height: 52)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear, value: gameVM.todayPlayTime)

                Text("\(Int(gameVM.todayPlayTime / 60))m")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
        }
    }

    // MARK: - 年龄选择器
    private var ageSelector: some View {
        HStack(spacing: 0) {
            ForEach(AgeGroup.allCases) { age in
                Button {
                    withAnimation(.spring(response: 0.35)) {
                        gameVM.selectedAgeGroup = age
                    }
                } label: {
                    VStack(spacing: 4) {
                        Text(age.emoji)
                            .font(.title2)
                        Text(age.displayName)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(gameVM.selectedAgeGroup == age
                                  ? Color.white
                                  : Color.clear)
                            .shadow(color: gameVM.selectedAgeGroup == age
                                    ? .black.opacity(0.06) : .clear,
                                    radius: 4, y: 2)
                    )
                    .foregroundColor(
                        gameVM.selectedAgeGroup == age ? .purple : .gray
                    )
                }
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
        )
    }

    // MARK: - 统计栏
    private var statsBar: some View {
        HStack(spacing: 20) {
            statItem(icon: "star.fill", color: .yellow, text: "\(gameVM.totalStars) 星")
            statItem(icon: "gamecontroller.fill", color: .blue, text: "\(gameVM.gamesPlayed) 次")
            Spacer()
            statItem(icon: "clock.fill", color: .orange,
                     text: "\(Int(gameVM.todayPlayTime / 60)) 分钟")
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 18)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func statItem(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.subheadline)
            Text(text)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
        }
    }

    // MARK: - 可用游戏区
    private var availableGamesSection: some View {
        LazyVGrid(columns: columns, spacing: 18) {
            ForEach(GameType.allCases.filter(gameVM.isGameAvailable)) { game in
                EnhancedGameCard(
                    gameType: game,
                    highScore: gameVM.highScores[game],
                    playCount: gameVM.gamePlayCount[game],
                    age: gameVM.selectedAgeGroup,
                    onTap: { onSelectGame(game) }
                )
            }
        }
    }

    // MARK: - 锁定游戏区
    private var lockedGames: [GameType] {
        GameType.allCases.filter { !gameVM.isGameAvailable($0) }
    }

    private var lockedGamesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\u{1F512} 长大一点再来玩")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.gray)

            LazyVGrid(columns: columns, spacing: 18) {
                ForEach(lockedGames) { game in
                    LockedGameCard(gameType: game)
                }
            }
        }
    }

    // MARK: - 家长中心按钮
    private var parentZoneButton: some View {
        Button(action: onOpenParentZone) {
            HStack(spacing: 8) {
                Image(systemName: "lock.shield.fill")
                    .font(.title3)
                Text("家长中心")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                Capsule().fill(
                    LinearGradient(
                        colors: [Color.purple.opacity(0.7), Color.blue.opacity(0.7)],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
            )
        }
    }

    // MARK: - 时间超限横幅
    private var timeLimitBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "hourglass.tophalf.filled")
            Text("今天的游戏时间到啦！让眼睛休息一下吧～")
                .font(.system(size: 15, weight: .medium, design: .rounded))
        }
        .foregroundColor(.white)
        .padding(.vertical, 14)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(Color.orange)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

// MARK: - 增强游戏卡片
struct EnhancedGameCard: View {
    let gameType: GameType
    var highScore: Int?
    var playCount: Int?
    var age: AgeGroup
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // 图标
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(gameType.backgroundColor.opacity(0.2))
                        .frame(width: 64, height: 64)

                    Image(systemName: gameType.icon)
                        .font(.system(size: AgeAdaptiveHelper.iconSize(for: age) * 0.55))
                        .foregroundColor(gameType.backgroundColor)
                }

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 8) {
                        Text(gameType.title)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)

                        Text(gameType.category.rawValue)
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(gameType.backgroundColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                Capsule().fill(gameType.backgroundColor.opacity(0.15))
                            )
                    }

                    Text(gameType.description(for: age))
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(.secondary)
                        .lineLimit(2)

                    // 统计小标签
                    HStack(spacing: 12) {
                        if let score = highScore {
                            Label("\(score)", systemImage: "trophy.fill")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.orange)
                        }
                        if let count = playCount {
                            Label("\(count)次", systemImage: "play.fill")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.blue)
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right.circle.fill")
                    .font(.title3)
                    .foregroundColor(gameType.backgroundColor.opacity(0.5))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(.regularMaterial)
                    .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 锁定游戏卡片
struct LockedGameCard: View {
    let gameType: GameType

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.gray.opacity(0.12))
                    .frame(width: 64, height: 64)

                Image(systemName: gameType.icon)
                    .font(.system(size: 28))
                    .foregroundColor(.gray.opacity(0.4))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(gameType.title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.gray.opacity(0.6))
                Text("适合 \(gameType.minimumAge.displayName) 以上")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(.gray.opacity(0.5))
            }

            Spacer()

            Image(systemName: "lock.fill")
                .foregroundColor(.gray.opacity(0.4))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(.regularMaterial)
                .opacity(0.6)
        )
    }
}

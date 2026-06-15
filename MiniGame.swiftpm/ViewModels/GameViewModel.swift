import SwiftUI
import Combine

// MARK: - 全局游戏状态管理
class GameViewModel: ObservableObject {
    // MARK: 年龄设置
    @Published var selectedAgeGroup: AgeGroup = .child {
        didSet { saveSettings() }
    }

    // MARK: 游戏统计
    @Published var totalStars: Int = 0
    @Published var gamesPlayed: Int = 0
    @Published var highScores: [GameType: Int] = [:]
    @Published var gamePlayCount: [GameType: Int] = [:]
    @Published var todayPlayTime: TimeInterval = 0

    // MARK: 家长控制
    @Published var dailyTimeLimit: TimeInterval = 45 * 60  // 默认45分钟
    @Published var isTimeLimitExceeded: Bool = false
    @Published var showParentZone: Bool = false
    @Published var parentGatePassed: Bool = false

    // MARK: 音效
    @Published var soundEnabled: Bool = true
    @Published var voiceGuideEnabled: Bool = true

    private var sessionStartTime: Date?
    private var timerCancellable: AnyCancellable?

    init() {
        loadSettings()
        startSession()
    }

    // MARK: - 游戏操作
    func addStars(_ count: Int) {
        totalStars += count
    }

    func recordGamePlayed(for game: GameType) {
        gamesPlayed += 1
        gamePlayCount[game, default: 0] += 1
    }

    func updateHighScore(for game: GameType, score: Int) {
        let current = highScores[game] ?? 0
        if score > current {
            highScores[game] = score
        }
    }

    // MARK: - 年龄段适配
    func isGameAvailable(_ game: GameType) -> Bool {
        return ageGroupOrder(game.minimumAge) <= ageGroupOrder(selectedAgeGroup)
    }

    private func ageGroupOrder(_ group: AgeGroup) -> Int {
        switch group {
        case .toddler: return 0
        case .child:   return 1
        case .preteen: return 2
        }
    }

    // MARK: - 时间管理
    func startSession() {
        sessionStartTime = Date()
        timerCancellable = Timer.publish(every: 10, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkTimeLimit()
            }
    }

    func checkTimeLimit() {
        guard let start = sessionStartTime else { return }
        todayPlayTime = Date().timeIntervalSince(start)
        if todayPlayTime >= dailyTimeLimit {
            isTimeLimitExceeded = true
        }
    }

    func resetTimeLimit() {
        sessionStartTime = Date()
        todayPlayTime = 0
        isTimeLimitExceeded = false
    }

    // MARK: - 家长验证
    func verifyParentGate(answer: Int) -> Bool {
        // 简单算术验证：让家长做一道乘法题
        let correct = 7 * 8  // 56
        if answer == correct {
            parentGatePassed = true
            return true
        }
        return false
    }

    func resetParentGate() {
        parentGatePassed = false
    }

    // MARK: - 持久化
    private func saveSettings() {
        UserDefaults.standard.set(selectedAgeGroup.rawValue, forKey: "ageGroup")
    }

    private func loadSettings() {
        if let raw = UserDefaults.standard.string(forKey: "ageGroup"),
           let age = AgeGroup(rawValue: raw) {
            selectedAgeGroup = age
        }
    }
}

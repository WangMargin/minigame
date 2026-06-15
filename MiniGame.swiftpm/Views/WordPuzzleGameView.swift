import SwiftUI

// MARK: - 单词拼图游戏 (6-12岁)
struct WordPuzzleGameView: View {
    let onBack: () -> Void
    @EnvironmentObject var gameVM: GameViewModel
    @State private var currentPuzzle: WordPuzzleData?
    @State private var selectedLetters: [Int] = []
    @State private var availableLetters: [LetterTile] = []
    @State private var score: Int = 0
    @State private var round: Int = 0
    @State private var starsEarned: Int = 0
    @State private var showFeedback: Bool = false
    @State private var isCorrect: Bool = false
    @State private var feedbackMessage: String = ""

    private var age: AgeGroup { gameVM.selectedAgeGroup }
    private var puzzlePool: [WordPuzzleData] {
        WordPuzzleData.pool(for: age)
    }
    private let maxRounds = 8

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.72, green: 0.88, blue: 0.96),
                         Color(red: 0.85, green: 0.95, blue: 0.98)],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 24)

                Spacer()

                if let puzzle = currentPuzzle {
                    hintSection(puzzle)
                        .padding(.bottom, 20)

                    answerSlots
                        .padding(.horizontal, 40)
                        .padding(.bottom, 28)

                    letterTiles
                        .padding(.horizontal, 40)
                }

                Spacer()

                // 操作按钮
                HStack(spacing: 24) {
                    Button(action: clearSelection) {
                        Label("清除", systemImage: "delete.left.fill")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .background(Capsule().fill(.gray))
                    }

                    Button(action: submitAnswer) {
                        Label("确认", systemImage: "checkmark")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .background(Capsule().fill(.cyan))
                    }
                    .disabled(selectedLetters.isEmpty)
                }
                .padding(.bottom, 24)
            }

            if showFeedback {
                feedbackOverlay
            }
        }
        .onAppear(perform: generateNewPuzzle)
        .navigationBarHidden(true)
    }

    // MARK: 顶栏
    private var topBar: some View {
        HStack {
            Button(action: {
                gameVM.addStars(starsEarned)
                gameVM.recordGamePlayed(for: .wordPuzzle)
                gameVM.updateHighScore(for: .wordPuzzle, score: score)
                onBack()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left.circle.fill").font(.title)
                    Text("返回主页")
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                }
                .foregroundColor(.cyan)
            }

            Spacer()

            HStack(spacing: 8) {
                Image(systemName: "star.fill").foregroundColor(.yellow).font(.title2)
                Text("\(score)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.cyan)
            }

            Spacer()

            Text("\(round + 1)/\(maxRounds)")
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundColor(.cyan.opacity(0.7))
        }
        .padding(.top, 16)
    }

    // MARK: 提示区
    private func hintSection(_ puzzle: WordPuzzleData) -> some View {
        VStack(spacing: 8) {
            Text(puzzle.emoji)
                .font(.system(size: 64))

            Text(puzzle.hint)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.cyan)

            Text("把字母排成正确的单词吧！")
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(.gray)
        }
    }

    // MARK: 答案拼写槽位
    private var answerSlots: some View {
        let wordLength = currentPuzzle?.word.count ?? 0

        return HStack(spacing: 12) {
            ForEach(0..<wordLength, id: \.self) { index in
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.white.opacity(0.9))
                        .frame(width: 50, height: 60)
                        .shadow(color: .black.opacity(0.05), radius: 3, y: 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(
                                    selectedLetters.count > index
                                        ? Color.cyan.opacity(0.6) : Color.gray.opacity(0.2),
                                    lineWidth: 2
                                )
                        )

                    if selectedLetters.count > index {
                        Text(String(availableLetters[selectedLetters[index]].char))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.cyan)
                    }
                }
            }
        }
    }

    // MARK: 字母选择区
    private var letterTiles: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 50, maximum: 60), spacing: 16)],
            spacing: 16
        ) {
            ForEach(Array(availableLetters.enumerated()), id: \.offset) { index, tile in
                if !tile.isUsed {
                    Button {
                        selectLetter(at: index)
                    } label: {
                        Text(String(tile.char))
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .frame(width: 56, height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(.white)
                                    .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                            )
                            .foregroundColor(.cyan)
                    }
                } else {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.clear)
                        .frame(width: 56, height: 56)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
    }

    // MARK: 反馈浮层
    private var feedbackOverlay: some View {
        VStack(spacing: 16) {
            Image(systemName: isCorrect ? "sparkles" : "lightbulb.fill")
                .font(.system(size: 60))
                .foregroundColor(isCorrect ? .green : .yellow)

            Text(feedbackMessage)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundColor(isCorrect ? .green : .orange)

            if isCorrect {
                HStack(spacing: 4) {
                    ForEach(0..<starsEarned, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.title)
                            .foregroundColor(.yellow)
                    }
                }
            }
        }
        .padding(36)
        .background(RoundedRectangle(cornerRadius: 30).fill(.ultraThinMaterial))
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: 游戏逻辑
    private func generateNewPuzzle() {
        selectedLetters = []
        showFeedback = false

        guard round < maxRounds else {
            gameVM.addStars(starsEarned)
            gameVM.recordGamePlayed(for: .wordPuzzle)
            gameVM.updateHighScore(for: .wordPuzzle, score: score)
            return
        }

        currentPuzzle = puzzlePool.randomElement()!
        availableLetters = currentPuzzle!.scrambled.map {
            LetterTile(char: $0)
        }
    }

    private func selectLetter(at index: Int) {
        guard !showFeedback,
              selectedLetters.count < (currentPuzzle?.word.count ?? 0),
              !availableLetters[index].isUsed else { return }

        selectedLetters.append(index)
        availableLetters[index].isUsed = true
    }

    private func clearSelection() {
        guard !showFeedback else { return }
        for idx in selectedLetters {
            availableLetters[idx].isUsed = false
        }
        selectedLetters = []
    }

    private func submitAnswer() {
        guard let puzzle = currentPuzzle else { return }

        let formed = String(selectedLetters.map { availableLetters[$0].char })
        let correct = puzzle.word.uppercased()

        if formed == correct {
            isCorrect = true
            score += AgeAdaptiveHelper.scoreMultiplier(for: age)
            starsEarned += 1
            feedbackMessage = "太厉害了！\u{1F389}"
        } else {
            isCorrect = false
            feedbackMessage = "答案是 \(puzzle.word)"
            selectedLetters = []
            for i in availableLetters.indices {
                availableLetters[i].isUsed = false
            }
        }

        showFeedback = true
        round += 1

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                generateNewPuzzle()
            }
        }
    }
}

// MARK: - 模型
struct LetterTile {
    let char: Character
    var isUsed: Bool = false
}

struct WordPuzzleData {
    let word: String
    let hint: String
    let emoji: String
    var scrambled: [Character] {
        var chars = Array(word.uppercased())
        repeat {
            chars.shuffle()
        } while String(chars) == word.uppercased() && word.count > 1
        return chars
    }

    static func pool(for age: AgeGroup) -> [WordPuzzleData] {
        switch age {
        case .child:
            return [
                WordPuzzleData(word: "CAT", hint: "喵喵叫的小动物", emoji: "\u{1F431}"),
                WordPuzzleData(word: "DOG", hint: "汪汪叫的好朋友", emoji: "\u{1F436}"),
                WordPuzzleData(word: "SUN", hint: "天上的发光体", emoji: "\u{2600}\u{FE0F}"),
                WordPuzzleData(word: "FISH", hint: "在水里游", emoji: "\u{1F41F}"),
                WordPuzzleData(word: "BIRD", hint: "会飞的小动物", emoji: "\u{1F426}"),
                WordPuzzleData(word: "BOOK", hint: "用来读的", emoji: "\u{1F4D6}"),
                WordPuzzleData(word: "STAR", hint: "夜空中一闪一闪", emoji: "\u{2B50}"),
                WordPuzzleData(word: "TREE", hint: "公园里有很多", emoji: "\u{1F333}"),
                WordPuzzleData(word: "MOON", hint: "晚上在天上", emoji: "\u{1F319}"),
                WordPuzzleData(word: "RAIN", hint: "从云里掉下来的水", emoji: "\u{1F327}\u{FE0F}"),
            ]
        case .preteen:
            return [
                WordPuzzleData(word: "APPLE", hint: "一种红色或绿色的水果", emoji: "\u{1F34E}"),
                WordPuzzleData(word: "HOUSE", hint: "我们住在里面", emoji: "\u{1F3E0}"),
                WordPuzzleData(word: "WATER", hint: "生命之源", emoji: "\u{1F4A7}"),
                WordPuzzleData(word: "MUSIC", hint: "用耳朵听的艺术", emoji: "\u{1F3B5}"),
                WordPuzzleData(word: "PLANE", hint: "在天上飞的交通工具", emoji: "\u{2708}\u{FE0F}"),
                WordPuzzleData(word: "HAPPY", hint: "开心的心情", emoji: "\u{1F60A}"),
                WordPuzzleData(word: "DREAM", hint: "睡觉时脑海里的事", emoji: "\u{1F4AD}"),
                WordPuzzleData(word: "LIGHT", hint: "照亮黑暗的东西", emoji: "\u{1F4A1}"),
                WordPuzzleData(word: "OCEAN", hint: "很大很大的海", emoji: "\u{1F30A}"),
                WordPuzzleData(word: "TIGER", hint: "森林里的条纹大猫", emoji: "\u{1F42F}"),
                WordPuzzleData(word: "EARTH", hint: "我们生活的星球", emoji: "\u{1F30D}"),
                WordPuzzleData(word: "SMILE", hint: "开心时的表情", emoji: "\u{1F604}"),
            ]
        default: return []
        }
    }
}

import SwiftUI

// MARK: - 数学启蒙游戏 (3-12岁自适应)
struct MathGameView: View {
    let onBack: () -> Void
    @EnvironmentObject var gameVM: GameViewModel
    @State private var currentQuestion: MathQuestion?
    @State private var score: Int = 0
    @State private var round: Int = 0
    @State private var showFeedback: Bool = false
    @State private var isCorrect: Bool = false
    @State private var feedbackMessage: String = ""
    @State private var starsEarned: Int = 0
    @State private var selectedAnswer: Int?

    private var age: AgeGroup { gameVM.selectedAgeGroup }

    private var maxRounds: Int {
        switch age { case .toddler: return 6; case .child: return 8; case .preteen: return 10 }
    }

    private var maxCount: Int {
        switch age { case .toddler: return 5; case .child: return 10; case .preteen: return 20 }
    }

    private var includeOperations: Bool {
        age != .toddler
    }

    private var operationChance: Double {
        switch age { case .child: return 0.3; case .preteen: return 0.5; default: return 0 }
    }

    private let emojiOptions = ["\u{1F34E}","\u{1F31F}","\u{1F41F}","\u{1F338}","\u{1F388}","\u{1F36A}","\u{1F98B}","\u{1F3B5}","\u{1F424}","\u{1F353}","\u{1F680}","\u{1F420}"]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.7, green: 0.92, blue: 0.7),
                         Color(red: 0.88, green: 0.97, blue: 0.82)],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()

            VStack(spacing: 0) {
                topBar.padding(.horizontal, 24)
                Spacer()

                if let question = currentQuestion {
                    countingObjectsView(question).padding(.bottom, 16)

                    questionText(question)
                        .font(.system(size: AgeAdaptiveHelper.bodyFontSize(for: age),
                                      weight: .bold, design: .rounded))
                        .foregroundColor(.green)
                        .padding(.bottom, 24)

                    answerGrid(question).padding(.horizontal, 50)
                }
                Spacer()
            }
            if showFeedback { feedbackOverlay }
        }
        .onAppear(perform: generateNewRound)
        .onChange(of: gameVM.selectedAgeGroup) { _ in
            score = 0; round = 0; starsEarned = 0
            generateNewRound()
        }
        .navigationBarHidden(true)
    }

    private var topBar: some View {
        HStack {
            Button(action: {
                gameVM.addStars(starsEarned)
                gameVM.recordGamePlayed(for: .mathFun)
                gameVM.updateHighScore(for: .mathFun, score: score)
                onBack()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left.circle.fill").font(.title)
                    Text("返回主页")
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                }.foregroundColor(.green)
            }
            Spacer()
            HStack(spacing: 8) {
                Image(systemName: "star.fill").foregroundColor(.yellow).font(.title2)
                Text("\(score)").font(.system(size: 24, weight: .bold, design: .rounded)).foregroundColor(.green)
            }
            Spacer()
            Text("\(round + 1)/\(maxRounds)")
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundColor(.green.opacity(0.7))
        }.padding(.top, 16)
    }

    private func countingObjectsView(_ question: MathQuestion) -> some View {
        VStack(spacing: 8) {
            let displayCount: Int
            if let op = question.operationSymbol, let second = question.secondCount {
                displayCount = op == "+" ? question.objectCount + second : question.objectCount
            } else {
                displayCount = question.objectCount
            }
            let capped = min(displayCount, 24)
            let perRow = min(6, max(3, capped))
            let rows = max(1, (capped + perRow - 1) / perRow)

            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(0..<min(perRow, capped - row * perRow), id: \.self) { _ in
                        Text(question.emoji)
                            .font(.system(size: age == .toddler ? 48 : age == .child ? 40 : 34))
                    }
                }
            }
        }
        .padding(24)
        .background(RoundedRectangle(cornerRadius: 24).fill(.white.opacity(0.8)).shadow(color: .black.opacity(0.06), radius: 8, y: 4))
    }

    private func questionText(_ question: MathQuestion) -> Text {
        if let op = question.operationSymbol, let second = question.secondCount {
            return Text("\(question.objectCount) \(op) \(second) = ?")
        } else {
            return Text("有多少个？")
        }
    }

    private var answerGrid: (MathQuestion) -> some View {
        { question in
            let cols = [GridItem(.flexible()), GridItem(.flexible())]
            return LazyVGrid(columns: cols, spacing: 16) {
                ForEach(question.options, id: \.self) { option in
                    Button {
                        guard !showFeedback else { return }
                        selectedAnswer = option
                        checkAnswer(option)
                    } label: {
                        Text("\(option)")
                            .font(.system(size: AgeAdaptiveHelper.titleFontSize(for: age) * 0.9,
                                          weight: .bold, design: .rounded))
                            .foregroundColor(
                                selectedAnswer == option && showFeedback
                                    ? (isCorrect ? .white : .red.opacity(0.6)) : .green
                            )
                            .frame(maxWidth: .infinity)
                            .frame(height: 90)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(
                                        selectedAnswer == option && showFeedback
                                            ? (isCorrect ? Color.green : Color.red.opacity(0.15))
                                            : Color.white.opacity(0.85)
                                    )
                                    .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
                            )
                    }
                    .disabled(showFeedback)
                }
            }
        }
    }

    private var feedbackOverlay: some View {
        VStack(spacing: 16) {
            Image(systemName: isCorrect ? "hands.sparkles.fill" : "heart.fill")
                .font(.system(size: 56))
                .foregroundColor(isCorrect ? .green : .pink)
            Text(feedbackMessage)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundColor(isCorrect ? .green : .pink)
            HStack(spacing: 4) {
                ForEach(0..<starsEarned, id: \.self) { _ in
                    Image(systemName: "star.fill").font(.title).foregroundColor(.yellow)
                }
            }
        }
        .padding(36)
        .background(RoundedRectangle(cornerRadius: 30).fill(.ultraThinMaterial))
    }

    private func generateNewRound() {
        selectedAnswer = nil; showFeedback = false
        guard round < maxRounds else {
            gameVM.addStars(starsEarned)
            gameVM.recordGamePlayed(for: .mathFun)
            gameVM.updateHighScore(for: .mathFun, score: score)
            return
        }
        let emoji = emojiOptions.randomElement()!

        // 是否出运算题
        if includeOperations && Double.random(in: 0...1) < operationChance {
            let useAdd = Bool.random()
            let a = Int.random(in: 1...(maxCount / 2))
            let b = Int.random(in: 1...(maxCount / 2))
            let correct = useAdd ? a + b : max(a, b) - min(a, b)
            let maxVal = max(a, b) + maxCount / 2

            var opts = Set<Int>([correct])
            while opts.count < 4 {
                let n = Int.random(in: 0...maxVal)
                if n > 0 && !opts.contains(n) { opts.insert(n) }
            }
            currentQuestion = MathQuestion(
                objectCount: a, emoji: emoji,
                correctAnswer: correct, options: Array(opts).shuffled(),
                operationSymbol: useAdd ? "+" : "-",
                secondCount: b
            )
        } else {
            let count = Int.random(in: 1...maxCount)
            var opts = Set<Int>([count])
            let range = maxCount + 3
            while opts.count < 4 {
                let n = Int.random(in: 1...range)
                if !opts.contains(n) { opts.insert(n) }
            }
            currentQuestion = MathQuestion(
                objectCount: count, emoji: emoji,
                correctAnswer: count, options: Array(opts).shuffled(),
                operationSymbol: nil, secondCount: nil
            )
        }
    }

    private func checkAnswer(_ answer: Int) {
        guard let question = currentQuestion else { return }
        if answer == question.correctAnswer {
            isCorrect = true
            score += AgeAdaptiveHelper.scoreMultiplier(for: age)
            starsEarned += 1
            feedbackMessage = "答对啦！\u{1F389}"
            AudioManager.shared.play(.correct)
        } else {
            isCorrect = false
            feedbackMessage = "答案是 \(question.correctAnswer) 哦～"
        }
        showFeedback = true; round += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + AgeAdaptiveHelper.feedbackDuration(for: age)) {
            withAnimation(.easeInOut(duration: 0.3)) { generateNewRound() }
        }
    }
}

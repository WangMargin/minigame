import SwiftUI

// MARK: - 形状匹配游戏 (3-12岁自适应)
struct ShapeMatchGameView: View {
    let onBack: () -> Void
    @EnvironmentObject var gameVM: GameViewModel
    @State private var currentShape: ShapeOption = ShapeMatchGameView.shapePool.randomElement()!
    @State private var options: [ShapeOption] = []
    @State private var score: Int = 0
    @State private var round: Int = 0
    @State private var feedbackMessage: String = ""
    @State private var showFeedback: Bool = false
    @State private var isCorrect: Bool = false
    @State private var starsEarned: Int = 0

    private var age: AgeGroup { gameVM.selectedAgeGroup }

    private var maxRounds: Int {
        switch age { case .toddler: return 4; case .child: return 6; case .preteen: return 8 }
    }

    private var optionCount: Int {
        switch age { case .toddler: return 3; case .child: return 4; case .preteen: return 4 }
    }

    private var activePool: [ShapeOption] {
        switch age {
        case .toddler:
            return Self.shapePool.filter { ["circle.fill","square.fill","triangle.fill","heart.fill"].contains($0.systemImage) }
        case .child:
            return Self.shapePool
        case .preteen:
            return Self.shapePool + Self.advancedShapes
        }
    }

    static let shapePool: [ShapeOption] = [
        ShapeOption(name: "圆形", color: .red, systemImage: "circle.fill"),
        ShapeOption(name: "方形", color: .blue, systemImage: "square.fill"),
        ShapeOption(name: "三角形", color: .green, systemImage: "triangle.fill"),
        ShapeOption(name: "五边形", color: .purple, systemImage: "pentagon.fill"),
        ShapeOption(name: "六边形", color: .orange, systemImage: "hexagon.fill"),
        ShapeOption(name: "心形", color: .pink, systemImage: "heart.fill"),
        ShapeOption(name: "星形", color: .yellow, systemImage: "star.fill"),
        ShapeOption(name: "菱形", color: .cyan, systemImage: "diamond.fill"),
    ]

    static let advancedShapes: [ShapeOption] = [
        ShapeOption(name: "八边形", color: .brown, systemImage: "octagon.fill"),
        ShapeOption(name: "椭圆", color: .indigo, systemImage: "oval.fill"),
        ShapeOption(name: "盾牌", color: .mint, systemImage: "shield.fill"),
        ShapeOption(name: "领奖台", color: .teal, systemImage: "seal.fill"),
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 1.0, green: 0.82, blue: 0.65),
                         Color(red: 1.0, green: 0.94, blue: 0.78)],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()

            VStack(spacing: 0) {
                topBar.padding(.horizontal, 24)
                Spacer()

                // 目标图形
                targetShape.padding(.bottom, 36)

                // 语音提示
                Text(currentShape.name)
                    .font(.system(size: AgeAdaptiveHelper.bodyFontSize(for: age),
                                  weight: .bold, design: .rounded))
                    .foregroundColor(.brown)
                    .padding(.bottom, 8)
                Text(AgeAdaptiveHelper.voicePrompt(for: age))
                    .font(.system(size: 18, design: .rounded))
                    .foregroundColor(.gray)
                    .padding(.bottom, 28)

                // 选项
                optionsGrid.padding(.horizontal, 40)
                Spacer()
            }

            if showFeedback { feedbackOverlay }
        }
        .onAppear(perform: generateNewRound)
        .onChange(of: gameVM.selectedAgeGroup) { _ in
            // 切换年龄时重置
            score = 0; round = 0; starsEarned = 0
            generateNewRound()
        }
        .navigationBarHidden(true)
    }

    private var topBar: some View {
        HStack {
            Button(action: {
                gameVM.addStars(starsEarned)
                gameVM.recordGamePlayed(for: .shapeMatch)
                gameVM.updateHighScore(for: .shapeMatch, score: score)
                onBack()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left.circle.fill").font(.title)
                    Text("返回主页")
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                }.foregroundColor(.brown)
            }
            Spacer()
            HStack(spacing: 8) {
                Image(systemName: "star.fill").foregroundColor(.yellow).font(.title2)
                Text("\(score)")
                    .font(.system(size: 24, weight: .bold, design: .rounded)).foregroundColor(.brown)
            }
            Spacer()
            Text("\(round + 1)/\(maxRounds)")
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundColor(.brown.opacity(0.7))
        }.padding(.top, 16)
    }

    private var targetShape: some View {
        Image(systemName: currentShape.systemImage)
            .font(.system(size: 110))
            .foregroundColor(currentShape.color)
            .frame(width: 170, height: 170)
            .background(Circle().fill(.white.opacity(0.7)).shadow(color: .black.opacity(0.08), radius: 10))
    }

    private var optionsGrid: some View {
        let cols = age == .toddler ? [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
                                   : [GridItem(.flexible()), GridItem(.flexible())]
        return LazyVGrid(columns: cols, spacing: 18) {
            ForEach(options) { option in
                Button {
                    checkAnswer(option)
                } label: {
                    Image(systemName: option.systemImage)
                        .font(.system(size: AgeAdaptiveHelper.iconSize(for: age) * 0.75))
                        .foregroundColor(option.color)
                        .frame(maxWidth: .infinity)
                        .frame(height: AgeAdaptiveHelper.buttonSize(for: age) * 1.3)
                        .background(
                            RoundedRectangle(cornerRadius: 22)
                                .fill(.white.opacity(0.85))
                                .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
                        )
                }
                .disabled(showFeedback)
            }
        }
    }

    private var feedbackOverlay: some View {
        VStack(spacing: 16) {
            Image(systemName: isCorrect ? "hands.clap.fill" : "hand.thumbsup.fill")
                .font(.system(size: 60))
                .foregroundColor(isCorrect ? .green : .orange)
            Text(feedbackMessage)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(isCorrect ? .green : .orange)
            if isCorrect {
                HStack(spacing: 4) {
                    ForEach(0..<starsEarned, id: \.self) { _ in
                        Image(systemName: "star.fill").font(.title).foregroundColor(.yellow)
                    }
                }
            }
        }
        .padding(40)
        .background(RoundedRectangle(cornerRadius: 30).fill(.ultraThinMaterial))
    }

    private func generateNewRound() {
        guard round < maxRounds else {
            gameVM.addStars(starsEarned)
            gameVM.recordGamePlayed(for: .shapeMatch)
            gameVM.updateHighScore(for: .shapeMatch, score: score)
            return
        }
        currentShape = activePool.randomElement()!
        var pool = activePool.shuffled()
        pool.removeAll { $0.systemImage == currentShape.systemImage }
        options = Array(pool.prefix(optionCount - 1)) + [currentShape]
        options.shuffle()
        showFeedback = false
    }

    private func checkAnswer(_ selected: ShapeOption) {
        if selected.systemImage == currentShape.systemImage {
            isCorrect = true
            let pts = AgeAdaptiveHelper.scoreMultiplier(for: age)
            score += pts
            starsEarned += 1
            feedbackMessage = "太棒了！\u{1F389}"
            AudioManager.shared.play(.correct)
            if gameVM.voiceGuideEnabled {
                AudioManager.shared.speak("太棒了")
            }
        } else {
            isCorrect = false
            feedbackMessage = "再试一次！"
        }
        showFeedback = true; round += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + AgeAdaptiveHelper.feedbackDuration(for: age)) {
            withAnimation(.easeInOut(duration: 0.3)) { generateNewRound() }
        }
    }
}

import SwiftUI

// MARK: - 记忆翻牌游戏 (3-12岁自适应)
struct MemoryGameView: View {
    let onBack: () -> Void
    @EnvironmentObject var gameVM: GameViewModel
    @State private var cards: [MemoryCard] = []
    @State private var flippedIndices: Set<Int> = []
    @State private var score: Int = 0
    @State private var moves: Int = 0
    @State private var isProcessing: Bool = false
    @State private var starsEarned: Int = 0
    @State private var gameComplete: Bool = false

    private var age: AgeGroup { gameVM.selectedAgeGroup }

    private var pairsNeeded: Int {
        switch age { case .toddler: return 4; case .child: return 6; case .preteen: return 8 }
    }

    private var gridColumns: [GridItem] {
        let cols: Int
        switch age { case .toddler: cols = 4; case .child: cols = 4; case .preteen: cols = 4 }
        return Array(repeating: GridItem(.flexible(), spacing: 12), count: cols)
    }

    private let emojiPool = ["🐶","🐱","🐼","🐨","🐸","🦊","🐰","🐯","🦁","🐮","🐷","🐵"]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.65, green: 0.85, blue: 1.0),
                         Color(red: 0.82, green: 0.92, blue: 1.0)],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()

            VStack(spacing: 0) {
                topBar.padding(.horizontal, 24)
                Spacer()

                LazyVGrid(columns: gridColumns, spacing: 12) {
                    ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                        MemoryCardView(
                            card: card,
                            size: AgeAdaptiveHelper.buttonSize(for: age),
                            onTap: { flipCard(at: index) }
                        )
                        .disabled(card.isMatched || isProcessing || flippedIndices.contains(index))
                    }
                }
                .padding(.horizontal, 32)
                Spacer()
            }

            if gameComplete { completionOverlay }
        }
        .onAppear(perform: setupGame)
        .onChange(of: gameVM.selectedAgeGroup) { _ in setupGame() }
        .navigationBarHidden(true)
    }

    private var topBar: some View {
        HStack {
            Button(action: {
                gameVM.addStars(starsEarned)
                gameVM.recordGamePlayed(for: .memoryMatch)
                gameVM.updateHighScore(for: .memoryMatch, score: score)
                onBack()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left.circle.fill").font(.title)
                    Text("返回主页")
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                }.foregroundColor(.blue)
            }
            Spacer()
            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    Image(systemName: "star.fill").foregroundColor(.yellow)
                    Text("\(score)").font(.system(size: 22, weight: .bold, design: .rounded)).foregroundColor(.blue)
                }
                HStack(spacing: 6) {
                    Image(systemName: "arrow.triangle.swap").foregroundColor(.gray)
                    Text("\(moves)").font(.system(size: 22, weight: .bold, design: .rounded)).foregroundColor(.gray)
                }
            }
        }.padding(.top, 16)
    }

    private var completionOverlay: some View {
        VStack(spacing: 16) {
            Text("🎉").font(.system(size: 72))
            Text("全部找到啦！")
                .font(.system(size: 32, weight: .bold, design: .rounded)).foregroundColor(.blue)
            HStack(spacing: 6) {
                ForEach(0..<starsEarned, id: \.self) { _ in
                    Image(systemName: "star.fill").font(.title).foregroundColor(.yellow)
                }
            }
            Text("用了 \(moves) 步").font(.system(size: 20, design: .rounded)).foregroundColor(.gray)
            HStack(spacing: 20) {
                Button {
                    setupGame(); gameComplete = false
                } label: {
                    Label("再玩一次", systemImage: "arrow.counterclockwise")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .padding(.horizontal, 24).padding(.vertical: 12)
                        .background(Capsule().fill(.blue)).foregroundColor(.white)
                }
            }.padding(.top, 8)
        }
        .padding(40)
        .background(RoundedRectangle(cornerRadius: 30).fill(.ultraThinMaterial))
    }

    private func setupGame() {
        let selected = Array(emojiPool.shuffled().prefix(pairsNeeded))
        let paired = selected + selected
        cards = paired.shuffled().map { MemoryCard(emoji: $0) }
        flippedIndices = []; score = 0; moves = 0; starsEarned = 0; isProcessing = false
    }

    private func flipCard(at index: Int) {
        guard !cards[index].isMatched, !flippedIndices.contains(index), flippedIndices.count < 2 else { return }
        cards[index].isFlipped = true
        flippedIndices.insert(index)

        if flippedIndices.count == 2 {
            isProcessing = true; moves += 1
            let pair = Array(flippedIndices)
            if cards[pair[0]].emoji == cards[pair[1]].emoji {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    cards[pair[0]].isMatched = true; cards[pair[1]].isMatched = true
                    let pts = AgeAdaptiveHelper.scoreMultiplier(for: age)
                    score += pts; starsEarned += 1
                    flippedIndices = []; isProcessing = false
                    AudioManager.shared.play(.correct)
                    checkCompletion()
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    cards[pair[0]].isFlipped = false; cards[pair[1]].isFlipped = false
                    flippedIndices = []; isProcessing = false
                }
            }
        }
    }

    private func checkCompletion() {
        if cards.allSatisfy({ $0.isMatched }) {
            gameComplete = true
            gameVM.addStars(starsEarned)
            gameVM.recordGamePlayed(for: .memoryMatch)
            gameVM.updateHighScore(for: .memoryMatch, score: score)
            AudioManager.shared.play(.complete)
        }
    }
}

// MARK: - 记忆卡牌视图（带尺寸参数）
struct MemoryCardView: View {
    let card: MemoryCard
    var size: CGFloat = 64
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                if card.isFlipped || card.isMatched {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.white)
                        .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                    Text(card.emoji)
                        .font(.system(size: size * 0.6))
                } else {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(LinearGradient(
                            colors: [Color.purple, Color.blue.opacity(0.8)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                    Text("?")
                        .font(.system(size: size * 0.45, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .aspectRatio(1, contentMode: .fit)
        }
        .animation(.easeInOut(duration: 0.3), value: card.isFlipped)
    }
}

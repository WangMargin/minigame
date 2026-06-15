import SwiftUI

// MARK: - 音乐节奏游戏 (全年龄段)
struct MusicRhythmGameView: View {
    let onBack: () -> Void
    @EnvironmentObject var gameVM: GameViewModel
    @State private var notes: [FallingNote] = []
    @State private var score: Int = 0
    @State private var combo: Int = 0
    @State private var starsEarned: Int = 0
    @State private var gameStarted: Bool = false
    @State private var gameFinished: Bool = false
    @State private var beatIndex: Int = 0
    @State private var elapsedTime: Double = 0
    @State private var hitFeedback: HitFeedback?

    private var age: AgeGroup { gameVM.selectedAgeGroup }
    private let noteSpeed: Double = 2.5
    private let screenHeight: CGFloat = 500
    private let hitZoneY: CGFloat = 400
    private let hitThreshold: CGFloat = 60

    // 预置节奏模式
    private var beatPattern: [(lane: Int, time: Double)] {
        switch age {
        case .toddler:
            return [
                (0, 0.0), (2, 0.8), (1, 1.6),
                (0, 2.4), (2, 3.2), (1, 4.0),
                (0, 4.8), (2, 5.6), (1, 6.4)
            ]
        case .child:
            return [
                (0, 0.0), (2, 0.5), (1, 1.0), (3, 1.5),
                (0, 2.0), (2, 2.5), (1, 3.0), (3, 3.5),
                (0, 4.0), (2, 4.5), (1, 5.0), (3, 5.5),
                (0, 6.0), (2, 6.5), (1, 7.0)
            ]
        case .preteen:
            return [
                (0, 0.0), (2, 0.35), (1, 0.7), (3, 1.05),
                (0, 1.4), (1, 1.75), (2, 2.1), (3, 2.45),
                (0, 2.8), (2, 3.15), (1, 3.5), (3, 3.85),
                (0, 4.2), (1, 4.55), (2, 4.9), (3, 5.25),
                (0, 5.6), (2, 5.95), (1, 6.3), (3, 6.65)
            ]
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.85, green: 0.78, blue: 1.0),
                         Color(red: 0.95, green: 0.89, blue: 1.0)],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 24)

                if !gameStarted {
                    startScreen
                } else if gameFinished {
                    resultScreen
                } else {
                    gameArea
                }
            }
        }
        .onAppear {
            generateNotes()
        }
        .onReceive(Timer.publish(every: 0.03, on: .main, in: .common).autoconnect()) { _ in
            guard gameStarted, !gameFinished else { return }
            elapsedTime += 0.03
            updateNotes()
        }
        .navigationBarHidden(true)
    }

    // MARK: 顶栏
    private var topBar: some View {
        HStack {
            Button(action: {
                gameVM.addStars(starsEarned)
                gameVM.recordGamePlayed(for: .musicRhythm)
                gameVM.updateHighScore(for: .musicRhythm, score: score)
                onBack()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left.circle.fill").font(.title)
                    Text("返回主页")
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                }
                .foregroundColor(.purple)
            }

            Spacer()

            HStack(spacing: 6) {
                Image(systemName: "star.fill").foregroundColor(.yellow).font(.title2)
                Text("\(score)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.purple)
            }

            Spacer()

            if combo >= 3 {
                Text("\u{1F525} x\(combo)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.orange)
                    .scaleEffect(combo >= 5 ? 1.15 : 1.0)
                    .animation(.easeInOut, value: combo)
            }
        }
        .padding(.top, 16)
    }

    // MARK: 开始画面
    private var startScreen: some View {
        VStack(spacing: 28) {
            Spacer()

            Text("\u{1F3B5}")
                .font(.system(size: 80))

            Text("音乐节奏游戏")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundColor(.purple)

            Text("当音符落到圆圈位置时，\n点击对应颜色的按钮！")
                .font(.system(size: AgeAdaptiveHelper.bodyFontSize(for: age),
                              design: .rounded))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)

            // 颜色说明
            HStack(spacing: 20) {
                laneIndicator(color: .pink, label: "粉色")
                laneIndicator(color: .blue, label: "蓝色")
                laneIndicator(color: .green, label: "绿色")
                laneIndicator(color: .orange, label: "橙色")
            }

            Button {
                gameStarted = true
                elapsedTime = 0
                generateNotes()
            } label: {
                Label("开始！", systemImage: "play.fill")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 50)
                    .padding(.vertical, 18)
                    .background(Capsule().fill(
                        LinearGradient(colors: [.purple, .pink], startPoint: .leading, endPoint: .trailing)
                    ))
            }

            Spacer()
        }
    }

    private func laneIndicator(color: Color, label: String) -> some View {
        VStack(spacing: 4) {
            Circle().fill(color).frame(width: 24, height: 24)
            Text(label).font(.system(size: 12, design: .rounded)).foregroundColor(.gray)
        }
    }

    // MARK: 游戏区域
    private var gameArea: some View {
        VStack(spacing: 0) {
            ZStack {
                // 4条轨道
                HStack(spacing: 0) {
                    ForEach(0..<4, id: \.self) { lane in
                        Rectangle()
                            .fill(laneColor(lane).opacity(0.08))
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 20))

                // 下落音符
                ForEach(notes) { note in
                    if note.y < hitZoneY + hitThreshold && note.y > -50 && !note.isHit {
                        noteView(note)
                            .position(x: laneX(note.lane), y: note.y)
                    }
                }

                // 判定线
                hitZoneLine
            }
            .frame(height: screenHeight)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.white.opacity(0.85))
                    .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
            )
            .padding(.horizontal, 20)
            .padding(.top, 12)

            // 4个击打按钮
            HStack(spacing: 16) {
                ForEach(0..<4, id: \.self) { lane in
                    hitButton(lane: lane)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 20)
        }
    }

    private func noteView(_ note: FallingNote) -> some View {
        Text(note.emoji)
            .font(.system(size: 40))
            .scaleEffect(note.y > hitZoneY - hitThreshold && note.y < hitZoneY + hitThreshold ? 1.3 : 1.0)
    }

    private var hitZoneLine: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: hitZoneY - 2)
            Rectangle()
                .fill(
                    LinearGradient(colors: [.clear, .purple.opacity(0.5), .purple.opacity(0.5), .clear],
                                   startPoint: .leading, endPoint: .trailing)
                )
                .frame(height: 4)
        }
    }

    private func hitButton(lane: Int) -> some View {
        let color = laneColor(lane)
        return Button {
            hitLane(lane)
        } label: {
            Circle()
                .fill(color)
                .frame(width: 70, height: 70)
                .overlay {
                    Text("\u{1F446}")
                        .font(.system(size: 28))
                }
                .shadow(color: color.opacity(0.4), radius: 10, y: 4)
        }
    }

    // MARK: 结果画面
    private var resultScreen: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("\u{1F389}")
                .font(.system(size: 72))

            Text("表演结束！")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.purple)

            HStack(spacing: 6) {
                ForEach(0..<starsEarned, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.title)
                        .foregroundColor(.yellow)
                }
            }

            Text("得分: \(score)")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.purple)

            HStack(spacing: 20) {
                Button {
                    gameStarted = false
                    gameFinished = false
                    score = 0
                    combo = 0
                    starsEarned = 0
                } label: {
                    Label("再来一次", systemImage: "arrow.counterclockwise")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical: 14)
                        .background(Capsule().fill(.purple))
                }
            }

            Spacer()
        }
    }

    // MARK: 游戏逻辑
    private func generateNotes() {
        notes = beatPattern.map { beat in
            FallingNote(
                lane: beat.lane,
                startTime: beat.time,
                emoji: laneEmoji(beat.lane)
            )
        }
    }

    private func updateNotes() {
        for i in notes.indices {
            guard !notes[i].isHit else { continue }
            let travelTime = screenHeight / (noteSpeed * 100)
            let elapsed = elapsedTime - notes[i].startTime
            notes[i].y = (elapsed / travelTime) * screenHeight

            if notes[i].y > hitZoneY + hitThreshold * 2 {
                notes[i].isHit = true
                combo = 0
            }
        }

        if notes.allSatisfy({ $0.isHit }) && notes.count > 0 {
            finishGame()
        }
    }

    private func hitLane(_ lane: Int) {
        guard gameStarted, !gameFinished else { return }

        var bestIdx: Int?

        for i in notes.indices {
            guard notes[i].lane == lane, !notes[i].isHit else { continue }
            let dist = abs(notes[i].y - hitZoneY)
            if dist < hitThreshold {
                if bestIdx == nil || dist < abs(notes[bestIdx!].y - hitZoneY) {
                    bestIdx = i
                }
            }
        }

        if let idx = bestIdx {
            notes[idx].isHit = true
            combo += 1
            let pts = combo >= 5 ? 15 : (combo >= 3 ? 10 : 5)
            let multiplier = AgeAdaptiveHelper.scoreMultiplier(for: age) / 5
            score += pts * multiplier
            starsEarned = max(starsEarned, combo / 3 + 1)
            hitFeedback = HitFeedback(points: pts * multiplier, good: true)
        } else {
            combo = 0
            hitFeedback = HitFeedback(points: 0, good: false)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            hitFeedback = nil
        }
    }

    private func finishGame() {
        gameFinished = true
        gameStarted = false
        gameVM.addStars(starsEarned)
        gameVM.recordGamePlayed(for: .musicRhythm)
        gameVM.updateHighScore(for: .musicRhythm, score: score)
    }

    // MARK: 辅助
    private func laneColor(_ lane: Int) -> Color {
        [Color.pink, Color.blue, Color.green, Color.orange][lane]
    }

    private func laneEmoji(_ lane: Int) -> String {
        ["\u{1F3B5}", "\u{1F3B6}", "\u{1F941}", "\u{1F3B9}"][lane]
    }

    private func laneX(_ lane: Int) -> CGFloat {
        let totalWidth: CGFloat = UIScreen.main.bounds.width - 40
        let spacing: CGFloat = totalWidth / 4
        return spacing * CGFloat(lane) + spacing / 2
    }
}

// MARK: - 模型
struct FallingNote: Identifiable {
    let id = UUID()
    let lane: Int
    var startTime: Double
    var y: CGFloat = 0
    var isHit: Bool = false
    let emoji: String
}

struct HitFeedback {
    let points: Int
    let good: Bool
}

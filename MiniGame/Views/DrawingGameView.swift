import SwiftUI

// MARK: - 涂鸦描红游戏 (3-12岁自适应)
struct DrawingGameView: View {
    let onBack: () -> Void
    @EnvironmentObject var gameVM: GameViewModel
    @State private var currentTemplate: TracingContent = .line
    @State private var roundIndex: Int = 0
    @State private var score: Int = 0
    @State private var starsEarned: Int = 0
    @State private var showCompleted: Bool = false

    // 描红画布
    @State private var drawingPath = Path()
    @State private var currentPoints: [CGPoint] = []
    @State private var isDrawing: Bool = false

    private var age: AgeGroup { gameVM.selectedAgeGroup }
    private var templates: [TracingContent] {
        TracingContent.templates(for: age)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 1.0, green: 0.88, blue: 0.92),
                         Color(red: 1.0, green: 0.94, blue: 0.96)],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 24)

                Spacer()

                // 描红画布
                tracingCanvas
                    .padding(.horizontal, 40)
                    .padding(.vertical, 20)

                // 提示文字
                Text("用手指沿着虚线画出来 ✏️")
                    .font(.system(size: AgeAdaptiveHelper.bodyFontSize(for: age),
                                  weight: .medium, design: .rounded))
                    .foregroundColor(.pink.opacity(0.8))
                    .padding(.bottom, 12)

                // 底部操作
                bottomControls
                    .padding(.horizontal, 40)
                    .padding(.bottom, 20)

                Spacer()
            }
        }
        .onAppear {
            loadTemplate(at: 0)
        }
        .navigationBarHidden(true)
    }

    // MARK: 顶栏
    private var topBar: some View {
        HStack {
            Button(action: {
                gameVM.addStars(starsEarned)
                gameVM.recordGamePlayed(for: .drawing)
                gameVM.updateHighScore(for: .drawing, score: score)
                onBack()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.title)
                    Text("返回主页")
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                }
                .foregroundColor(.pink)
            }

            Spacer()

            HStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .font(.title2)
                Text("\(score)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.pink)
            }

            Spacer()

            Text("\(roundIndex + 1)/\(templates.count)")
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundColor(.pink.opacity(0.7))
        }
        .padding(.top, 16)
    }

    // MARK: 描红画布
    private var tracingCanvas: some View {
        GeometryReader { geo in
            ZStack {
                // 背景
                RoundedRectangle(cornerRadius: 24)
                    .fill(.white.opacity(0.95))
                    .shadow(color: .black.opacity(0.06), radius: 8, y: 3)

                // 虚线模板
                templatePath(in: geo.size)
                    .stroke(style: StrokeStyle(lineWidth: 3, dash: [8, 6]))
                    .foregroundColor(.gray.opacity(0.4))

                // 用户绘制的轨迹
                drawingPath
                    .stroke(
                        style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round)
                    )
                    .foregroundColor(.pink)

                // 起点标记
                if let first = templatePoints(in: geo.size).first {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 14, height: 14)
                        .position(first)
                }

                // 终点标记
                if let last = templatePoints(in: geo.size).last {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 14, height: 14)
                        .position(last)
                }
            }
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { value in
                        let point = value.location
                        if isDrawing {
                            if let last = currentPoints.last {
                                let mid = CGPoint(
                                    x: (last.x + point.x) / 2,
                                    y: (last.y + point.y) / 2
                                )
                                drawingPath.addLine(to: mid)
                            }
                            currentPoints.append(point)
                        }
                    }
                    .onEnded { _ in
                        isDrawing = false
                        checkCompletion()
                    }
            )
            .simultaneousGesture(
                TapGesture()
                    .onEnded {
                        // 开始新的一笔
                        isDrawing = true
                        currentPoints = []
                    }
            )
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: 模板点
    private func templatePoints(in size: CGSize) -> [CGPoint] {
        let w = size.width
        let h = size.height
        let margin: CGFloat = 50

        switch currentTemplate {
        case .line:
            return [CGPoint(x: margin, y: h / 2),
                    CGPoint(x: w - margin, y: h / 2)]
        case .curve:
            return [CGPoint(x: margin, y: h * 0.7),
                    CGPoint(x: w * 0.3, y: h * 0.3),
                    CGPoint(x: w * 0.7, y: h * 0.3),
                    CGPoint(x: w - margin, y: h * 0.7)]
        case .circle:
            return circlePoints(center: CGPoint(x: w / 2, y: h / 2),
                                radius: min(w, h) / 3, count: 36)
        case .shape(let name):
            return shapePoints(for: name, in: size)
        case .zigzag:
            return [CGPoint(x: margin, y: h * 0.3),
                    CGPoint(x: w * 0.3, y: h * 0.7),
                    CGPoint(x: w * 0.5, y: h * 0.3),
                    CGPoint(x: w * 0.7, y: h * 0.7),
                    CGPoint(x: w - margin, y: h * 0.3)]
        case .letter(let ch):
            return letterPoints(for: ch, in: size)
        case .number(let ch):
            return numberPoints(for: ch, in: size)
        case .chineseWord(let ch):
            return chineseWordOutline(for: ch, in: size)
        }
    }

    private func templatePath(in size: CGSize) -> Path {
        let pts = templatePoints(in: size)
        var path = Path()
        guard pts.count >= 2 else { return path }
        path.move(to: pts[0])
        for pt in pts.dropFirst() {
            path.addLine(to: pt)
        }
        return path
    }

    // MARK: 辅助形状点
    private func circlePoints(center: CGPoint, radius: CGFloat, count: Int) -> [CGPoint] {
        (0..<count).map { i in
            let angle = 2 * .pi * CGFloat(i) / CGFloat(count)
            return CGPoint(x: center.x + radius * cos(angle),
                           y: center.y + radius * sin(angle))
        }
    }

    private func shapePoints(for name: String, in size: CGSize) -> [CGPoint] {
        let w = size.width; let h = size.height
        let cx = w / 2; let cy = h / 2
        let r = min(w, h) / 3
        switch name {
        case "三角形":
            return [CGPoint(x: cx, y: cy - r),
                    CGPoint(x: cx - r, y: cy + r * 0.7),
                    CGPoint(x: cx + r, y: cy + r * 0.7),
                    CGPoint(x: cx, y: cy - r)]
        case "方形":
            return [CGPoint(x: cx - r, y: cy - r),
                    CGPoint(x: cx + r, y: cy - r),
                    CGPoint(x: cx + r, y: cy + r),
                    CGPoint(x: cx - r, y: cy + r),
                    CGPoint(x: cx - r, y: cy - r)]
        case "五角星":
            let inner = r * 0.38
            var pts: [CGPoint] = []
            for i in 0..<10 {
                let angle = -.pi / 2 + .pi * CGFloat(i) / 5
                let rad = i % 2 == 0 ? r : inner
                pts.append(CGPoint(x: cx + rad * cos(angle),
                                   y: cy + rad * sin(angle)))
            }
            pts.append(pts[0])
            return pts
        default: return []
        }
    }

    private func letterPoints(for ch: String, in size: CGSize) -> [CGPoint] {
        // 简化字母轮廓
        let w = size.width; let h = size.height
        let margin: CGFloat = 60
        switch ch.uppercased() {
        case "A":
            return [CGPoint(x: w / 2, y: margin),
                    CGPoint(x: margin, y: h - margin),
                    CGPoint(x: w / 2, y: h * 0.5),
                    CGPoint(x: w - margin, y: h - margin)]
        case "B":
            return [CGPoint(x: margin, y: margin),
                    CGPoint(x: w * 0.6, y: margin),
                    CGPoint(x: w * 0.7, y: h * 0.3),
                    CGPoint(x: w * 0.5, y: h * 0.5),
                    CGPoint(x: w * 0.7, y: h * 0.7),
                    CGPoint(x: w * 0.6, y: h - margin),
                    CGPoint(x: margin, y: h - margin)]
        case "C":
            return circlePoints(center: CGPoint(x: w / 2, y: h / 2),
                                radius: min(w, h) / 3, count: 28)
                .map { $0 }.reversed()
        default:
            return [CGPoint(x: margin, y: h / 2),
                    CGPoint(x: w - margin, y: h / 2)]
        }
    }

    private func numberPoints(for ch: String, in size: CGSize) -> [CGPoint] {
        let w = size.width; let h = size.height
        let margin: CGFloat = 60
        switch ch {
        case "1":
            return [CGPoint(x: w / 2, y: margin),
                    CGPoint(x: w / 2, y: h - margin)]
        case "2":
            return [CGPoint(x: margin, y: margin),
                    CGPoint(x: w - margin, y: margin),
                    CGPoint(x: w - margin, y: h / 2),
                    CGPoint(x: margin, y: h / 2),
                    CGPoint(x: margin, y: h - margin),
                    CGPoint(x: w - margin, y: h - margin)]
        case "3":
            return [CGPoint(x: margin, y: margin),
                    CGPoint(x: w - margin, y: margin),
                    CGPoint(x: w - margin, y: h / 2),
                    CGPoint(x: margin, y: h / 2),
                    CGPoint(x: w - margin, y: h / 2),
                    CGPoint(x: w - margin, y: h - margin),
                    CGPoint(x: margin, y: h - margin)]
        case "8":
            return [CGPoint(x: w * 0.3, y: margin),
                    CGPoint(x: w * 0.7, y: margin),
                    CGPoint(x: w * 0.7, y: h / 2),
                    CGPoint(x: w * 0.3, y: h / 2),
                    CGPoint(x: w * 0.3, y: margin),
                    CGPoint(x: w * 0.3, y: h / 2),
                    CGPoint(x: w * 0.7, y: h / 2),
                    CGPoint(x: w * 0.7, y: h - margin),
                    CGPoint(x: w * 0.3, y: h - margin)]
        default:
            return [CGPoint(x: margin, y: h / 2),
                    CGPoint(x: w - margin, y: h / 2)]
        }
    }

    private func chineseWordOutline(for ch: String, in size: CGSize) -> [CGPoint] {
        // 简化汉字描红点 — 提供大致笔顺
        let w = size.width; let h = size.height
        let margin: CGFloat = 40
        switch ch {
        case "大":
            return [CGPoint(x: w / 2, y: margin),
                    CGPoint(x: w / 2, y: h - margin * 0.5),
                    CGPoint(x: w * 0.25, y: h * 0.4),
                    CGPoint(x: w * 0.75, y: h * 0.4)]
        case "人":
            return [CGPoint(x: w * 0.35, y: margin),
                    CGPoint(x: w / 2, y: h - margin),
                    CGPoint(x: w * 0.65, y: margin)]
        case "山":
            return [CGPoint(x: margin * 2, y: h - margin),
                    CGPoint(x: margin * 2, y: h * 0.4),
                    CGPoint(x: w / 2, y: margin * 1.5),
                    CGPoint(x: w - margin * 2, y: h * 0.4),
                    CGPoint(x: w - margin * 2, y: h - margin)]
        default:
            return [CGPoint(x: w * 0.3, y: margin),
                    CGPoint(x: w * 0.7, y: margin),
                    CGPoint(x: w * 0.7, y: h - margin),
                    CGPoint(x: w * 0.3, y: h - margin),
                    CGPoint(x: w * 0.3, y: margin)]
        }
    }

    // MARK: 底部控制
    private var bottomControls: some View {
        HStack(spacing: 40) {
            // 清除
            Button(action: clearCanvas) {
                Label("清除", systemImage: "eraser.fill")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(.gray))
            }

            // 下一个
            Button(action: nextTemplate) {
                Label("下一个", systemImage: "arrow.right")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(.pink))
            }
        }
    }

    // MARK: 游戏逻辑
    private func loadTemplate(at index: Int) {
        guard index < templates.count else {
            finishGame()
            return
        }
        roundIndex = index
        currentTemplate = templates[index]
        clearCanvas()
    }

    private func clearCanvas() {
        drawingPath = Path()
        currentPoints = []
    }

    private func checkCompletion() {
        // 简单判定：有点就算完成
        if !currentPoints.isEmpty {
            let pts = AgeAdaptiveHelper.scoreMultiplier(for: age)
            score += pts
            starsEarned += 1
            AudioManager.shared.play(.correct)
        }
    }

    private func nextTemplate() {
        loadTemplate(at: roundIndex + 1)
    }

    private func finishGame() {
        gameVM.addStars(starsEarned)
        gameVM.recordGamePlayed(for: .drawing)
        gameVM.updateHighScore(for: .drawing, score: score)
        onBack()
    }
}

// MARK: - 描红内容定义
enum TracingContent: Identifiable {
    case line, curve, circle, zigzag
    case shape(String)      // 形状名
    case letter(String)     // 字母
    case number(String)     // 数字
    case chineseWord(String) // 汉字

    var id: String {
        switch self {
        case .line: return "line"
        case .curve: return "curve"
        case .circle: return "circle"
        case .zigzag: return "zigzag"
        case .shape(let n): return "shape_\(n)"
        case .letter(let c): return "letter_\(c)"
        case .number(let c): return "num_\(c)"
        case .chineseWord(let c): return "cn_\(c)"
        }
    }

    var displayName: String {
        switch self {
        case .line:     return "直线"
        case .curve:    return "曲线"
        case .circle:   return "圆形"
        case .zigzag:   return "锯齿线"
        case .shape(let n): return n
        case .letter(let c): return c
        case .number(let c): return c
        case .chineseWord(let c): return c
        }
    }

    static func templates(for age: AgeGroup) -> [TracingContent] {
        switch age {
        case .toddler:
            return [.line, .curve, .circle, .zigzag,
                    .shape("三角形"), .shape("方形")]
        case .child:
            return [.line, .curve, .circle, .zigzag,
                    .number("1"), .number("2"), .number("3"),
                    .letter("A"), .letter("B"), .letter("C")]
        case .preteen:
            return [.line, .curve, .circle, .zigzag,
                    .number("8"), .letter("C"),
                    .chineseWord("大"), .chineseWord("人"), .chineseWord("山")]
        }
    }
}

import SwiftUI

// MARK: - 家长中心
struct ParentZoneView: View {
    let onBack: () -> Void
    @EnvironmentObject var gameVM: GameViewModel
    @State private var gateAnswer: String = ""
    @State private var showGate: Bool = true
    @State private var gateError: Bool = false
    @State private var showResetConfirm: Bool = false

    // 临时设置
    @State private var tempTimeLimit: Double = 45
    @State private var tempSoundEnabled: Bool = true
    @State private var tempVoiceEnabled: Bool = true

    var body: some View {
        Group {
            if showGate {
                parentGateView
            } else {
                settingsView
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - 家长验证门
    private var parentGateView: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.85, green: 0.82, blue: 0.98),
                         Color(red: 0.82, green: 0.88, blue: 0.98)],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()

            VStack(spacing: 24) {
                HStack {
                    Button(action: onBack) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left.circle.fill")
                                .font(.title2)
                            Text("返回")
                                .font(.system(size: 18, weight: .medium, design: .rounded))
                        }
                        .foregroundColor(.purple)
                    }
                    Spacer()
                }
                .padding(.horizontal, 28)
                .padding(.top, 20)

                Spacer()

                VStack(spacing: 20) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.purple)

                    Text("家长验证")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(.purple)

                    Text("请回答以下问题以进入家长设置")
                        .font(.system(size: 16, design: .rounded))
                        .foregroundColor(.gray)

                    // 算术题
                    VStack(spacing: 8) {
                        Text("7 \u{00D7} 8 = ?")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.purple)

                        TextField("输入答案", text: $gateAnswer)
                            .keyboardType(.numberPad)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .frame(width: 160, height: 60)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(.white.opacity(0.9))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(gateError ? Color.red : Color.gray.opacity(0.3), lineWidth: 2)
                            )

                        if gateError {
                            Text("答案不正确，请重试")
                                .font(.system(size: 14, design: .rounded))
                                .foregroundColor(.red)
                        }
                    }

                    Button(action: verifyGate) {
                        Text("确认")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(width: 120, height: 46)
                            .background(Capsule().fill(Color.purple))
                    }
                    .disabled(gateAnswer.isEmpty)
                }

                Spacer()
            }
        }
    }

    // MARK: - 设置页
    private var settingsView: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.95, green: 0.95, blue: 1.0),
                         Color(red: 0.98, green: 0.96, blue: 0.98)],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // 顶栏
                    HStack {
                        Button(action: {
                            gameVM.resetParentGate()
                            onBack()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.left.circle.fill")
                                    .font(.title2)
                                Text("返回主页")
                                    .font(.system(size: 18, weight: .medium, design: .rounded))
                            }
                            .foregroundColor(.purple)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 20)

                    Text("\u{1F468}\u{200D}\u{1F469}\u{200D}\u{1F467} 家长中心")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.purple)
                        .padding(.top, 8)

                    // --- 时长控制 ---
                    settingsCard(title: "\u{23F1}\u{FE0F} 每日时长限制", systemImage: "hourglass") {
                        VStack(spacing: 16) {
                            HStack {
                                Text("\(Int(tempTimeLimit)) 分钟")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(.purple)
                                Spacer()
                            }

                            Slider(value: $tempTimeLimit, in: 15...120, step: 5)
                                .tint(.purple)

                            HStack {
                                Text("15分钟")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Spacer()
                                Text("120分钟")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }

                            Button(action: applyTimeLimit) {
                                Text("应用")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 10)
                                    .background(Capsule().fill(.purple))
                            }
                        }
                    }

                    // --- 音效控制 ---
                    settingsCard(title: "\u{1F50A} 音效设置", systemImage: "speaker.wave.2") {
                        VStack(spacing: 14) {
                            Toggle(isOn: $tempSoundEnabled) {
                                Text("游戏音效")
                                    .font(.system(size: 17, design: .rounded))
                            }
                            .tint(.purple)
                            .onChange(of: tempSoundEnabled) { newValue in
                                gameVM.soundEnabled = newValue
                                AudioManager.shared.isSoundEnabled = newValue
                            }

                            Toggle(isOn: $tempVoiceEnabled) {
                                Text("语音引导")
                                    .font(.system(size: 17, design: .rounded))
                            }
                            .tint(.purple)
                            .onChange(of: tempVoiceEnabled) { newValue in
                                gameVM.voiceGuideEnabled = newValue
                                AudioManager.shared.isVoiceEnabled = newValue
                            }
                        }
                    }

                    // --- 学习进度 ---
                    settingsCard(title: "\u{1F4CA} 学习进度", systemImage: "chart.bar.fill") {
                        VStack(spacing: 14) {
                            progressRow("总星星数", value: "\(gameVM.totalStars) \u{2B50}")
                            progressRow("玩游戏总次数", value: "\(gameVM.gamesPlayed) 次")
                            progressRow("今日时长", value: "\(Int(gameVM.todayPlayTime / 60)) 分钟")
                            progressRow("当前年龄段", value: gameVM.selectedAgeGroup.displayName)

                            Divider()

                            ForEach(GameType.allCases, id: \.self) { game in
                                HStack {
                                    Image(systemName: game.icon)
                                        .foregroundColor(game.backgroundColor)
                                    Text(game.title)
                                        .font(.system(size: 15, design: .rounded))
                                    Spacer()
                                    if let score = gameVM.highScores[game] {
                                        Text("最高 \(score)分")
                                            .font(.system(size: 14, design: .rounded))
                                            .foregroundColor(.orange)
                                    }
                                    if let count = gameVM.gamePlayCount[game] {
                                        Text("\(count)次")
                                            .font(.system(size: 14, design: .rounded))
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                    }

                    // --- 重置 ---
                    settingsCard(title: "\u{1F504} 数据管理", systemImage: "arrow.triangle.2.circlepath") {
                        Button(role: .destructive) {
                            showResetConfirm = true
                        } label: {
                            Label("重置所有游戏进度", systemImage: "trash")
                                .font(.system(size: 16, design: .rounded))
                        }
                        .alert("确认重置", isPresented: $showResetConfirm) {
                            Button("取消", role: .cancel) {}
                            Button("确定重置", role: .destructive) {
                                resetAllProgress()
                            }
                        } message: {
                            Text("这将清除所有星星、分数和游戏记录。此操作不可撤销。")
                        }
                    }

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 20)
            }
        }
        .onAppear {
            tempTimeLimit = gameVM.dailyTimeLimit / 60
            tempSoundEnabled = gameVM.soundEnabled
            tempVoiceEnabled = gameVM.voiceGuideEnabled
        }
    }

    // MARK: 设置卡片
    private func settingsCard<Content: View>(
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.purple)

            content()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white)
                .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
        )
    }

    // MARK: 进度行
    private func progressRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 15, design: .rounded))
                .foregroundColor(.primary)
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(.purple)
        }
    }

    // MARK: 操作
    private func verifyGate() {
        guard let answer = Int(gateAnswer) else {
            gateError = true
            return
        }
        if gameVM.verifyParentGate(answer: answer) {
            withAnimation {
                showGate = false
                gateError = false
            }
        } else {
            gateError = true
            gateAnswer = ""
        }
    }

    private func applyTimeLimit() {
        gameVM.dailyTimeLimit = tempTimeLimit * 60
        gameVM.resetTimeLimit()
    }

    private func resetAllProgress() {
        gameVM.totalStars = 0
        gameVM.gamesPlayed = 0
        gameVM.highScores = [:]
        gameVM.gamePlayCount = [:]
        gameVM.resetTimeLimit()
    }
}

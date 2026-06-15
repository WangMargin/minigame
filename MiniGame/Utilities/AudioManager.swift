import AVFoundation
import SwiftUI

// MARK: - 音效管理器
class AudioManager: ObservableObject {
    static let shared = AudioManager()

    @Published var isSoundEnabled: Bool = true
    @Published var isVoiceEnabled: Bool = true

    private var bgmPlayer: AVAudioPlayer?
    private var sfxPlayers: [String: AVAudioPlayer] = [:]

    // 预设音效分类
    enum SFX: String {
        case correct = "correct"       // 答对
        case wrong = "wrong"           // 答错
        case tap = "tap"               // 点击
        case star = "star"             // 获得星星
        case complete = "complete"     // 完成一轮
        case flip = "flip"             // 翻牌
        case rhythm = "rhythm"         // 节奏击打
    }

    private init() {
        setupAudioSession()
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .ambient,
                mode: .default,
                options: [.mixWithOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("⚠️ Audio session setup failed: \(error)")
        }
    }

    /// 播放音效（注意：需要 .wav/.mp3 资源文件；无文件时静默）
    func play(_ sfx: SFX) {
        guard isSoundEnabled else { return }
        // 预留接口 — 后续添加音频资源后启用
        // if let url = Bundle.main.url(forResource: sfx.rawValue, withExtension: "wav") {
        //     playSound(url: url)
        // }
    }

    /// 语音引导（TODO: 集成 AVSpeechSynthesizer 或预录音频）
    func speak(_ text: String) {
        guard isVoiceEnabled else { return }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.85
        utterance.pitchMultiplier = 1.1
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.speak(utterance)
    }

    private func playSound(url: URL) {
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            player.play()
        } catch {
            print("⚠️ Failed to play sound: \(error)")
        }
    }
}

import SwiftUI

// MARK: - 年龄适配辅助工具
struct AgeAdaptiveHelper {

    // MARK: 按钮尺寸 (越小年龄越大按钮)
    static func buttonSize(for age: AgeGroup) -> CGFloat {
        switch age {
        case .toddler: return 80
        case .child:   return 64
        case .preteen: return 52
        }
    }

    // MARK: 文字大小
    static func titleFontSize(for age: AgeGroup) -> CGFloat {
        switch age {
        case .toddler: return 38
        case .child:   return 30
        case .preteen: return 26
        }
    }

    static func bodyFontSize(for age: AgeGroup) -> CGFloat {
        switch age {
        case .toddler: return 24
        case .child:   return 20
        case .preteen: return 18
        }
    }

    // MARK: 卡片间距
    static func cardSpacing(for age: AgeGroup) -> CGFloat {
        switch age {
        case .toddler: return 32
        case .child:   return 24
        case .preteen: return 20
        }
    }

    // MARK: 图标大小
    static func iconSize(for age: AgeGroup) -> CGFloat {
        switch age {
        case .toddler: return 72
        case .child:   return 56
        case .preteen: return 44
        }
    }

    // MARK: 反馈显示时长
    static func feedbackDuration(for age: AgeGroup) -> Double {
        switch age {
        case .toddler: return 2.5  // 幼儿需要更长时间看反馈
        case .child:   return 2.0
        case .preteen: return 1.5
        }
    }

    // MARK: 分数加倍 (年长者分数更高以保持挑战性)
    static func scoreMultiplier(for age: AgeGroup) -> Int {
        switch age {
        case .toddler: return 5
        case .child:   return 10
        case .preteen: return 15
        }
    }

    // MARK: 背景配色
    static func backgroundGradient(for age: AgeGroup) -> [Color] {
        switch age {
        case .toddler:
            return [Color(red: 1.0, green: 0.92, blue: 0.85),
                    Color(red: 1.0, green: 0.85, blue: 0.92)]
        case .child:
            return [Color(red: 0.9, green: 0.95, blue: 1.0),
                    Color(red: 1.0, green: 0.92, blue: 0.95)]
        case .preteen:
            return [Color(red: 0.85, green: 0.92, blue: 1.0),
                    Color(red: 0.88, green: 1.0, blue: 0.92)]
        }
    }

    // MARK: 语音引导提示文本
    static func voicePrompt(for age: AgeGroup) -> String {
        switch age {
        case .toddler: return "轻轻点一下就行哦～"
        case .child:   return "选一个答案吧！"
        case .preteen: return "选择正确答案"
        }
    }
}

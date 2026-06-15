import SwiftUI

// MARK: - 年龄段
enum AgeGroup: String, CaseIterable, Identifiable {
    case toddler = "3-5"    // 幼儿
    case child = "6-8"      // 学龄
    case preteen = "9-12"   // 少年

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .toddler: return "3-5 岁"
        case .child:    return "6-8 岁"
        case .preteen:  return "9-12 岁"
        }
    }

    var emoji: String {
        switch self {
        case .toddler: return "🌱"
        case .child:   return "🌿"
        case .preteen: return "🌳"
        }
    }

    var description: String {
        switch self {
        case .toddler: return "启蒙认知"
        case .child:   return "基础学习"
        case .preteen: return "进阶挑战"
        }
    }

    var difficultyScale: Double {
        switch self {
        case .toddler: return 0.0
        case .child:   return 0.5
        case .preteen: return 1.0
        }
    }
}

// MARK: - 游戏分类
enum GameCategory: String {
    case cognition = "认知启蒙"    // 3-5岁核心
    case logic = "逻辑思维"        // 6-12岁核心
    case creativity = "创意表达"   // 全年龄
    case memory = "记忆力"         // 全年龄
}

// MARK: - 游戏类型枚举
enum GameType: String, CaseIterable, Identifiable {
    case shapeMatch = "shapeMatch"
    case memoryMatch = "memoryMatch"
    case mathFun = "mathFun"
    case drawing = "drawing"
    case musicRhythm = "musicRhythm"
    case wordPuzzle = "wordPuzzle"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .shapeMatch:  return "形状匹配"
        case .memoryMatch: return "记忆翻牌"
        case .mathFun:     return "数学启蒙"
        case .drawing:     return "涂鸦描红"
        case .musicRhythm: return "音乐节奏"
        case .wordPuzzle:  return "单词拼图"
        }
    }

    var icon: String {
        switch self {
        case .shapeMatch:  return "circle.hexagongrid.fill"
        case .memoryMatch: return "grid.2x2.fill"
        case .mathFun:     return "123.rectangle.fill"
        case .drawing:     return "pencil.tip.crop.circle.fill"
        case .musicRhythm: return "music.note.list"
        case .wordPuzzle:  return "character.textbox"
        }
    }

    var backgroundColor: Color {
        switch self {
        case .shapeMatch:  return Color(red: 1.0, green: 0.75, blue: 0.35)
        case .memoryMatch: return Color(red: 0.45, green: 0.75, blue: 1.0)
        case .mathFun:     return Color(red: 0.55, green: 0.85, blue: 0.5)
        case .drawing:     return Color(red: 0.95, green: 0.45, blue: 0.55)
        case .musicRhythm: return Color(red: 0.7, green: 0.45, blue: 0.95)
        case .wordPuzzle:  return Color(red: 0.3, green: 0.7, blue: 0.85)
        }
    }

    var category: GameCategory {
        switch self {
        case .shapeMatch:  return .cognition
        case .mathFun:     return .logic
        case .memoryMatch: return .memory
        case .drawing:     return .creativity
        case .musicRhythm: return .creativity
        case .wordPuzzle:  return .logic
        }
    }

    var ageDescription: String {
        switch self {
        case .shapeMatch:  return "认识形状和颜色"
        case .memoryMatch: return "锻炼记忆力和专注力"
        case .mathFun:     return "数字认知与简单算术"
        case .drawing:     return "练习控笔和书写"
        case .musicRhythm: return "感受节奏和旋律"
        case .wordPuzzle:  return "拼写单词丰富词汇"
        }
    }

    /// 适合的最低年龄段
    var minimumAge: AgeGroup {
        switch self {
        case .shapeMatch:  return .toddler
        case .memoryMatch: return .toddler
        case .mathFun:     return .toddler
        case .drawing:     return .toddler
        case .musicRhythm: return .toddler
        case .wordPuzzle:  return .child    // 6岁+才适合
        }
    }

    /// 根据年龄段返回描述
    func description(for age: AgeGroup) -> String {
        switch (self, age) {
        case (.shapeMatch, .toddler): return "认识圆形、方形和三角形！"
        case (.shapeMatch, .child):   return "匹配不同的形状和颜色吧！"
        case (.shapeMatch, .preteen): return "挑战更多几何图形匹配！"
        case (.memoryMatch, .toddler): return "找到一样的可爱小动物！"
        case (.memoryMatch, .child):  return "翻牌配对锻炼记忆力！"
        case (.memoryMatch, .preteen): return "大量卡片等你来挑战！"
        case (.mathFun, .toddler):    return "数一数有几个水果呀？"
        case (.mathFun, .child):      return "加法减法我都会算！"
        case (.mathFun, .preteen):    return "挑战更有难度的计算！"
        case (.drawing, .toddler):    return "用手指画出线条和形状！"
        case (.drawing, .child):      return "学写字母和数字吧！"
        case (.drawing, .preteen):    return "练习书写汉字和单词！"
        case (.musicRhythm, .toddler): return "跟着节拍一起拍手！"
        case (.musicRhythm, .child):   return "有趣的节奏游戏！"
        case (.musicRhythm, .preteen): return "挑战复杂节奏模式！"
        case (.wordPuzzle, .child):    return "拼出简单的单词！"
        case (.wordPuzzle, .preteen):  return "挑战更长更难的单词！"
        default: return ageDescription
        }
    }
}

// MARK: - 记忆翻牌卡片
struct MemoryCard: Identifiable {
    let id = UUID()
    let emoji: String
    var isFlipped: Bool = false
    var isMatched: Bool = false
}

// MARK: - 形状匹配模型
struct ShapeOption: Identifiable {
    let id = UUID()
    let name: String
    let color: Color
    let systemImage: String
}

// MARK: - 数学题目模型
struct MathQuestion {
    let objectCount: Int
    let emoji: String
    let correctAnswer: Int
    let options: [Int]
    let operationSymbol: String?  // nil = 数数, "+" = 加法, "-" = 减法
    let secondCount: Int?         // 用于加减法的第二个数
}

// MARK: - 描红模型
struct TracingStroke {
    let points: [CGPoint]
    let color: Color
}

// MARK: - 音乐节奏音符
struct RhythmNote: Identifiable {
    let id = UUID()
    let lane: Int           // 0-3 四条轨道
    let timeOffset: Double  // 出现的时间偏移
    let emoji: String
}

// MARK: - 单词拼图模型
struct WordPuzzleItem {
    let word: String
    let hint: String
    let scrambledLetters: [Character]
}

// MARK: - 涂鸦描红模板
struct TracingTemplate: Identifiable {
    let id = UUID()
    let name: String
    let type: TracingType
}

enum TracingType {
    case line         // 直线
    case curve        // 曲线
    case shape(String) // 形状
    case letter(String) // 字母
    case number(String) // 数字
    case chinese(String) // 汉字
}

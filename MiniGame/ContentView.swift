import SwiftUI

// MARK: - 根导航视图
struct ContentView: View {
    @StateObject private var gameVM = GameViewModel()
    @StateObject private var audioMgr = AudioManager.shared
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            HomeView(
                onSelectGame: { gameType in
                    navigationPath.append(gameType)
                },
                onOpenParentZone: {
                    navigationPath.append("parentZone")
                }
            )
            .navigationDestination(for: GameType.self) { gameType in
                destinationView(for: gameType)
            }
            .navigationDestination(for: String.self) { route in
                if route == "parentZone" {
                    ParentZoneView(onBack: { navigationPath.removeLast() })
                }
            }
        }
        .environmentObject(gameVM)
        .environmentObject(audioMgr)
    }

    @ViewBuilder
    private func destinationView(for gameType: GameType) -> some View {
        switch gameType {
        case .shapeMatch:
            ShapeMatchGameView(onBack: { navigationPath.removeLast() })
        case .memoryMatch:
            MemoryGameView(onBack: { navigationPath.removeLast() })
        case .mathFun:
            MathGameView(onBack: { navigationPath.removeLast() })
        case .drawing:
            DrawingGameView(onBack: { navigationPath.removeLast() })
        case .musicRhythm:
            MusicRhythmGameView(onBack: { navigationPath.removeLast() })
        case .wordPuzzle:
            WordPuzzleGameView(onBack: { navigationPath.removeLast() })
        }
    }
}

// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MiniGame",
    platforms: [.iOS(.v16)],
    products: [
        .iOSApplication(
            name: "小天才乐园",
            targets: ["AppModule"],
            displayVersion: "1.0.0",
            bundleVersion: "1",
            supportedDeviceFamilies: [
                .pad,
                .phone
            ],
            capabilities: [
                .microphone(purposeString: "用于语音引导功能"),
                .camera(purposeString: "未使用")
            ]
        )
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            path: ".",
            sources: [
                "MiniGameApp.swift",
                "ContentView.swift",
                "Models/GameModels.swift",
                "ViewModels/GameViewModel.swift",
                "Utilities/AudioManager.swift",
                "Utilities/AgeAdaptiveHelper.swift",
                "Views/HomeView.swift",
                "Views/ShapeMatchGameView.swift",
                "Views/MemoryGameView.swift",
                "Views/MathGameView.swift",
                "Views/DrawingGameView.swift",
                "Views/MusicRhythmGameView.swift",
                "Views/WordPuzzleGameView.swift",
                "Views/ParentZoneView.swift"
            ]
        )
    ]
)

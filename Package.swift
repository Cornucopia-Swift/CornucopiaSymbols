// swift-tools-version: 5.9
import PackageDescription

let setNames = [
    "Feather",
    "Heroicons",
    "Lucide",
    "FontAwesome",
    "Remix",
    "Tabler",
    "Pictogrammers",
]

func setTarget(_ name: String) -> Target {
    .target(
        name: "CornucopiaSymbols\(name)",
        dependencies: ["CornucopiaSymbolsCore"],
        path: "Sources/CornucopiaSymbols\(name)",
        exclude: ["ATTRIBUTION.md", "LICENSE.txt"],
        resources: [.process("Resources")]
    )
}

func setProduct(_ name: String) -> Product {
    .library(name: "CornucopiaSymbols\(name)", targets: ["CornucopiaSymbols\(name)"])
}

let package = Package(
    name: "CornucopiaSymbols",
    platforms: [
        .iOS(.v15),
        .macOS(.v13),
        .tvOS(.v15),
        .watchOS(.v8),
        .visionOS(.v1),
    ],
    products: [
        .library(name: "CornucopiaSymbolsCore", targets: ["CornucopiaSymbolsCore"]),
    ] + setNames.map(setProduct) + [
        .executable(name: "SymbolBrowser", targets: ["SymbolBrowser"]),
    ],
    targets: [
        .target(name: "CornucopiaSymbolsCore", path: "Sources/CornucopiaSymbolsCore"),
    ] + setNames.map(setTarget) + [
        .executableTarget(
            name: "SymbolBrowser",
            dependencies: [
                "CornucopiaSymbolsCore",
            ] + setNames.map { .target(name: "CornucopiaSymbols\($0)") },
            path: "App/SymbolBrowser"
        ),
        .testTarget(
            name: "CornucopiaSymbolsCoreTests",
            dependencies: ["CornucopiaSymbolsCore", "CornucopiaSymbolsFeather"],
            path: "Tests/CornucopiaSymbolsCoreTests"
        ),
    ]
)

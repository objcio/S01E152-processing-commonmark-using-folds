// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "commonmark-folds",
    products: [
        .library(name: "Ccmark", targets: ["Ccmark"]),
    ],
    targets: [
        .target(name: "commonmark-folds", dependencies: ["Ccmark"]),
        .systemLibrary(
            name: "Ccmark",
            pkgConfig: "libcmark",
            providers: [
                .brew(["commonmark"])
            ]
        )
    ]
)

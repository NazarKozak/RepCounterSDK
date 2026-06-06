// swift-tools-version: 6.0
//
//  Package.swift
//  RepKit
//
//  Created by Nazar Kozak on 05.06.2026.
//

import PackageDescription

let package = Package(
    name: "RepKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v12)
    ],
    products: [
        .library(name: "RepKit", targets: ["RepKit"])
    ],
    targets: [
        .target(
            name: "RepKit",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "RepKitTests",
            dependencies: ["RepKit"]
        )
    ]
)

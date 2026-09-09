// swift-tools-version: 6.0

//
//  Package.swift
//  Networking
//
//  Created by Niklas Holloh on 09.09.26.
//  Copyright 2026 adesso SE
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//

import PackageDescription

let package = Package(
    name: "NetworkingExample",
    platforms: [.macOS(.v13), .iOS(.v16)],
    dependencies: [
        // Local reference to the Networking library in the parent directory.
        .package(path: "../")
    ],
    targets: [
        .executableTarget(
            name: "Example",
            dependencies: [
                .product(name: "Networking", package: "Networking")
            ],
            path: "Sources/Example"
        )
    ]
)

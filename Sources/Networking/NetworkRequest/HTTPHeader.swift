//
//  HTTPHeader.swift
//  Networking
//
//  Created by Niklas Holloh on 24.04.22.
//  Copyright 2026 adesso SE
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//

import Foundation

/// Represents an HTTPHeader key.
public struct HTTPHeader: Hashable, ExpressibleByStringLiteral, Sendable {
    /// The raw string key.
    public let headerKey: String

    /// Creates a new instance of `HTTPHeader`.
    /// - Parameter headerKey: The raw string header key.
    public init(_ headerKey: String) {
        self.headerKey = headerKey
    }

    /// Creates a new instance of `HTTPHeader`.
    /// - Parameter value: The raw string header key.
    public init(stringLiteral value: String) {
        headerKey = value
    }
}

// MARK: - Default Headers

public extension HTTPHeader {
    /// The content type header.
    static let contentType = HTTPHeader("Content-Type")

    /// The authorization header.
    static let authorization = HTTPHeader("Authorization")
}

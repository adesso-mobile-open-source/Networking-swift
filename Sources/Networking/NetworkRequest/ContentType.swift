//
//  ContentType.swift
//  Networking
//
//  Created by Niklas Holloh on 25.08.25.
//  Copyright 2026 adesso SE
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//

/// Represents a Content Type as represented in the header fields.
public struct ContentType: Hashable, ExpressibleByStringLiteral, Sendable {
    /// The raw string value of the content type.
    public let contentTypeString: String

    /// Creates a new instance of `ContentType`.
    /// - Parameter contentTypeString: The raw string value of the content type.
    public init(contentTypeString: String) {
        self.contentTypeString = contentTypeString
    }

    /// Creates a new instance of `HTTPHeader`.
    /// - Parameter value: The raw string header key.
    public init(stringLiteral value: String) {
        self.init(contentTypeString: value)
    }
}

// MARK: - Default Content Types

public extension ContentType {
    /// The content type `application/json`
    static let applicationJson = ContentType(contentTypeString: "application/json")
}

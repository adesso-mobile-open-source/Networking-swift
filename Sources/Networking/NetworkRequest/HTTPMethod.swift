//
//  HTTPMethod.swift
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

/// A HTTP method. May be extended by adding static properties.
public struct HTTPMethod: Sendable, Equatable {
    /// The raw HTTP method string.
    public let methodString: String

    /// Creates a new HTTPMethod instance.
    /// - Parameter methodString: The raw HTTP method string.
    fileprivate init(_ methodString: String) {
        self.methodString = methodString
    }
}

// MARK: - Default HTTP Methods

public extension HTTPMethod {
    /// The HEAD HTTP method.
    static let head: HTTPMethod = .init("HEAD")

    /// The GET HTTP method.
    static let get: HTTPMethod = .init("GET")

    /// The POST HTTP method.
    static let post: HTTPMethod = .init("POST")

    /// The PUT HTTP method.
    static let put: HTTPMethod = .init("PUT")

    /// The PATCH HTTP method.
    static let patch: HTTPMethod = .init("PATCH")

    /// The DELETE HTTP method.
    static let delete: HTTPMethod = .init("DELETE")
}

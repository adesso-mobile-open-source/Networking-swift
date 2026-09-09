//
//  NetworkEnvironment.swift
//  Networking
//
//  Created by Niklas Holloh on 18.08.25.
//  Copyright 2026 adesso SE
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//

/// The `NetworkClient`'s runtime environment.
///
/// Provides the validated base URL that is combined with each request's `URLPath`
/// at call time, and a set of default headers (e.g. API keys) merged into every request.
///
/// Create a `NetworkEnvironment` using the `#URLBase` macro:
///
/// ```swift
/// let env = NetworkEnvironment(
///     base: #URLBase("https://api.example.com/v2"),
///     defaultHeaders: [.apiKey: "secret"]
/// )
/// ```
public struct NetworkEnvironment: Sendable {
    /// The validated base URL. Combined with `NetworkRequest.path` via `+` to form the full endpoint.
    public let base: URLBase
    /// Default HTTP header fields applied to every request (e.g. API keys, environment identifiers).
    /// Request-specific headers override these for duplicate keys.
    public let defaultHeaders: [HTTPHeader: String]

    /// Creates a new `NetworkEnvironment`.
    /// - Parameters:
    ///   - base: The validated base URL. Use `#URLBase(...)` to construct this.
    ///   - defaultHeaders: Default header fields applied to every request. Defaults to `[:]`.
    public init(base: URLBase, defaultHeaders: [HTTPHeader: String] = [:]) {
        self.base = base
        self.defaultHeaders = defaultHeaders
    }
}

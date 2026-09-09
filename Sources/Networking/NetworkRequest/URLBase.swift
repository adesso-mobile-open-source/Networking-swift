//
//  URLBase.swift
//  Networking
//
//  Created by Niklas Holloh on 14.06.26.
//  Copyright 2026 adesso SE
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//

import Foundation

/// A compile-time-validated base URL consisting of scheme, host, and an optional path prefix.
///
/// `URLBase` intentionally forbids query strings and fragments — those belong in
/// `NetworkRequestWithQuery` and `URLPath` respectively. Create instances exclusively
/// via the `#URLBase` macro, which enforces these rules at compile time.
///
/// ```swift
/// let base = #URLBase("https://api.example.com/v2")
/// ```
///
/// Combine with a `URLPath` using `+` to produce a `ResolvedURL`:
///
/// ```swift
/// let resolved: ResolvedURL = base + #URLPath("users/profile")
/// ```
public struct URLBase: Sendable, Equatable {
    /// The raw validated base URL string (no query, no fragment).
    public let value: String

    /// Creates a `URLBase` from a raw string **without compile-time validation**.
    ///
    /// Prefer the `#URLBase` macro, which validates the scheme, host, and
    /// the absence of query/fragment/template characters at compile time.
    /// Use this initializer only when the base URL is not known at compile
    /// time (e.g. test scaffolding or runtime configuration).
    public init(unsafeValue value: String) {
        self.value = value
    }

    /// Unavailable. Use the `#URLBase` macro, which validates the scheme,
    /// host, and path at compile time.
    @available(*, unavailable, message: "Use #URLBase instead — it validates the scheme, host, and path at compile time.")
    public init(_ value: String) {
        fatalError("Use #URLBase instead — it validates the scheme, host, and path at compile time.")
    }

    // MARK: - Composition

    /// Combines this base URL with a `URLPath`, producing a `ResolvedURL`.
    ///
    /// A single `/` separator is inserted between base and path regardless of
    /// whether either side already carries a trailing/leading slash.
    ///
    /// ```swift
    /// let url: ResolvedURL = #URLBase("https://api.example.com") + #URLPath("users/profile")
    /// ```
    public static func + (base: URLBase, path: URLPath) -> ResolvedURL {
        let base = base.value.hasSuffix("/") ? String(base.value.dropLast()) : base.value
        let path = path.value.hasPrefix("/") ? String(path.value.dropFirst()) : path.value
        return ResolvedURL(rawValue: path.isEmpty ? base + "/" : base + "/" + path)
    }
}

// MARK: - ResolvedURL

/// The result of combining a `URLBase` with a `URLPath`.
///
/// `ResolvedURL` is the only type that can produce a `Foundation.URL` for use
/// with `URLSession`. It cannot be constructed directly — obtain one via
/// `URLBase + URLPath`.
///
/// Attach query items with ``appending(queryItems:)``:
///
/// ```swift
/// let resolved = (#URLBase("https://api.example.com") + #URLPath("search"))
///     .appending(queryItems: [URLQueryItem(name: "q", value: "swift")])
/// ```
public struct ResolvedURL: Sendable, Equatable {
    /// The composed URL string.
    public let rawValue: String

    /// The composed URL.
    ///
    /// Constructed by `URLBase + URLPath` using macro-validated inputs, so the
    /// result is always a valid URL. The force-unwrap is intentional and safe.
    public var url: URL { URL(string: rawValue)! }

    internal init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// Returns a new `ResolvedURL` with the given query items appended.
    ///
    /// - Parameter queryItems: The items to append. Passing an empty array
    ///   returns `self` unchanged (no trailing `?` is inserted).
    public func appending(queryItems: [URLQueryItem]) -> ResolvedURL {
        guard !queryItems.isEmpty else { return self }
        var components = URLComponents(string: rawValue)!
        components.queryItems = queryItems
        return ResolvedURL(rawValue: components.string!)
    }
}

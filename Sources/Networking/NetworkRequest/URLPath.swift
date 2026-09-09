//
//  URLPath.swift
//  Networking
//
//  Created by Niklas Holloh on 12.06.26.
//  Copyright 2026 adesso SE
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//

/// A type-safe representation of a URL path segment.
///
/// `URLPath` can only be created via the `#URLPath` or `@URLPathTemplate` macros,
/// which validate or extract the path at compile time. Direct instantiation is
/// intentionally restricted to prevent unvalidated strings from entering the
/// networking layer.
public struct URLPath: Sendable, Equatable {
    /// The raw string value of the path.
    ///
    /// Internal — consumers interact with `URLPath` as an opaque token that is
    /// combined with a `URLBase` via `+` to produce a `ResolvedURL`. Reading the
    /// raw string is an implementation detail of `NetworkClientImpl`.
    let value: String

    /// Creates a `URLPath` from a raw string **without compile-time validation**.
    ///
    /// Prefer the `#URLPath` macro for static paths or `@URLPathTemplate` for
    /// paths with dynamic segments — both validate the path at compile time.
    /// Use this initializer only when the path is not known at compile time
    /// (e.g. test scaffolding or runtime configuration).
    public init(unsafeValue value: String) {
        self.value = value
    }

    /// Unavailable. Use the `#URLPath` macro for static paths or
    /// `@URLPathTemplate` for paths with dynamic segments.
    @available(
        *, unavailable, message: "Use #URLPath for static paths or @URLPathTemplate for dynamic paths — both validate at compile time."
    )
    public init(_ value: String) { fatalError() }
}

//
//  URLBaseMacro.swift
//  Networking
//
//  Created by Niklas Holloh on 14.06.26.
//  Copyright 2026 adesso SE
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//

/// Validates a base URL at compile time and produces a `URLBase` value.
///
/// ```swift
/// let base = #URLBase("https://api.example.com/v2")
/// ```
///
/// The following are rejected at compile time:
/// - Missing scheme (e.g. no `https://`)
/// - Empty host
/// - Query strings (`?`)
/// - Fragments (`#`)
/// - Template parameters (`{`, `}`)
/// - Unencoded spaces or control characters
///
/// Combine with a `URLPath` using `+`:
///
/// ```swift
/// let resolved: ResolvedURL = #URLBase("https://api.example.com") + #URLPath("users/profile")
/// ```
@freestanding(expression)
public macro URLBase(_ url: String) -> URLBase = #externalMacro(
    module: "NetworkingMacros",
    type: "URLBaseMacro"
)

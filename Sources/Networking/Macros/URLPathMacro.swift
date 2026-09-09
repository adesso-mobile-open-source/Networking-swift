//
//  URLPathMacro.swift
//  Networking
//
//  Created by Niklas Holloh on 14.06.26.
//  Copyright 2026 adesso SE
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//

/// Validates a static URL path at compile time and produces a `URLPath` value.
///
/// ```swift
/// var path: URLPath { #URLPath("users/profile") }
/// ```
///
/// The following are rejected at compile time:
/// - Empty strings
/// - Unencoded spaces
/// - Unencoded control characters (U+0000–U+001F, U+007F)
/// - Unencoded `?`, `#`, `{`, `}`
@freestanding(expression)
public macro URLPath(_ path: String) -> URLPath = #externalMacro(
    module: "NetworkingMacros",
    type: "URLPathMacro"
)

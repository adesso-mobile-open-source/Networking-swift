//
//  URLPathTemplate.swift
//  Networking
//
//  Created by Niklas Holloh on 14.06.26.
//  Copyright 2026 adesso SE
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//

/// Validates a URL path template at compile time and generates typed stored properties
/// and a `path` computed property for each `{param}` placeholder.
///
/// Apply to a `NetworkRequest`-conforming type:
///
/// ```swift
/// @URLPathTemplate("users/{id}/posts/{postId}")
/// struct GetPostRequest: NetworkRequest {
///     let method: HTTPMethod = .get
/// }
/// ```
///
/// The macro generates the following members inside the annotated type:
/// ```swift
/// let id: PathParameterStringConvertible
/// let postId: PathParameterStringConvertible
/// var path: URLPath { URLPath(unsafeValue: "users/\(id.stringRepresentation)/posts/\(postId.stringRepresentation)") }
/// ```
///
/// Swift's compiler synthesises a memberwise initialiser from the generated `let` properties.
/// Any type conforming to `PathParameterStringConvertible` can be passed — the library ships
/// conformances for `String`, `Int`, `UInt`, `Float`, `Double`, `Bool`, `UUID`, `Decimal`,
/// and all fixed-width integer variants:
///
/// ```swift
/// let byString = GetPostRequest(id: "42", postId: "7")
/// let byUUID   = GetPostRequest(id: UUID(), postId: UUID())
/// let byInt    = GetPostRequest(id: 1, postId: 7)
/// ```
///
/// The following template strings are rejected at compile time:
/// - Empty string
/// - Unencoded spaces, `?`, or `#` outside placeholder braces
/// - Duplicate parameter names
@attached(member, names: arbitrary)
public macro URLPathTemplate(_ template: String) = #externalMacro(
    module: "NetworkingMacros",
    type: "URLPathTemplateMacro"
)

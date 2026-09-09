//
//  PathParameterStringConvertible.swift
//  Networking
//
//  Created by Niklas Holloh on 16.06.26.
//  Copyright 2026 adesso SE
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//

/// A type that can be used as a path parameter in an `@URLPathTemplate`-annotated request.
///
/// The `@URLPathTemplate` macro generates stored properties typed as
/// `PathParameterStringConvertible` for each `{param}` placeholder in the template.
/// At runtime, each property's `stringRepresentation` is interpolated into the path.
///
/// The library ships conformances for the most common Swift and Foundation types —
/// see `Foundation+PathParameterStringConvertible.swift` for the full list. Common
/// types work with no extra code:
///
/// ```swift
/// @URLPathTemplate("users/{id}")
/// struct GetUserRequest: NetworkRequestWithResponse {
///     typealias ResponseBody = User
///     let method: HTTPMethod = .get
/// }
///
/// let byString = GetUserRequest(id: "42")
/// let byUUID   = GetUserRequest(id: UUID())
/// let byInt    = GetUserRequest(id: 42)
/// ```
///
/// For your own model ID types, add an explicit conformance:
///
/// ```swift
/// extension UserID: PathParameterStringConvertible {
///     public var stringRepresentation: String { value.uuidString }
/// }
///
/// let request = GetUserRequest(id: myUserID)
/// ```
///
/// If your type already conforms to `CustomStringConvertible`, the constrained extension
/// in this module provides `stringRepresentation` automatically once you declare the
/// conformance — no body required:
///
/// ```swift
/// extension MyID: PathParameterStringConvertible {}
/// // stringRepresentation returns description automatically
/// ```
public protocol PathParameterStringConvertible: Sendable {
    /// The string that will be interpolated into the URL path.
    var stringRepresentation: String { get }
}

// MARK: - Convenience default for CustomStringConvertible

/// Provides a free `stringRepresentation` implementation for any type that
/// *both* explicitly adopts `PathParameterStringConvertible` and already
/// conforms to `CustomStringConvertible`. Adopt `PathParameterStringConvertible`
/// on your type to opt in; `description` will be used unless you override
/// `stringRepresentation` yourself.
public extension PathParameterStringConvertible where Self: CustomStringConvertible {
    var stringRepresentation: String { description }
}

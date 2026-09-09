//
//  NetworkRequest.swift
//  Networking
//
//  Created by Niklas Holloh on 24.04.22.
//  Copyright 2026 adesso SE
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//

/// The base protocol for all network requests sent through `NetworkClient`.
///
/// Every endpoint is modelled as a value type conforming to `NetworkRequest`.
/// Additional traits — query parameters, a request body, an expected response, etc. —
/// are expressed by conforming to the matching `NetworkRequestWith*` protocol alongside
/// this one.
///
/// ## Specifying the path
///
/// Use the `#URLPath` macro for static paths:
/// ```swift
/// struct GetProfileRequest: NetworkRequest {
///     let method: HTTPMethod = .get
///     var path: URLPath { #URLPath("users/profile") }
/// }
/// ```
///
/// Use `@URLPathTemplate` for paths with dynamic segments:
/// ```swift
/// @URLPathTemplate("users/{id}/posts/{postId}")
/// struct GetPostRequest: NetworkRequest {
///     let method: HTTPMethod = .get
/// }
/// ```
///
/// The macro generates a `let` property typed as `PathParameterStringConvertible` for
/// each placeholder, so `String`, `UUID`, `Int`, and other common types can be passed
/// directly without manual string conversion.
///
/// The `NetworkClient` always composes the request path with the configured
/// `NetworkEnvironment.base` URL at call time.
public protocol NetworkRequest: Sendable {
    /// The HTTP method for this request.
    var method: HTTPMethod { get }

    /// The URL path for this request, relative to `NetworkEnvironment.base`.
    ///
    /// Prefer creating `URLPath` values via the `#URLPath` macro for static paths
    /// or the `@URLPathTemplate` macro for paths with dynamic segments.
    var path: URLPath { get }

    /// Request-specific HTTP header fields.
    ///
    /// These are merged with any headers set by interceptors and the environment's
    /// `defaultHeaders`. Request-specific headers take precedence over environment
    /// headers for duplicate keys. Defaults to `[:]`.
    var headers: [HTTPHeader: String] { get }

    /// The HTTP status codes that are considered successful for this request.
    ///
    /// `NetworkClient` validates the response status code against this range immediately
    /// after receiving the response. Codes outside the range cause an
    /// `InterceptorError.errorStatusCode` to be thrown.
    ///
    /// Override this property to accept a different range for a specific endpoint:
    /// ```swift
    /// struct SubmitRequest: NetworkRequest {
    ///     var allowedStatusCodes: Range<Int> { 200..<204 }
    ///     // ...
    /// }
    /// ```
    ///
    /// Defaults to `200..<300`.
    var allowedStatusCodes: Range<Int> { get }
}

public extension NetworkRequest {
    /// Default implementation — returns an empty dictionary.
    var headers: [HTTPHeader: String] { [:] }

    /// Default implementation — accepts any 2xx status code.
    var allowedStatusCodes: Range<Int> { 200 ..< 300 }
}

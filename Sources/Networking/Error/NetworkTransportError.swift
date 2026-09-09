//
//  NetworkTransportError.swift
//  Networking
//
//  Created by Simon Feistel on 02.09.25.
//  Copyright 2026 adesso SE
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//

import Foundation

/// Errors originating from network transport, connectivity, TLS, HTTP status-code validation,
/// or the request/response interceptor pipeline.
///
/// This is the only error type that `NetworkRequestInterceptor`, `NetworkResponseInterceptor`,
/// and `NetworkErrorInterceptor` can throw or receive — the interceptor pipeline never touches
/// request/response body encoding, response decoding, or required-header validation, so those
/// concerns are modeled by separate, narrower error types (see `NetworkSendError`,
/// `NetworkSendResponseError`, `NetworkSendOptionalResponseError`, `NetworkSendHeaderResponseError`)
/// which each embed `NetworkTransportError` via a `.transport(_:)` case.
///
/// ## Accessing error response data
///
/// For the `.errorStatusCode` case, you can access the full HTTP response including
/// the raw body data to decode structured error responses:
///
/// ```swift
/// do {
///     try await client.send(request: request)
/// } catch let .transport(.errorStatusCode(code, response)) {
///     // Decode structured error from response.data
///     if let apiError = try? JSONDecoder().decode(APIError.self, from: response.data) {
///         print("API error: \(apiError.message)")
///     }
/// }
/// ```
///
/// See [Advanced Response Handling](Documentation/Advanced_Response_Handling.md) for
/// detailed patterns and examples.
public enum NetworkTransportError: Error, Equatable {
    /// Thrown when there is no active network connection
    /// (i.e. `NetworkPathMonitoring.currentPathIsSatisfied` is `false`).
    case noNetworkConnection

    /// A non-OK status code was received. You can mutate this behaviour by overriding
    /// the `ValidateHTTPStatusResponseInterceptor` in the `responseInterceptor`.
    ///
    /// The associated `HTTPResponse` contains:
    /// - `data: Data` — The raw response body (use this to decode error responses)
    /// - `urlResponse: HTTPURLResponse` — Full HTTP response with headers and status
    /// - `request: HTTPRequest` — The original request
    ///
    /// ## Example: Decoding error bodies
    ///
    /// ```swift
    /// catch let .transport(.errorStatusCode(code, response)) {
    ///     let errorBody = try? JSONDecoder().decode(APIError.self, from: response.data)
    /// }
    /// ```
    case errorStatusCode(code: Int, response: HTTPResponse)

    /// Thrown when an internal precondition required by an interceptor is not met.
    /// This typically indicates a programming error or an unexpected state in the
    /// request‑handling pipeline. Also used as an escape hatch for custom interceptors
    /// to surface arbitrary domain errors (e.g. `SessionError.notAuthenticated`) through
    /// the typed-throws pipeline.
    case interceptorError(any Error & Equatable)

    /// Thrown when a secure TLS/SSL connection could not be established.
    ///
    /// This covers failures from `NSPinnedDomains` identity pinning (which surfaces as
    /// `URLError.serverCertificateUntrusted`) as well as other TLS-related errors such as
    /// expired or unknown-root certificates and general secure-connection failures.
    case secureConnectionNotPossible

    /// Networking encountered an unknown URLError.
    case unknownURLError(URLError)

    /// The response received is no HTTPURLResponse.
    case responseIsNoHTTPURLResponse

    /// Any other, untyped SDK errors that may occur with their localized description.
    case unknownError(String)

    public static func == (lhs: NetworkTransportError, rhs: NetworkTransportError) -> Bool {
        switch (lhs, rhs) {
        case (.noNetworkConnection, .noNetworkConnection):
            return true
        case let (.errorStatusCode(lCode, _), .errorStatusCode(rCode, _)):
            return lCode == rCode
        case let (.interceptorError(lError), .interceptorError(rError)):
            return areEqual(lError, rError)
        case (.secureConnectionNotPossible, .secureConnectionNotPossible):
            return true
        case let (.unknownURLError(lError), .unknownURLError(rError)):
            return lError == rError
        case (.responseIsNoHTTPURLResponse, .responseIsNoHTTPURLResponse):
            return true
        case let (.unknownError(lStr), .unknownError(rStr)):
            return lStr == rStr
        default:
            return false
        }
    }

    private static func areEqual<T: Equatable>(_ lhs: T, _ rhs: any Error & Equatable) -> Bool {
        // Compare existential types by checking if they're the same concrete type
        // and then comparing using that type's Equatable implementation
        guard let rhs = rhs as? T else {
            return false
        }
        return lhs == rhs
    }
}

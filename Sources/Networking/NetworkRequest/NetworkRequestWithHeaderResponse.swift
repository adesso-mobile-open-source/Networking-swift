//
//  NetworkRequestWithHeaderResponse.swift
//  Networking
//
//  Created by Simon Feistel on 15.10.25.
//  Copyright 2026 adesso SE
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//

/// A `NetworkRequest` whose result is a set of HTTP response headers rather than a body.
///
/// Use this protocol for endpoints like `HEAD` requests or token-refresh flows where the
/// meaningful data is carried in response headers, not the body.
///
/// ```swift
/// struct FetchAuthTokenRequest: NetworkRequest, NetworkRequestWithHeaderResponse {
///     let method: HTTPMethod = .head
///     var path: URLPath { #URLPath("auth/session") }
///     var requiredHeaders: [String] { ["X-Session-Token", "X-Expires-At"] }
/// }
///
/// let headers = try await NetworkClient.send(request: FetchAuthTokenRequest())
/// let token = headers["X-Session-Token"]
/// ```
///
/// `NetworkClient` throws `NetworkClientImpl.Error.headerFieldsMissing` if any header
/// listed in `requiredHeaders` is absent from the response.
public protocol NetworkRequestWithHeaderResponse: NetworkRequest {
    /// The header field names that must be present in the HTTP response.
    ///
    /// Names are matched case-insensitively by `HTTPURLResponse`.
    var requiredHeaders: [String] { get }
}

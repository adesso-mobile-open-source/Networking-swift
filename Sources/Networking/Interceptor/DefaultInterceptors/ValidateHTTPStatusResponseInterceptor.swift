//
//  ValidateHTTPStatusResponseInterceptor.swift
//  Networking
//
//  Created by Niklas Holloh on 17.05.22.
//  Copyright 2026 adesso SE
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//

import Foundation

/// A response interceptor that rejects HTTP responses whose status code is not in `allowedStatusCodes`.
///
/// > Note: `NetworkClient` already performs status-code validation automatically using
/// > `NetworkRequest.allowedStatusCodes` (default `200..<300`). Use this interceptor only when you need
/// > supplementary, interceptor-level validation — for example, applying a different accepted range
/// > globally across all requests via `NetworkClientConfiguration.responseInterceptor`.
public final class ValidateHTTPStatusResponseInterceptor: NetworkResponseInterceptor {
    /// The default instance, accepting all status codes `200..<300`.
    public static let `default` = ValidateHTTPStatusResponseInterceptor()

    /// Get the currently allowed status codes.
    public let allowedStatusCodes: Set<Int>

    /// Create a new `ValidateHTTPStatusResponseInterceptor` with custom allowed status codes.
    /// - Parameter allowedStatusCodes: A range of allowed status codes.
    public convenience init(allowedStatusCodes: Range<Int> = 200 ..< 300) {
        self.init(allowedStatusCodes: Set(allowedStatusCodes))
    }

    /// Create a new `ValidateHTTPStatusResponseInterceptor` with custom allowed status codes.
    /// - Parameter allowedStatusCodes: A set of allowed status codes.
    public init(allowedStatusCodes: Set<Int>) {
        self.allowedStatusCodes = allowedStatusCodes
    }

    public func intercept(response: inout HTTPResponse) async throws(NetworkTransportError) -> NetworkResponseInterceptorResult {
        guard allowedStatusCodes.contains(response.urlResponse.statusCode) else {
            throw .errorStatusCode(code: response.urlResponse.statusCode, response: response)
        }

        return .defaultHandling
    }
}

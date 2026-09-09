//
//  NetworkErrorInterceptor.swift
//  Networking
//
//  Created by Kay Kartschewsky on 25.02.26.
//  Copyright 2026 adesso SE
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//

import Foundation

/// A result returned by the network error interceptor.
public enum NetworkErrorInterceptorResult: Sendable {
    /// Rethrow the error to the call site. Overridden by `.retryRequest` when combined with another result.
    case defaultHandling

    /// Retry the request after finishing interceptions.
    case retryRequest

    /// Combines `self` and another result to produce a joint result.
    /// - Parameter other: The other result.
    /// - Returns: A joint result.
    func combine(with other: Self) -> Self {
        switch (self, other) {
        case (.defaultHandling, .retryRequest):
            .retryRequest
        case (.retryRequest, .defaultHandling):
            .retryRequest
        default:
            self
        }
    }
}

/// An error interceptor, which will be executed when a network request fails or a response
/// interceptor throws a `NetworkTransportError`.
public protocol NetworkErrorInterceptor: Sendable {
    /// Intercepts an error thrown during network request execution.
    /// - Parameter error: The `NetworkTransportError` to handle.
    /// - Returns: A result indicating whether to retry the request or proceed with default handling.
    func intercept(error: NetworkTransportError) async -> NetworkErrorInterceptorResult
}

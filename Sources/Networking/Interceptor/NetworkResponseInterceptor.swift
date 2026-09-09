//
//  NetworkResponseInterceptor.swift
//  Networking
//
//  Created by Niklas Holloh on 25.04.22.
//  Copyright 2026 adesso SE
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//

import Foundation

/// A result returned by the network response interceptor.
public enum NetworkResponseInterceptorResult: Sendable {
    /// Continue with normal response processing. Overridden by `.retryRequest` when combined with another result.
    case defaultHandling

    /// Retry the request after finishing interceptions.
    case retryRequest

    /// Combines `self` and another InterceptorResult, to produce a joint result.
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

/// A response interceptor, which will be executed after the backend's response has been received.
public protocol NetworkResponseInterceptor: Sendable {
    /// Intercepts a response as received by the backend. Data may be mutated on the original response.
    /// - Parameter response: The response, on which mutation is possible.
    func intercept(response: inout HTTPResponse) async throws(NetworkTransportError) -> NetworkResponseInterceptorResult
}

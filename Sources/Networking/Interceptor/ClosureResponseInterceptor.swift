//
//  ClosureResponseInterceptor.swift
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

/// A response interceptor, which receives a closure to process the HTTPResponse.
public final class ClosureResponseInterceptor: NetworkResponseInterceptor {
    private let closure: @Sendable (inout HTTPResponse) async throws(NetworkTransportError) -> NetworkResponseInterceptorResult

    /// Creates a response interceptor, which receives a closure to process the HTTPResponse.
    /// - Parameter closure: The closure which receives and mutates the HTTPResponse.
    public init(
        _ closure: @escaping @Sendable (inout HTTPResponse) async throws(NetworkTransportError) -> NetworkResponseInterceptorResult
    ) {
        self.closure = closure
    }

    public func intercept(response: inout HTTPResponse) async throws(NetworkTransportError) -> NetworkResponseInterceptorResult {
        try await closure(&response)
    }

    /// A no-operation empty closure response interceptor.
    public static let empty = ClosureResponseInterceptor { _ in .defaultHandling }
}

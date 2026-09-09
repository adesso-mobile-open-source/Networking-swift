//
//  ClosureErrorInterceptor.swift
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

/// An error interceptor, which receives a closure to process the `NetworkTransportError`.
public final class ClosureErrorInterceptor: NetworkErrorInterceptor {
    private let closure: @Sendable (NetworkTransportError) async -> NetworkErrorInterceptorResult

    /// Creates an error interceptor, which receives a closure to process the `NetworkTransportError`.
    /// - Parameter closure: The closure which receives the error and returns a handling decision.
    public init(_ closure: @escaping @Sendable (NetworkTransportError) async -> NetworkErrorInterceptorResult) {
        self.closure = closure
    }

    public func intercept(error: NetworkTransportError) async -> NetworkErrorInterceptorResult {
        await closure(error)
    }
    
    /// A no-operation empty closure error interceptor.
    public static let empty = ClosureErrorInterceptor { _ in .defaultHandling }
}

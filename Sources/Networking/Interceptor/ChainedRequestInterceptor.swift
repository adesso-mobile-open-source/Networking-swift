//
//  ChainedRequestInterceptor.swift
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

/// An interceptor type that chains two child interceptors together and executes them in order `first` -> `second`.
public final class ChainedRequestInterceptor: NetworkRequestInterceptor, ExpressibleByArrayLiteral {
    private let first: NetworkRequestInterceptor
    private let second: NetworkRequestInterceptor

    init(first: NetworkRequestInterceptor, second: NetworkRequestInterceptor) {
        self.first = first
        self.second = second
    }
    
    public convenience init(arrayLiteral interceptors: NetworkRequestInterceptor...) {
        guard let first = interceptors.first else {
            self.init(first: ClosureRequestInterceptor.empty, second: ClosureRequestInterceptor.empty)
            return
        }

        self.init(first: first, second: ChainedRequestInterceptor.chain(inOrder: Array(interceptors[1...])))
    }

    public func intercept(request: inout HTTPRequest) async throws(NetworkTransportError) {
        try await first.intercept(request: &request)
        try await second.intercept(request: &request)
    }
}

public extension NetworkRequestInterceptor {
    /// Combines this (`self`) interceptor with another one, where this interceptor is executed **after** the other interceptor.
    /// - Parameter other: The other interceptor to execute **before** this interceptor instance.
    /// - Returns: A new `NetworkRequestInterceptor`, which executes both interceptors in order.
    func chain(after other: NetworkRequestInterceptor) -> NetworkRequestInterceptor {
        ChainedRequestInterceptor(first: other, second: self)
    }

    /// Combines this (`self`) interceptor with another one, where this interceptor is executed **before** the other interceptor.
    /// - Parameter other: The other interceptor to execute **after** this interceptor instance.
    /// - Returns: A new `NetworkRequestInterceptor`, which executes both interceptors in order.
    func chain(before other: NetworkRequestInterceptor) -> NetworkRequestInterceptor {
        ChainedRequestInterceptor(first: self, second: other)
    }

    /// Combines an ordered array of `[NetworkRequestInterceptor]` into a single `NetworkRequestInterceptor`,
    /// which executes the interceptors in order of the array.
    /// - Parameter interceptors: The ordered array of interceptors.
    /// - Returns: A new `NetworkRequestInterceptor`, which executes all interceptors in order of the array provided.
    static func chain(inOrder interceptors: [NetworkRequestInterceptor]) -> NetworkRequestInterceptor {
        guard let first = interceptors.first else {
            return ClosureRequestInterceptor { _ in }
        }

        return interceptors[1...].reduce(first) { chainedInterceptor, nextInterceptor in
            chainedInterceptor.chain(before: nextInterceptor)
        }
    }
}

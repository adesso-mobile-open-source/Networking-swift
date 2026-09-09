//
//  ChainedResponseInterceptor.swift
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
public final class ChainedResponseInterceptor: NetworkResponseInterceptor, ExpressibleByArrayLiteral {
    private let first: NetworkResponseInterceptor
    private let second: NetworkResponseInterceptor

    init(first: NetworkResponseInterceptor, second: NetworkResponseInterceptor) {
        self.first = first
        self.second = second
    }

    public convenience init(arrayLiteral interceptors: NetworkResponseInterceptor...) {
        guard let first = interceptors.first else {
            self.init(first: ClosureResponseInterceptor.empty, second: ClosureResponseInterceptor.empty)
            return
        }

        self.init(first: first, second: ChainedResponseInterceptor.chain(inOrder: Array(interceptors[1...])))
    }

    public func intercept(response: inout HTTPResponse) async throws(NetworkTransportError) -> NetworkResponseInterceptorResult {
        let firstResult = try await first.intercept(response: &response)
        let secondResult = try await second.intercept(response: &response)
        return firstResult.combine(with: secondResult)
    }
}

public extension NetworkResponseInterceptor {
    /// Combines this (`self`) interceptor with another one, where this interceptor is executed **after** the other interceptor.
    /// - Parameter other: The other interceptor to execute **before** this interceptor instance.
    /// - Returns: A new `NetworkResponseInterceptor`, which executes both interceptors in order.
    func chain(after other: NetworkResponseInterceptor) -> NetworkResponseInterceptor {
        ChainedResponseInterceptor(first: other, second: self)
    }

    /// Combines this (`self`) interceptor with another one, where this interceptor is executed **before** the other interceptor.
    /// - Parameter other: The other interceptor to execute **after** this interceptor instance.
    /// - Returns: A new `NetworkResponseInterceptor`, which executes both interceptors in order.
    func chain(before other: NetworkResponseInterceptor) -> NetworkResponseInterceptor {
        ChainedResponseInterceptor(first: self, second: other)
    }

    /// Combines an ordered array of `[NetworkResponseInterceptor]` into a single `NetworkResponseInterceptor`,
    /// which executes the interceptors in order of the array.
    /// - Parameter interceptors: The ordered array of interceptors.
    /// - Returns: A new `NetworkResponseInterceptor`, which executes all interceptors in order of the array provided.
    static func chain(inOrder interceptors: [NetworkResponseInterceptor]) -> NetworkResponseInterceptor {
        guard let first = interceptors.first else {
            return ClosureResponseInterceptor { _ in .defaultHandling }
        }

        return interceptors[1...].reduce(first) { chainedInterceptor, nextInterceptor in
            chainedInterceptor.chain(before: nextInterceptor)
        }
    }
}

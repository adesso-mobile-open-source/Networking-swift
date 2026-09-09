//
//  ChainedErrorInterceptor.swift
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

/// An interceptor type that chains two child interceptors together and executes them in order `first` -> `second`.
public final class ChainedErrorInterceptor: NetworkErrorInterceptor, ExpressibleByArrayLiteral {
    private let first: NetworkErrorInterceptor
    private let second: NetworkErrorInterceptor

    init(first: NetworkErrorInterceptor, second: NetworkErrorInterceptor) {
        self.first = first
        self.second = second
    }

    public convenience init(arrayLiteral interceptors: NetworkErrorInterceptor...) {
        guard let first = interceptors.first else {
            self.init(first: ClosureErrorInterceptor.empty, second: ClosureErrorInterceptor.empty)
            return
        }

        self.init(first: first, second: ChainedErrorInterceptor.chain(inOrder: Array(interceptors[1...])))
    }

    public func intercept(error: NetworkTransportError) async -> NetworkErrorInterceptorResult {
        let firstResult = await first.intercept(error: error)
        let secondResult = await second.intercept(error: error)
        return firstResult.combine(with: secondResult)
    }
}

public extension NetworkErrorInterceptor {
    /// Combines this (`self`) interceptor with another one, where this interceptor is executed **after** the other interceptor.
    /// - Parameter other: The other interceptor to execute **before** this interceptor instance.
    /// - Returns: A new `NetworkErrorInterceptor`, which executes both interceptors in order.
    func chain(after other: NetworkErrorInterceptor) -> NetworkErrorInterceptor {
        ChainedErrorInterceptor(first: other, second: self)
    }

    /// Combines this (`self`) interceptor with another one, where this interceptor is executed **before** the other interceptor.
    /// - Parameter other: The other interceptor to execute **after** this interceptor instance.
    /// - Returns: A new `NetworkErrorInterceptor`, which executes both interceptors in order.
    func chain(before other: NetworkErrorInterceptor) -> NetworkErrorInterceptor {
        ChainedErrorInterceptor(first: self, second: other)
    }

    /// Combines an ordered array of `[NetworkErrorInterceptor]` into a single `NetworkErrorInterceptor`,
    /// which executes the interceptors in order of the array.
    /// - Parameter interceptors: The ordered array of interceptors.
    /// - Returns: A new `NetworkErrorInterceptor`, which executes all interceptors in order of the array provided.
    static func chain(inOrder interceptors: [NetworkErrorInterceptor]) -> NetworkErrorInterceptor {
        guard let first = interceptors.first else {
            return ClosureErrorInterceptor { _ in .defaultHandling }
        }

        return interceptors[1...].reduce(first) { chainedInterceptor, nextInterceptor in
            chainedInterceptor.chain(before: nextInterceptor)
        }
    }
}

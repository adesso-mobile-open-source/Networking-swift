//
//  ClosureRequestInterceptor.swift
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

/// A request interceptor, which receives a closure to process the HTTPRequest.
public final class ClosureRequestInterceptor: NetworkRequestInterceptor {
    private let closure: @Sendable (inout HTTPRequest) async throws(NetworkTransportError) -> Void

    /// Creates a request interceptor, which receives a closure to process the HTTPRequest.
    /// - Parameter closure: The closure which receives and mutates the HTTPRequest.
    public init(_ closure: @Sendable @escaping (inout HTTPRequest) async throws(NetworkTransportError) -> Void) {
        self.closure = closure
    }

    public func intercept(request: inout HTTPRequest) async throws(NetworkTransportError) {
        try await closure(&request)
    }

    /// A no-operation empty closure request interceptor.
    public static let empty = ClosureRequestInterceptor { _ in }
}

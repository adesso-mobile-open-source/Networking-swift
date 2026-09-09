//
//  AddRequestIdInterceptor.swift
//  Networking
//
//  Created by Niklas Holloh on 25.08.25.
//  Copyright 2026 adesso SE
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//

/// Use the `AddRequestIdInterceptor` to add the request's UUID to the header fields.
public final class AddRequestIdInterceptor: NetworkRequestInterceptor, Sendable {
    /// The default instance, adding the request id to `x-correlation-id`.
    public static let `default` = AddRequestIdInterceptor()

    /// The key of the header where the request Id should be placed.
    public let key: HTTPHeader

    /// Create a new `AddRequestIdInterceptor` with custom header key.
    /// - Parameter key: The key of the header where to place the request UUID. Default: `X-Correlation-ID`.
    public init(key: HTTPHeader = "X-Correlation-ID") {
        self.key = key
    }

    public func intercept(request: inout HTTPRequest) async throws(NetworkTransportError) {
        request.urlRequest.setValue(request.uuid.uuidString, forHTTPHeaderField: key.headerKey)
    }
}

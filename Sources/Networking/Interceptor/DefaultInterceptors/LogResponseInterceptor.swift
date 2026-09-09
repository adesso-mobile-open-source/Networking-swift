//
//  LogResponseInterceptor.swift
//  Networking
//
//  Created by Niklas Holloh on 12.05.22.
//  Copyright 2026 adesso SE
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//

import Foundation

/// Use the `LogResponseInterceptor` to redirect response logs to your default logging system via closure.
public final class LogResponseInterceptor: NetworkResponseInterceptor {
    private let log: @Sendable (String) -> Void

    /// Creates a new `LogResponseInterceptor`.
    /// - Parameter log: The closure called to log the network response. Hand the string parameter to your
    /// logging system.
    public init(log: @escaping @Sendable (String) -> Void) {
        self.log = log
    }

    public func intercept(response: inout HTTPResponse) throws(NetworkTransportError) -> NetworkResponseInterceptorResult {
        var stringEncodedBody: String?
        if !response.data.isEmpty {
            stringEncodedBody = String(data: response.data, encoding: .utf8)
        }

        let message = """

        📥 Received URL response:
        - ID: \(response.request.uuid)
        - URL: \(response.request.urlRequest.url?.absoluteString ?? "nil")
        - Method: \(response.request.urlRequest.httpMethod ?? "nil")
        - Status: \(response.urlResponse.statusCode)
        - Headers:
          \(response.urlResponse.allHeaderFields.debugDescription)
        - Body:
          \(stringEncodedBody ?? "nil")
        """

        log(message)

        return .defaultHandling
    }
}

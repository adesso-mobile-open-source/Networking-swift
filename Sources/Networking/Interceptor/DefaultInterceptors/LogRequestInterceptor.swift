//
//  LogRequestInterceptor.swift
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

/// Use the `LogRequestInterceptor` to redirect request logs to your default logging system via closure.
public final class LogRequestInterceptor: NetworkRequestInterceptor {
    private let log: @Sendable (String) -> Void

    /// Creates a new `LogRequestInterceptor`.
    /// - Parameter log: The closure called to log the network request. Hand the string parameter to your
    /// logging system.
    public init(log: @Sendable @escaping (String) -> Void) {
        self.log = log
    }

    public func intercept(request: inout HTTPRequest) {
        var stringEncodedBody: String?
        if let body = request.urlRequest.httpBody {
            stringEncodedBody = String(data: body, encoding: .utf8)
        }

        let message = """

        📤 Sending URL request:
        - ID: \(request.uuid)
        - URL: \(request.urlRequest.url?.absoluteString ?? "nil")
        - Method: \(request.urlRequest.httpMethod ?? "nil")
        - Headers:
          \(request.urlRequest.allHTTPHeaderFields.debugDescription)
        - Body:
          \(stringEncodedBody ?? "nil")
        """

        log(message)
    }
}

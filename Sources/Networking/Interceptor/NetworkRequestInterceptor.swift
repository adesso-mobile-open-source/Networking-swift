//
//  NetworkRequestInterceptor.swift
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

/// A request interceptor, which will be executed before the request is sent to the backend.
public protocol NetworkRequestInterceptor: Sendable {
    /// Intercepts a request as sent to the backend. Data may be mutated on the original request.
    /// - Parameter request: The request, on which mutation is possible.
    func intercept(request: inout HTTPRequest) async throws(NetworkTransportError)
}

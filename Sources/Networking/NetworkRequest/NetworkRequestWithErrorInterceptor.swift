//
//  NetworkRequestWithErrorInterceptor.swift
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

/// Extends a `NetworkRequest` so it can define custom error interceptors. These are executed **after** the
/// `NetworkClient` default error interceptors are run.
public protocol NetworkRequestWithErrorInterceptor: NetworkRequest {
    /// A singular error interceptor to be run after default `NetworkClient` error interceptors are executed.
    /// Use `myInterceptor.chain(_:)` to combine multiple `NetworkErrorInterceptor` instances
    /// into a single one.
    var errorInterceptor: NetworkErrorInterceptor { get }
}

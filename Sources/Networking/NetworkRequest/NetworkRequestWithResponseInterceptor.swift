//
//  NetworkRequestWithResponseInterceptor.swift
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

/// Extends a `NetworkRequest` so it can define custom response interceptors. These are executed **after** the
/// `NetworkClient` default response interceptor is run.
public protocol NetworkRequestWithResponseInterceptor: NetworkRequest {
    /// A singular response interceptor to be run after the global `NetworkClient` response interceptor is executed.
    /// Use `myInterceptor.chain(_:)` to combine multiple `NetworkResponseInterceptor` instances
    /// into a single one.
    var responseInterceptor: NetworkResponseInterceptor { get }
}

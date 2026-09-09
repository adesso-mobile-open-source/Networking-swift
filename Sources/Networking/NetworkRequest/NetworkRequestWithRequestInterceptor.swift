//
//  NetworkRequestWithRequestInterceptor.swift
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

/// Extends a `NetworkRequest` so it can define custom request interceptors. These are executed **before** the
/// `NetworkClient` default request interceptors are run.
public protocol NetworkRequestWithRequestInterceptor: NetworkRequest {
    /// A singular request interceptor to be run before default `NetworkClient` interceptors are executed.
    /// Use `myInterceptor.chain(_:)` to combine multiple `NetworkRequestInterceptor` instances
    /// into a single one.
    var requestInterceptor: NetworkRequestInterceptor { get }
}

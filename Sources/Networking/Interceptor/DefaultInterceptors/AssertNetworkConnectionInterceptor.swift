//
//  AssertNetworkConnectionInterceptor.swift
//  Networking
//
//  Created by Simon Feistel on 02.09.25.
//  Copyright 2026 adesso SE
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//

import Network

/// An interceptor that ensures a valid network connection is available before allowing a network request to proceed.
public actor AssertNetworkConnectionInterceptor: NetworkRequestInterceptor {
    /// The underlying network path monitor used to observe connectivity status.
    private let monitor: NetworkPathMonitoring

    /// Creates a new interceptor with a custom network path monitor.
    ///
    /// - Parameter monitor: An object conforming to `NetworkPathMonitoring` used to observe network status.
    ///                     The monitor is started immediately upon initialization.
    public init(monitor: NetworkPathMonitoring) {
        self.monitor = monitor
        monitor.start(queue: .global(qos: .userInitiated))
    }

    /// Intercepts a network request and throws if there is no active network connection.
    ///
    /// - Parameter request: The HTTP request to be intercepted (unused in this interceptor).
    /// - Throws: `NetworkTransportError.noNetworkConnection` if the current network path is not satisfied.
    public func intercept(request _: inout Networking.HTTPRequest) async throws(NetworkTransportError) {
        // unfortunately we cannot work with the `AsyncSequence` conformance of `NWPathMonitor` because it is only available since iOS 17.0
        guard monitor.currentPathStatus == .satisfied else {
            throw .noNetworkConnection
        }
    }
}

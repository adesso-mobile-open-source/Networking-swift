//
//  NetworkPathMonitoring.swift
//  Networking
//
//  Created by Simon Feistel on 04.09.25.
//  Copyright 2026 adesso SE
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//

import Network

/// A protocol defining the interface for monitoring network path status.
public protocol NetworkPathMonitoring {
    /// Starts the network path monitor.
    func start(queue: DispatchQueue)

    /// Stops the network path monitor.
    func cancel()

    /// A Boolean value indicating whether the current network path is satisfied.
    var currentPathStatus: NWPath.Status { get }
}

extension NWPathMonitor: NetworkPathMonitoring {
    public var currentPathStatus: NWPath.Status {
        currentPath.status
    }
}

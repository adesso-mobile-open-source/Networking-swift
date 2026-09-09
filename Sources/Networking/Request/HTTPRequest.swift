//
//  HTTPRequest.swift
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

/// An internal representation of the HTTPRequest which may or may not have been sent.
public struct HTTPRequest: Sendable, Equatable {
    /// The unique ID of the request.
    public let uuid = UUID()

    /// The underlying URLRequest.
    public var urlRequest: URLRequest

    /// The underlying request configuration, producing this `HTTPRequest` object.
    public let configuration: any NetworkRequest

    /// The network environment used to construct this request.
    public let environment: NetworkEnvironment

    /// Computes partial equality based on the urlRequest and uuid properties of two HTTPRequests.
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.uuid == rhs.uuid && lhs.urlRequest == rhs.urlRequest
    }

    /// Creates a new instance of HTTPRequest.
    /// - Parameters:
    ///   - urlRequest: The `URLRequest` to be sent.
    ///   - configuration: The underlying request configuration.
    ///   - environment: The environment used to compose the request URL.
    init(urlRequest: URLRequest, configuration: any NetworkRequest, environment: NetworkEnvironment) {
        self.urlRequest = urlRequest
        self.configuration = configuration
        self.environment = environment
    }
}

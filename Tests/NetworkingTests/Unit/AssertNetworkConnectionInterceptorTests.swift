//
//  AssertNetworkConnectionInterceptorTests.swift
//  Networking
//
//  Created by Simon Feistel on 02.09.25.
//  Copyright 2026 adesso SE
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//

import Foundation
import Network
@testable import Networking
import Testing

private final class NetworkPathMonitoringSpy: NetworkPathMonitoring, @unchecked Sendable {
    var startCallsCount = 0
    var cancelCallsCount = 0

    func start(queue _: DispatchQueue) {
        startCallsCount += 1
    }

    func cancel() {
        cancelCallsCount += 1
    }

    var currentPathStatus: NWPath.Status = .satisfied
}

struct AssertNetworkConnectionInterceptorTests {
    @Test
    func `init when Interceptor Instantiated expect Monitor Start Called`() {
        // Given
        let spy = NetworkPathMonitoringSpy()

        // When
        _ = AssertNetworkConnectionInterceptor(monitor: spy)

        // Then
        #expect(spy.startCallsCount == 1)
    }

    @Test
    func `intercept when Network Satisfied does Not Throw`() async throws {
        // Given
        let spy = NetworkPathMonitoringSpy()
        spy.currentPathStatus = .satisfied
        let interceptor = AssertNetworkConnectionInterceptor(monitor: spy)
        let urlRequest = URLRequest(url: URL(string: "https://api.example.com")!)
        var request = Networking.HTTPRequest(urlRequest: urlRequest)

        // When Then
        try await interceptor.intercept(request: &request)
    }

    @Test
    func `intercept when Network Unsatisfied throws No Network Connection`() async {
        // Given
        let spy = NetworkPathMonitoringSpy()
        spy.currentPathStatus = .unsatisfied
        let interceptor = AssertNetworkConnectionInterceptor(monitor: spy)
        let urlRequest = URLRequest(url: URL(string: "https://api.example.com")!)
        var request = Networking.HTTPRequest(urlRequest: urlRequest)

        // When Then
        await #expect(throws: NetworkTransportError.noNetworkConnection) {
            try await interceptor.intercept(request: &request)
        }
    }
}

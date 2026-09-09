//
//  HTTPRequest+Stubbed.swift
//  Networking
//
//  Created by Niklas Holloh on 22.04.26.
//  Copyright 2026 adesso SE
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//

// MARK: - Debug-only convenience

#if DEBUG
import Foundation

/// A minimal stub used exclusively by the `HTTPRequest(urlRequest:)` convenience initialiser.
private struct StubNetworkRequest: NetworkRequest {
    let method: HTTPMethod = .get
    let path: URLPath = URLPath(unsafeValue: "stub")
}

private let stubEnvironment = NetworkEnvironment(base: URLBase(unsafeValue: "https://stub.test.com"))

extension HTTPRequest {
    /// Convenience initialiser that supplies stub configuration and environment.
    /// Intended for test usage via `@testable import Networking` where these values are irrelevant.
    init(urlRequest: URLRequest) {
        self.init(urlRequest: urlRequest, configuration: StubNetworkRequest(), environment: stubEnvironment)
    }
}
#endif

//
//  ClosureRequestInterceptorTests.swift
//  Networking
//
//  Created by Jan Frederik Zerrath on 19.08.25.
//  Copyright 2026 adesso SE
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//

@testable import Networking

struct ClosureRequestInterceptorTests {
    @Test("intercept when intercepted modifies HTTP request")
    func intercept_whenIntercepted_modifiesHTTPRequest() async throws {
        // Given
        var request = generateHTTPRequest()

        #expect(request.urlRequest.allHTTPHeaderFields?["TestField"] == "TestValue")

        let interceptor = ClosureRequestInterceptor { httpRequest in
            httpRequest.urlRequest.setValue("InterceptValue", forHTTPHeaderField: "TestField")
        }

        // when
        try await interceptor.intercept(request: &request)

        // then
        #expect(request.urlRequest.allHTTPHeaderFields?["TestField"] == "InterceptValue")
    }
}

// MARK: - Helper

private extension ClosureRequestInterceptorTests {
    func generateHTTPRequest() -> HTTPRequest {
        var request = URLRequest(url: URL(string: "www.adesso.de").unsafelyUnwrapped)
        request.setValue("TestValue", forHTTPHeaderField: "TestField")

        return HTTPRequest(urlRequest: request)
    }
}

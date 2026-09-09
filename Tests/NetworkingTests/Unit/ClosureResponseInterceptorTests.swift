//
//  ClosureResponseInterceptorTests.swift
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

struct ClosureResponseInterceptorTests {
    @Test("intercept when intercepted modifies HTTP response and returns result", arguments: [Data("Test".utf8), Data("AnotherTest".utf8)], [NetworkResponseInterceptorResult.defaultHandling, NetworkResponseInterceptorResult.retryRequest])
    func intercept_whenIntercepted_modifiesHTTPResponse_andReturnsResult(
        responseData: Data,
        interceptResult: NetworkResponseInterceptorResult
    ) async throws {
        // given
        var response = generateHTTPResponse(statusCode: 200, responseData: responseData)

        #expect(response.urlResponse.statusCode == 200)
        #expect(response.data == responseData)

        let interceptor = ClosureResponseInterceptor { httpResponse in
            httpResponse.data = Data("Intercepted".utf8)
            return interceptResult
        }

        // when
        try await #expect(interceptor.intercept(response: &response) == interceptResult)

        // then
        #expect(response.data == Data("Intercepted".utf8))
    }
}

// MARK: - Helper

private extension ClosureResponseInterceptorTests {
    func generateHTTPResponse(statusCode: Int, responseData: Data) -> HTTPResponse {
        let urlRequest = URLRequest(url: URL(string: "https://www.adesso.de").unsafelyUnwrapped)
        let httpRequest = HTTPRequest(urlRequest: urlRequest)

        let urlResponse = HTTPURLResponse(
            url: URL(string: "https://www.adesso.de").unsafelyUnwrapped,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        ).unsafelyUnwrapped

        return HTTPResponse(request: httpRequest, urlResponse: urlResponse, data: responseData)
    }
}

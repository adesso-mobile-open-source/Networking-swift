//
//  ValidateHTTPStatusResponseInterceptorTests.swift
//  Networking
//
//  Created by Jan Frederik Zerrath on 18.08.25.
//  Copyright 2026 adesso SE
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//

@testable import Networking

// swiftlint:disable:next type_name
struct ValidateHTTPStatusResponseInterceptorTests {
    @Test("intercept when 2xx status code returns default handling", arguments: [200, 201, 204, 226, 299])
    func intercept_when2xxStatusCode_returnsDefaultHandling(statusCode: Int) async throws {
        // given
        let interceptor = ValidateHTTPStatusResponseInterceptor()
        var response = HTTPResponse(
            request: generateHTTPRequest(),
            urlResponse: generateHTTPURLResponse(statusCode: statusCode),
            data: Data()
        )

        // when
        let result = try await interceptor.intercept(response: &response)

        // then
        #expect(result == .defaultHandling)
    }

    @Test("intercept when status code is not 2xx throws", arguments: [0, 100, 101, 300, 301, 304, 305, 399, 400, 401, 403, 499, 500, 503])
    func intercept_whenStatusCodeIsNot2xx_throws(statusCode: Int) async throws {
        // given
        let interceptor = ValidateHTTPStatusResponseInterceptor()
        var response = HTTPResponse(
            request: generateHTTPRequest(),
            urlResponse: generateHTTPURLResponse(statusCode: statusCode),
            data: Data()
        )

        // when/then
        await #expect(throws: NetworkTransportError.errorStatusCode(code: statusCode, response: response)) {
            _ = try await interceptor.intercept(response: &response)
        }
    }

    @Test("intercept when status code is in valid range returns default handling", arguments: [
        // 0 ..< 100 range tests
        (0 ..< 100, 0),
        (0 ..< 100, 1),
        (0 ..< 100, 99),
        // 100 ..< 200 range tests
        (100 ..< 200, 100),
        (100 ..< 200, 199),
        // 200 ..< 300 range tests
        (200 ..< 300, 200),
        (200 ..< 300, 299),
        // 300 ..< 400 range tests
        (300 ..< 400, 300),
        (300 ..< 400, 399),
        // 400 ..< 500 range tests
        (400 ..< 500, 400),
        (400 ..< 500, 499)
    ])
    func intercept_whenStatusCodeIsInValidRange_returnsDefaultHandling(validRange: Range<Int>, statusCode: Int) async throws {
        // given
        let interceptor = ValidateHTTPStatusResponseInterceptor(allowedStatusCodes: validRange)
        var response = HTTPResponse(
            request: generateHTTPRequest(),
            urlResponse: generateHTTPURLResponse(statusCode: statusCode),
            data: Data()
        )

        // when
        let result = try await interceptor.intercept(response: &response)

        // then
        #expect(result == .defaultHandling)
    }

    @Test("intercept when status code is not in valid range throws", arguments: [
        // 0 ..< 100 range tests
        (0 ..< 100, 100),
        // 100 ..< 200 range tests
        (100 ..< 200, 99),
        (100 ..< 200, 201),
        // 200 ..< 300 range tests
        (200 ..< 300, 199),
        (200 ..< 300, 301),
        // 300 ..< 400 range tests
        (300 ..< 400, 299),
        (300 ..< 400, 401),
        // 400 ..< 500 range tests
        (400 ..< 500, 399),
        (400 ..< 500, 501)
    ])
    func intercept_whenStatusCodeIsNotInValidRange_throws(validRange: Range<Int>, statusCode: Int) async throws {
        // given
        let interceptor = ValidateHTTPStatusResponseInterceptor(allowedStatusCodes: validRange)
        var response = HTTPResponse(
            request: generateHTTPRequest(),
            urlResponse: generateHTTPURLResponse(statusCode: statusCode),
            data: Data()
        )

        // when/then
        await #expect(throws: NetworkTransportError.errorStatusCode(code: statusCode, response: response)) {
            _ = try await interceptor.intercept(response: &response)
        }
    }
}

// MARK: - Helper

private extension ValidateHTTPStatusResponseInterceptorTests {
    func generateHTTPURLResponse(statusCode: Int) -> HTTPURLResponse {
        HTTPURLResponse(
            url: URL(string: "www.adesso.de").unsafelyUnwrapped,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: [:]
        )
        .unsafelyUnwrapped
    }

    func generateHTTPRequest() -> HTTPRequest {
        HTTPRequest(
            urlRequest: URLRequest(url: .init(string: "www.adesso.de").unsafelyUnwrapped)
        )
    }
}

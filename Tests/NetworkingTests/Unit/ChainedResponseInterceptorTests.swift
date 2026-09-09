//
//  ChainedResponseInterceptorTests.swift
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

struct ChainedResponseInterceptorTests {
    @Test("intercept when using two interceptors executes both in order")
    func intercept_whenUsingTwoInterceptors_executesBothInOrder() async throws {
        // Given
        var response = generateHTTPResponse()
        let originalData = response.data

        let firstInterceptor = ClosureResponseInterceptor { httpResponse in
            httpResponse.data.append(Data("First".utf8))
            return .defaultHandling
        }

        let secondInterceptor = ClosureResponseInterceptor { httpResponse in
            httpResponse.data.append(Data("Second".utf8))
            return .defaultHandling
        }

        let chainedInterceptor = ChainedResponseInterceptor(first: firstInterceptor, second: secondInterceptor)

        // When
        let result = try await chainedInterceptor.intercept(response: &response)

        // Then
        #expect(result == .defaultHandling)
        let expectedData = originalData + Data("First".utf8) + Data("Second".utf8)
        #expect(response.data == expectedData)
    }

    @Test("intercept when first retry and second default returns retry")
    func intercept_whenFirstRetryAndSecondDefault_returnsRetry() async throws {
        // Given
        var response = generateHTTPResponse()

        let firstInterceptor = ClosureResponseInterceptor { _ in
            .retryRequest
        }

        let secondInterceptor = ClosureResponseInterceptor { _ in
            .defaultHandling
        }

        let chainedInterceptor = ChainedResponseInterceptor(first: firstInterceptor, second: secondInterceptor)

        // When
        let result = try await chainedInterceptor.intercept(response: &response)

        // Then
        #expect(result == .retryRequest)
    }

    @Test("intercept when first default and second retry returns retry")
    func intercept_whenFirstDefaultAndSecondRetry_returnsRetry() async throws {
        // Given
        var response = generateHTTPResponse()

        let firstInterceptor = ClosureResponseInterceptor { _ in
            .defaultHandling
        }

        let secondInterceptor = ClosureResponseInterceptor { _ in
            .retryRequest
        }

        let chainedInterceptor = ChainedResponseInterceptor(first: firstInterceptor, second: secondInterceptor)

        // When
        let result = try await chainedInterceptor.intercept(response: &response)

        // Then
        #expect(result == .retryRequest)
    }

    @Test("intercept when both retry returns retry")
    func intercept_whenBothRetry_returnsRetry() async throws {
        // Given
        var response = generateHTTPResponse()

        let firstInterceptor = ClosureResponseInterceptor { _ in
            .retryRequest
        }

        let secondInterceptor = ClosureResponseInterceptor { _ in
            .retryRequest
        }

        let chainedInterceptor = ChainedResponseInterceptor(first: firstInterceptor, second: secondInterceptor)

        // When
        let result = try await chainedInterceptor.intercept(response: &response)

        // Then
        #expect(result == .retryRequest)
    }

    @Test("chainAfter when using two interceptors executes other interceptor first")
    func chainAfter_whenUsingTwoInterceptors_executesOtherInterceptorFirst() async throws {
        // Given
        var response = generateHTTPResponse()
        response.data = Data()

        let firstInterceptor = ClosureResponseInterceptor { httpResponse in
            httpResponse.data.append(Data("First".utf8))
            return .defaultHandling
        }

        let secondInterceptor = ClosureResponseInterceptor { httpResponse in
            httpResponse.data.append(Data("Second".utf8))
            return .defaultHandling
        }

        let chainedInterceptor = secondInterceptor.chain(after: firstInterceptor)

        // When
        _ = try await chainedInterceptor.intercept(response: &response)

        // Then
        let expectedData = Data("First".utf8) + Data("Second".utf8)
        #expect(response.data == expectedData)
    }

    @Test("chainBefore when using two interceptors executes current interceptor first")
    func chainBefore_whenUsingTwoInterceptors_executesCurrentInterceptorFirst() async throws {
        // Given
        var response = generateHTTPResponse()
        response.data = Data()

        let firstInterceptor = ClosureResponseInterceptor { httpResponse in
            httpResponse.data.append(Data("First".utf8))
            return .defaultHandling
        }

        let secondInterceptor = ClosureResponseInterceptor { httpResponse in
            httpResponse.data.append(Data("Second".utf8))
            return .defaultHandling
        }

        let chainedInterceptor = firstInterceptor.chain(before: secondInterceptor)

        // When
        _ = try await chainedInterceptor.intercept(response: &response)

        // Then
        let expectedData = Data("First".utf8) + Data("Second".utf8)
        #expect(response.data == expectedData)
    }

    @Test("chainInOrder when using empty array returns default handling")
    func chainInOrder_whenUsingEmptyArray_returnsDefaultHandling() async throws {
        // Given
        var response = generateHTTPResponse()
        let originalData = response.data

        let chainedInterceptor = ChainedResponseInterceptor.chain(inOrder: [])

        // When
        let result = try await chainedInterceptor.intercept(response: &response)

        // Then
        #expect(result == .defaultHandling)
        #expect(response.data == originalData)
    }

    @Test("chainInOrder when using multiple interceptors executes in correct order")
    func chainInOrder_whenUsingMultipleInterceptors_executesInCorrectOrder() async throws {
        // Given
        var response = generateHTTPResponse()
        response.data = Data()

        let interceptors = [
            ClosureResponseInterceptor { httpResponse in
                httpResponse.data.append(Data("1".utf8))
                return .defaultHandling
            },
            ClosureResponseInterceptor { httpResponse in
                httpResponse.data.append(Data("2".utf8))
                return .defaultHandling
            },
            ClosureResponseInterceptor { httpResponse in
                httpResponse.data.append(Data("3".utf8))
                return .retryRequest
            }
        ]

        let chainedInterceptor = ChainedResponseInterceptor.chain(inOrder: interceptors)

        // When
        let result = try await chainedInterceptor.intercept(response: &response)

        // Then
        #expect(result == .retryRequest)
        let expectedData = Data("1".utf8) + Data("2".utf8) + Data("3".utf8)
        #expect(response.data == expectedData)
    }

    @Test("intercept when first interceptor throws propagates error")
    func intercept_whenFirstInterceptorThrows_propagatesError() async throws {
        // Given
        var response = generateHTTPResponse()

        struct TestError: Error, Equatable { }

        let firstInterceptor = ClosureResponseInterceptor { (_: inout HTTPResponse) async throws(NetworkTransportError)
            -> NetworkResponseInterceptorResult in
            throw NetworkTransportError.interceptorError(TestError())
        }

        let secondInterceptor = ClosureResponseInterceptor { httpResponse in
            httpResponse.data.append(Data("ShouldNotBeSet".utf8))
            return .defaultHandling
        }

        let chainedInterceptor = ChainedResponseInterceptor(first: firstInterceptor, second: secondInterceptor)

        // When/Then
        await #expect(throws: NetworkTransportError.self) {
            try await chainedInterceptor.intercept(response: &response)
        }

        #expect(!response.data.contains(Data("ShouldNotBeSet".utf8)))
    }

    @Test("intercept when second interceptor throws first interceptor still executed")
    func intercept_whenSecondInterceptorThrows_firstInterceptorStillExecuted() async throws {
        // Given
        var response = generateHTTPResponse()
        let originalData = response.data

        struct TestError: Error, Equatable { }

        let firstInterceptor = ClosureResponseInterceptor { httpResponse in
            httpResponse.data.append(Data("FirstExecuted".utf8))
            return .defaultHandling
        }

        let secondInterceptor = ClosureResponseInterceptor { (_: inout HTTPResponse) async throws(NetworkTransportError)
            -> NetworkResponseInterceptorResult in
            throw NetworkTransportError.interceptorError(TestError())
        }

        let chainedInterceptor = ChainedResponseInterceptor(first: firstInterceptor, second: secondInterceptor)

        // When/Then
        await #expect(throws: NetworkTransportError.self) {
            try await chainedInterceptor.intercept(response: &response)
        }

        let expectedData = originalData + Data("FirstExecuted".utf8)
        #expect(response.data == expectedData)
    }

    @Test("intercept when second interceptor modifies first result applies changes sequentially")
    func intercept_whenSecondInterceptorModifiesFirstResult_appliesChangesSequentially() async throws {
        // Given
        var response = generateHTTPResponse()
        response.data = Data()

        let firstInterceptor = ClosureResponseInterceptor { httpResponse in
            httpResponse.data.append(Data("Initial".utf8))
            return .defaultHandling
        }

        let secondInterceptor = ClosureResponseInterceptor { httpResponse in
            httpResponse.data.append(Data("_Modified".utf8))
            return .retryRequest
        }

        let chainedInterceptor = ChainedResponseInterceptor(first: firstInterceptor, second: secondInterceptor)

        // When
        let result = try await chainedInterceptor.intercept(response: &response)

        // Then
        #expect(result == .retryRequest)
        let expectedData = Data("Initial".utf8) + Data("_Modified".utf8)
        #expect(response.data == expectedData)
    }
}

// MARK: - Helper

private extension ChainedResponseInterceptorTests {
    func generateHTTPResponse() -> HTTPResponse {
        let urlRequest = URLRequest(url: URL(string: "https://www.adesso.de").unsafelyUnwrapped)
        let httpRequest = HTTPRequest(urlRequest: urlRequest)

        let urlResponse = HTTPURLResponse(
            url: URL(string: "https://www.adesso.de").unsafelyUnwrapped,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        ).unsafelyUnwrapped

        let data = Data("TestData".utf8)

        return HTTPResponse(request: httpRequest, urlResponse: urlResponse, data: data)
    }
}

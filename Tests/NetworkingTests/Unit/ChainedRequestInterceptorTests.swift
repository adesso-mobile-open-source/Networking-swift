//
//  ChainedRequestInterceptorTests.swift
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

struct ChainedRequestInterceptorTests {
    @Test("intercept when using two interceptors executes both in order")
    func intercept_whenUsingTwoInterceptors_executesBothInOrder() async throws {
        // Given
        var request = generateHTTPRequest()

        let firstInterceptor = ClosureRequestInterceptor { httpRequest in
            httpRequest.urlRequest.setValue("FirstValue", forHTTPHeaderField: "FirstField")
        }

        let secondInterceptor = ClosureRequestInterceptor { httpRequest in
            httpRequest.urlRequest.setValue("SecondValue", forHTTPHeaderField: "SecondField")
        }

        let chainedInterceptor = ChainedRequestInterceptor(first: firstInterceptor, second: secondInterceptor)

        // When
        try await chainedInterceptor.intercept(request: &request)

        // Then
        #expect(request.urlRequest.allHTTPHeaderFields?["FirstField"] == "FirstValue")
        #expect(request.urlRequest.allHTTPHeaderFields?["SecondField"] == "SecondValue")
    }

    @Test("intercept when second interceptor modifies first result applies changes sequentially")
    func intercept_whenSecondInterceptorModifiesFirstResult_appliesChangesSequentially() async throws {
        // Given
        var request = generateHTTPRequest()

        let firstInterceptor = ClosureRequestInterceptor { httpRequest in
            httpRequest.urlRequest.setValue("InitialValue", forHTTPHeaderField: "TestField")
        }

        let secondInterceptor = ClosureRequestInterceptor { httpRequest in
            let currentValue = httpRequest.urlRequest.allHTTPHeaderFields?["TestField"] ?? ""
            httpRequest.urlRequest.setValue(currentValue + "_Modified", forHTTPHeaderField: "TestField")
        }

        let chainedInterceptor = ChainedRequestInterceptor(first: firstInterceptor, second: secondInterceptor)

        // When
        try await chainedInterceptor.intercept(request: &request)

        // Then
        #expect(request.urlRequest.allHTTPHeaderFields?["TestField"] == "InitialValue_Modified")
    }

    @Test("chainAfter when using two interceptors executes other interceptor first")
    func chainAfter_whenUsingTwoInterceptors_executesOtherInterceptorFirst() async throws {
        // Given
        var request = generateHTTPRequest()

        let firstInterceptor = ClosureRequestInterceptor { httpRequest in
            httpRequest.urlRequest.setValue("First", forHTTPHeaderField: "Order")
        }

        let secondInterceptor = ClosureRequestInterceptor { httpRequest in
            let current = httpRequest.urlRequest.allHTTPHeaderFields?["Order"] ?? ""
            httpRequest.urlRequest.setValue(current + "Second", forHTTPHeaderField: "Order")
        }

        let chainedInterceptor = secondInterceptor.chain(after: firstInterceptor)

        // When
        try await chainedInterceptor.intercept(request: &request)

        // Then
        #expect(request.urlRequest.allHTTPHeaderFields?["Order"] == "FirstSecond")
    }

    @Test("chainBefore when using two interceptors executes current interceptor first")
    func chainBefore_whenUsingTwoInterceptors_executesCurrentInterceptorFirst() async throws {
        // Given
        var request = generateHTTPRequest()

        let firstInterceptor = ClosureRequestInterceptor { httpRequest in
            httpRequest.urlRequest.setValue("First", forHTTPHeaderField: "Order")
        }

        let secondInterceptor = ClosureRequestInterceptor { httpRequest in
            let current = httpRequest.urlRequest.allHTTPHeaderFields?["Order"] ?? ""
            httpRequest.urlRequest.setValue(current + "Second", forHTTPHeaderField: "Order")
        }

        let chainedInterceptor = firstInterceptor.chain(before: secondInterceptor)

        // When
        try await chainedInterceptor.intercept(request: &request)

        // Then
        #expect(request.urlRequest.allHTTPHeaderFields?["Order"] == "FirstSecond")
    }

    @Test("chainInOrder when using empty array returns no-op interceptor")
    func chainInOrder_whenUsingEmptyArray_returnsNoOpInterceptor() async throws {
        // Given
        var request = generateHTTPRequest()
        let originalHeaders = request.urlRequest.allHTTPHeaderFields

        let chainedInterceptor = ChainedRequestInterceptor.chain(inOrder: [])

        // When
        try await chainedInterceptor.intercept(request: &request)

        // Then
        #expect(request.urlRequest.allHTTPHeaderFields == originalHeaders)
    }

    @Test("chainInOrder when using multiple interceptors executes in correct order")
    func chainInOrder_whenUsingMultipleInterceptors_executesInCorrectOrder() async throws {
        // Given
        var request = generateHTTPRequest()

        let interceptors = [
            ClosureRequestInterceptor { httpRequest in
                httpRequest.urlRequest.setValue("1", forHTTPHeaderField: "Order")
            },
            ClosureRequestInterceptor { httpRequest in
                let current = httpRequest.urlRequest.allHTTPHeaderFields?["Order"] ?? ""
                httpRequest.urlRequest.setValue(current + "2", forHTTPHeaderField: "Order")
            },
            ClosureRequestInterceptor { httpRequest in
                let current = httpRequest.urlRequest.allHTTPHeaderFields?["Order"] ?? ""
                httpRequest.urlRequest.setValue(current + "3", forHTTPHeaderField: "Order")
            }
        ]

        let chainedInterceptor = ChainedRequestInterceptor.chain(inOrder: interceptors)

        // When
        try await chainedInterceptor.intercept(request: &request)

        // Then
        #expect(request.urlRequest.allHTTPHeaderFields?["Order"] == "123")
    }

    @Test("intercept when first interceptor throws propagates error")
    func intercept_whenFirstInterceptorThrows_propagatesError() async throws {
        // Given
        var request = generateHTTPRequest()

        struct TestError: Error, Equatable { }

        let firstInterceptor = ClosureRequestInterceptor { (_: inout HTTPRequest) async throws(NetworkTransportError) in
            throw NetworkTransportError.interceptorError(TestError())
        }

        let secondInterceptor = ClosureRequestInterceptor { httpRequest in
            httpRequest.urlRequest.setValue("ShouldNotBeSet", forHTTPHeaderField: "TestField")
        }

        let chainedInterceptor = ChainedRequestInterceptor(first: firstInterceptor, second: secondInterceptor)

        // When/Then
        await #expect(throws: NetworkTransportError.self) {
            try await chainedInterceptor.intercept(request: &request)
        }

        #expect(request.urlRequest.allHTTPHeaderFields?["TestField"] != "ShouldNotBeSet")
    }

    @Test("intercept when second interceptor throws first interceptor still executed")
    func intercept_whenSecondInterceptorThrows_firstInterceptorStillExecuted() async throws {
        // Given
        var request = generateHTTPRequest()

        struct TestError: Error, Equatable { }

        let firstInterceptor = ClosureRequestInterceptor { httpRequest in
            httpRequest.urlRequest.setValue("FirstExecuted", forHTTPHeaderField: "TestField")
        }

        let secondInterceptor = ClosureRequestInterceptor { (_: inout HTTPRequest) async throws(NetworkTransportError) in
            throw NetworkTransportError.interceptorError(TestError())
        }

        let chainedInterceptor = ChainedRequestInterceptor(first: firstInterceptor, second: secondInterceptor)

        // When/Then
        await #expect(throws: NetworkTransportError.self) {
            try await chainedInterceptor.intercept(request: &request)
        }

        #expect(request.urlRequest.allHTTPHeaderFields?["TestField"] == "FirstExecuted")
    }
}

// MARK: - Helper

private extension ChainedRequestInterceptorTests {
    func generateHTTPRequest() -> HTTPRequest {
        var request = URLRequest(url: URL(string: "https://www.adesso.de").unsafelyUnwrapped)
        request.setValue("TestValue", forHTTPHeaderField: "TestField")

        return HTTPRequest(urlRequest: request)
    }
}

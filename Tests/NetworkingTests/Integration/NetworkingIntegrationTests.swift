//
//  NetworkingIntegrationTests.swift
//  Networking
//
//  Created by Niklas Holloh on 13.08.25.
//  Copyright 2026 adesso SE
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//

// swiftlint:disable nesting type_body_length file_length

import Mocker
import Networking

// ===============================================================================================
// -- ON USING MOCKER: https://github.com/WeTransfer/Mocker
//
// Mocker is a tool to stub http responses, similar to OHHTTPStubs. Mocker is the swiftier,
// modern approach to the same underlying issue. Hand a URLRequest to mocker, provide a status
// code and a response and mocker will make sure the underlying network request is caught
// handled and returns the appropriate stubbed response.
//
// Mind the following:
// - Use the NetworkRequest.makeURLRequest(environment:) method to quickly get an appropriate
//   URLRequest object for the request you provided. It handles method, path, query and headers.
// - Hold the Mock() instance in memory. If you drop its reference, the mock
//   will automatically be removed from Mocker.
//
// ===============================================================================================

@NetworkActor
struct NetworkIntegrationTests {
    static let environment = NetworkEnvironment(base: #URLBase("https://mylittlepony.io/api"))

    let networkClient = {
        let config = URLSessionConfiguration.default
        config.protocolClasses = [MockingURLProtocol.self]
        return NetworkClientImpl(
            urlSession: URLSession(configuration: config),
            configuration: .init(environment: Self.environment)
        )
    }()

    // MARK: - GET, no query, no body, no response

    @Test
    func `network request GET when no query no request body no response body`() async throws {
        @URLPathTemplate("tests/{id}")
        struct Request: NetworkRequest {
            let method: HTTPMethod = .get
        }

        let request = Request(id: UUID())
        let mock = Mock(request: request.makeURLRequest(environment: Self.environment), statusCode: 200)
        mock.register()

        try await networkClient.send(request: request)
        // should not throw
    }

    // MARK: - GET with query

    @Test
    func `network request GET when with query no request body no response body`() async throws {
        @URLPathTemplate("tests/{id}/search")
        struct Request: NetworkRequest, NetworkRequestWithQuery {
            struct Query: Encodable {
                let string: String
                let int: Int
            }

            let method: HTTPMethod = .get
            let query: Query
        }

        let query = Request.Query(string: .random(), int: Int.random(in: 0 ... 100))
        let request = Request(query: query, id: UUID())
        let urlRequest = request.makeURLRequest(environment: Self.environment, query: [
            .init(name: "int", value: "\(query.int)"),
            .init(name: "string", value: query.string)
        ])
        let mock = Mock(request: urlRequest, statusCode: 200)
        mock.register()

        try await networkClient.send(request: request)
        // should not throw
    }

    // MARK: - GET with custom headers

    @Test
    func `network request GET when no query with headers no request body no response body`() async throws {
        @URLPathTemplate("tests/{id}")
        struct Request: NetworkRequest {
            let method: HTTPMethod = .get
            var headers: [HTTPHeader: String]
        }

        let customHeaderValue = String.random()
        let request = Request(headers: ["x-test": customHeaderValue], id: UUID())
        let urlRequest = request.makeURLRequest(environment: Self.environment, headers: [
            "x-test": customHeaderValue
        ])
        let mock = Mock(request: urlRequest, statusCode: 200)
        mock.register()

        try await networkClient.send(request: request)
        // should not throw
    }

    // MARK: - POST with request body

    @Test
    func `network request POST when no query no headers with request body no response body`() async throws {
        @URLPathTemplate("tests/{id}")
        struct Request: NetworkRequest, NetworkRequestWithBody {
            struct RequestBody: Encodable {
                let name: String
                let value: Int
            }

            let method: HTTPMethod = .post
            let body: RequestBody
        }

        let requestBody = Request.RequestBody(name: .random(), value: Int.random(in: 0 ... 100))
        let request = Request(body: requestBody, id: UUID())
        let mock = Mock(request: request.makeURLRequest(environment: Self.environment, method: .post), statusCode: 201)
        mock.register()

        try await networkClient.send(request: request)
        // should not throw
    }

    // MARK: - POST with response body

    @Test
    func `network request POST when no query no headers no request body with response body`() async throws {
        @URLPathTemplate("tests/{id}")
        struct Request: NetworkRequest, NetworkRequestWithResponse {
            struct ResponseBody: Codable {
                let id: String
                let success: Bool
            }

            let method: HTTPMethod = .post
        }

        let request = Request(id: UUID())
        let responseBody = Request.ResponseBody(id: .random(), success: true)
        let responseData = try JSONEncoder().encode(responseBody)
        let mock = Mock(request: request.makeURLRequest(environment: Self.environment, method: .post), statusCode: 200, data: responseData)
        mock.register()

        let response = try await networkClient.send(request: request)

        #expect(response.id == responseBody.id)
        #expect(response.success == responseBody.success)
    }

    // MARK: - PathParameterStringConvertible

    @Test
    func `network request GET when path parameter is UUID then path uses description`() async throws {
        @URLPathTemplate("tests/{id}")
        struct Request: NetworkRequest {
            let method: HTTPMethod = .get
        }

        // UUID conforms to CustomStringConvertible and therefore PathParameterStringConvertible.
        // No manual .uuidString conversion needed — the protocol handles it.
        let id = UUID()
        let request = Request(id: id)

        // makeURLRequest calls self.path which calls id.stringRepresentation (== id.description),
        // so the mock URL will match what NetworkClientImpl produces.
        let mock = Mock(request: request.makeURLRequest(environment: Self.environment), statusCode: 200)
        mock.register()

        try await networkClient.send(request: request)
        // Verify the composed URL contains the UUID's standard string form
        let expectedURL = (Self.environment.base + request.path).url
        #expect(expectedURL.absoluteString.contains(id.description))
    }

    @Test
    func `network request GET when path parameter is Int then path uses description`() async throws {
        @URLPathTemplate("tests/{id}")
        struct Request: NetworkRequest {
            let method: HTTPMethod = .get
        }

        let id = 42
        let request = Request(id: id)
        let mock = Mock(request: request.makeURLRequest(environment: Self.environment), statusCode: 200)
        mock.register()

        try await networkClient.send(request: request)
        let expectedURL = (Self.environment.base + request.path).url
        #expect(expectedURL.absoluteString.hasSuffix("/tests/42"))
    }

    // MARK: - allowedStatusCodes

    @Test
    func `network request GET when status outside default allowedStatusCodes then throws`() async throws {
        @URLPathTemplate("tests/{id}")
        struct Request: NetworkRequest {
            let method: HTTPMethod = .get
        }

        let request = Request(id: UUID())
        let mock = Mock(request: request.makeURLRequest(environment: Self.environment), statusCode: 404)
        mock.register()

        await #expect(throws: NetworkSendError.self) {
            try await networkClient.send(request: request)
        }
    }

    @Test
    func `network request POST when status inside custom allowedStatusCodes then does not throw`() async throws {
        @URLPathTemplate("tests/{id}")
        struct Request: NetworkRequest {
            let method: HTTPMethod = .post
            var allowedStatusCodes: Range<Int> { 200 ..< 202 }
        }

        let request = Request(id: UUID())
        let mock = Mock(request: request.makeURLRequest(environment: Self.environment, method: .post), statusCode: 201)
        mock.register()

        // Should not throw — 201 is within 200..<202
        try await networkClient.send(request: request)
    }

    @Test
    func `network request GET when status outside custom allowedStatusCodes then throws`() async throws {
        @URLPathTemplate("tests/{id}")
        struct Request: NetworkRequest {
            let method: HTTPMethod = .get
            /// Only accept 200, not 201
            var allowedStatusCodes: Range<Int> { 200 ..< 201 }
        }

        let request = Request(id: UUID())
        let mock = Mock(request: request.makeURLRequest(environment: Self.environment), statusCode: 201)
        mock.register()

        await #expect(throws: NetworkSendError.self) {
            try await networkClient.send(request: request)
        }
    }

    // MARK: - Custom request interceptor

    @Test
    func `network request GET when with custom request interceptor`() async throws {
        @URLPathTemplate("tests/{id}")
        struct Request: NetworkRequest, NetworkRequestWithRequestInterceptor {
            let method: HTTPMethod = .get
            let requestInterceptor: NetworkRequestInterceptor
        }

        let customHeaderValue = String.random()
        let interceptor = ClosureRequestInterceptor { req in
            req.urlRequest.setValue(customHeaderValue, forHTTPHeaderField: "X-Custom-Header")
        }
        let request = Request(requestInterceptor: interceptor, id: UUID())
        let urlRequest = request.makeURLRequest(environment: Self.environment, headers: ["X-Custom-Header": customHeaderValue])
        let mock = Mock(request: urlRequest, statusCode: 200)
        mock.register()

        try await networkClient.send(request: request)
        // should not throw — Mocker validates the custom header was set
    }

    // MARK: - Custom response interceptor

    @Test
    func `network request GET when with custom response interceptor`() async throws {
        @URLPathTemplate("tests/{id}")
        struct Request: NetworkRequest, NetworkRequestWithResponseInterceptor {
            let method: HTTPMethod = .get
            let responseInterceptor: NetworkResponseInterceptor
        }

        let wasIntercepted = ActorBox(false)
        let interceptor = ClosureResponseInterceptor { response in
            await wasIntercepted.set(true)
            response.data = Data("modified".utf8)
            return .defaultHandling
        }
        let request = Request(responseInterceptor: interceptor, id: UUID())
        let mock = Mock(request: request.makeURLRequest(environment: Self.environment), statusCode: 200, data: Data("original".utf8))
        mock.register()

        try await networkClient.send(request: request)

        #expect(await wasIntercepted.get())
    }

    // MARK: - Interceptor execution order

    @Test
    func `network request GET when custom request interceptor before default interceptors`() async throws {
        @URLPathTemplate("tests/{id}")
        struct Request: NetworkRequest, NetworkRequestWithRequestInterceptor {
            let method: HTTPMethod = .get
            let requestInterceptor: NetworkRequestInterceptor
        }

        let executionOrder = ActorBox([String]())
        let customInterceptor = ClosureRequestInterceptor { req in
            await executionOrder.withValue { $0.append("custom") }
            req.urlRequest.setValue("custom-value", forHTTPHeaderField: "X-Custom")
        }
        let defaultInterceptor = ClosureRequestInterceptor { req in
            await executionOrder.withValue { $0.append("default") }
            req.urlRequest.setValue("default-value", forHTTPHeaderField: "X-Default")
        }

        let request = Request(requestInterceptor: customInterceptor, id: UUID())

        let config = URLSessionConfiguration.default
        config.protocolClasses = [MockingURLProtocol.self]
        let testManager = NetworkClientImpl(
            urlSession: URLSession(configuration: config),
            configuration: .init(environment: Self.environment, requestInterceptor: defaultInterceptor)
        )

        let urlRequest = request.makeURLRequest(environment: Self.environment, headers: [
            "X-Custom": "custom-value",
            "X-Default": "default-value"
        ])
        let mock = Mock(request: urlRequest, statusCode: 200)
        mock.register()

        try await testManager.send(request: request)

        #expect(await executionOrder.get() == ["custom", "default"])
    }

    @Test
    func `network request GET when custom response interceptor after default interceptors`() async throws {
        @URLPathTemplate("tests/{id}")
        struct Request: NetworkRequest, NetworkRequestWithResponseInterceptor {
            let method: HTTPMethod = .get
            let responseInterceptor: NetworkResponseInterceptor
        }

        let executionOrder = ActorBox([String]())
        let defaultInterceptor = ClosureResponseInterceptor { _ in
            await executionOrder.withValue { $0.append("default") }
            return .defaultHandling
        }
        let customInterceptor = ClosureResponseInterceptor { _ in
            await executionOrder.withValue { $0.append("custom") }
            return .defaultHandling
        }

        let request = Request(responseInterceptor: customInterceptor, id: UUID())

        let config = URLSessionConfiguration.default
        config.protocolClasses = [MockingURLProtocol.self]
        let testManager = NetworkClientImpl(
            urlSession: URLSession(configuration: config),
            configuration: .init(environment: Self.environment, responseInterceptor: defaultInterceptor)
        )

        let mock = Mock(request: request.makeURLRequest(environment: Self.environment), statusCode: 200)
        mock.register()

        try await testManager.send(request: request)

        #expect(await executionOrder.get() == ["default", "custom"])
    }

    // MARK: - Optional response body

    @Test
    func `network request GET when no query no headers no request body with optional response body`() async throws {
        @URLPathTemplate("tests/{id}")
        struct Request: NetworkRequest, NetworkRequestWithResponse {
            struct Body: Codable {
                let id: String
                let success: Bool
            }

            typealias ResponseBody = Body?
            let method: HTTPMethod = .get
        }

        let request = Request(id: UUID())
        let responseBody = Request.Body(id: .random(), success: true)
        let responseData = try JSONEncoder().encode(responseBody)
        let mock = Mock(request: request.makeURLRequest(environment: Self.environment), statusCode: 200, data: responseData)
        mock.register()

        let response = try await networkClient.send(request: request)

        #expect(response.body?.id == responseBody.id)
        #expect(response.body?.success == responseBody.success)
    }

    @Test
    func `network request GET when no query no headers no request body with opt response body returns nil when no data`() async throws {
        @URLPathTemplate("tests/{id}")
        struct Request: NetworkRequest, NetworkRequestWithResponse {
            struct Body: Codable {
                let id: String
                let success: Bool
            }

            typealias ResponseBody = Body?
            let method: HTTPMethod = .get
        }

        let request = Request(id: UUID())
        let mock = Mock(request: request.makeURLRequest(environment: Self.environment), statusCode: 200, data: Data())
        mock.register()

        let response = try await networkClient.send(request: request)

        #expect(response.body == nil)
    }

    // MARK: - Optional response body with request body

    @Test
    func `network request POST when no query no headers with request body with optional response body`() async throws {
        @URLPathTemplate("tests/{id}")
        struct Request: NetworkRequest, NetworkRequestWithResponse, NetworkRequestWithBody {
            struct RequestBody: Encodable { let name: String; let value: Int }
            struct Body: Codable { let id: String; let success: Bool }
            typealias ResponseBody = Body?
            let method: HTTPMethod = .post
            let body: RequestBody
        }

        let requestBody = Request.RequestBody(name: .random(), value: Int.random(in: 0 ... 100))
        let request = Request(body: requestBody, id: UUID())
        let responseBody = Request.Body(id: .random(), success: true)
        let responseData = try JSONEncoder().encode(responseBody)
        let mock = Mock(request: request.makeURLRequest(environment: Self.environment, method: .post), statusCode: 200, data: responseData)
        mock.register()

        let response = try await networkClient.send(request: request)

        #expect(response.body?.id == responseBody.id)
        #expect(response.body?.success == responseBody.success)
    }

    @Test
    func `network request POST when no query no headers with request body with opt response body returns nil when no data`() async throws {
        @URLPathTemplate("tests/{id}")
        struct Request: NetworkRequest, NetworkRequestWithResponse, NetworkRequestWithBody {
            struct RequestBody: Encodable { let name: String; let value: Int }
            struct Body: Codable { let id: String; let success: Bool }
            typealias ResponseBody = Body?
            let method: HTTPMethod = .post
            let body: RequestBody
        }

        let requestBody = Request.RequestBody(name: .random(), value: Int.random(in: 0 ... 100))
        let request = Request(body: requestBody, id: UUID())
        let mock = Mock(request: request.makeURLRequest(environment: Self.environment, method: .post), statusCode: 200, data: Data())
        mock.register()

        let response = try await networkClient.send(request: request)

        #expect(response.body == nil)
    }

    // MARK: - Header response

    @Test
    func `network request HEAD when no query present headers no request body with header response`() async throws {
        @URLPathTemplate("tests/{id}")
        struct Request: NetworkRequest, NetworkRequestWithHeaderResponse {
            let method: HTTPMethod = .head
            var requiredHeaders: [String] { ["date"] }
        }

        let request = Request(id: UUID())
        let responseHeaders = ["date": "01.01.2001, 08:00:00"]
        let mock = Mock(
            request: request.makeURLRequest(environment: Self.environment, method: .head),
            statusCode: 200,
            additionalHeaders: responseHeaders
        )
        mock.register()

        let response = try await networkClient.send(request: request)

        #expect(response.count == 1)
        #expect(response["date"] == responseHeaders["date"])
    }

    @Test
    func `network request HEAD when no query missing headers no request body with header response`() async throws {
        @URLPathTemplate("tests/{id}")
        struct Request: NetworkRequest, NetworkRequestWithHeaderResponse {
            let method: HTTPMethod = .head
            var requiredHeaders: [String] { ["date"] }
        }

        let request = Request(id: UUID())
        let mock = Mock(request: request.makeURLRequest(environment: Self.environment, method: .head), statusCode: 200)
        mock.register()

        do {
            _ = try await networkClient.send(request: request)
            Issue.record("Expected NetworkSendHeaderResponseError.headerFieldsMissing to be thrown")
        } catch {
            #expect(error == .headerFieldsMissing)
        }
    }
}

// swiftlint:enable nesting type_body_length file_length

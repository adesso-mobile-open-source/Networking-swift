//
//  RetryIntegrationTests.swift
//  Networking
//
//  Created by Niklas Holloh on 18.11.26.
//  Copyright 2026 adesso SE
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//

import Foundation
import Mocker
import Networking
import Testing

/// Records what the request interceptor saw on each attempt.
private actor AttemptRecorder {
    private(set) var retryCounts: [Int] = []
    private(set) var traceHeadersBeforeInterception: [String?] = []

    func record(retryCount: Int, traceHeader: String?) {
        retryCounts.append(retryCount)
        traceHeadersBeforeInterception.append(traceHeader)
    }
}

@NetworkActor
struct RetryIntegrationTests {
    static let environment = NetworkEnvironment(base: #URLBase("https://mylittlepony.io/api"))

    @URLPathTemplate("retries/{id}")
    struct Request: NetworkRequest {
        let method: HTTPMethod = .get
    }

    /// A client whose request interceptor records every attempt and then appends to an `x-trace` header, so a retry
    /// that started from the previous attempt's intercepted request would be visible.
    private func client(
        recorder: AttemptRecorder,
        responseInterceptor: NetworkResponseInterceptor = ClosureResponseInterceptor { _ in .defaultHandling },
        errorInterceptor: NetworkErrorInterceptor = ClosureErrorInterceptor { _ in .defaultHandling },
        maximumRetryCount: Int = NetworkClientConfiguration.defaultMaximumRetryCount
    ) -> NetworkClientImpl {
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.protocolClasses = [MockingURLProtocol.self]
        let requestInterceptor = ClosureRequestInterceptor { request in
            let trace = request.urlRequest.value(forHTTPHeaderField: "x-trace")
            await recorder.record(retryCount: request.retryCount, traceHeader: trace)
            request.urlRequest.setValue((trace ?? "") + "a", forHTTPHeaderField: "x-trace")
        }
        return NetworkClientImpl(
            urlSession: URLSession(configuration: sessionConfiguration),
            configuration: .init(
                environment: Self.environment,
                requestInterceptor: requestInterceptor,
                responseInterceptor: responseInterceptor,
                errorInterceptor: errorInterceptor,
                maximumRetryCount: maximumRetryCount
            )
        )
    }

    @Test
    func `error interceptor retries are capped at the default maximum`() async throws {
        let request = Request(id: UUID())
        let mock = Mock(request: request.makeURLRequest(environment: Self.environment), statusCode: 500)
        mock.register()
        let recorder = AttemptRecorder()
        let client = client(recorder: recorder, errorInterceptor: ClosureErrorInterceptor { _ in .retryRequest })

        let error = await #expect(throws: NetworkSendError.self) {
            try await client.send(request: request)
        }
        guard case let .transport(.errorStatusCode(code, response)) = error else {
            Issue.record("Expected the last attempt's status code error, got \(String(describing: error))")
            return
        }
        #expect(code == 500)
        #expect(response.request.retryCount == 3)
        #expect(await recorder.retryCounts == [0, 1, 2, 3])
    }

    @Test
    func `every attempt runs the request interceptors on the request as it was built`() async throws {
        let request = Request(id: UUID())
        let mock = Mock(request: request.makeURLRequest(environment: Self.environment), statusCode: 500)
        mock.register()
        let recorder = AttemptRecorder()
        let client = client(recorder: recorder, errorInterceptor: ClosureErrorInterceptor { _ in .retryRequest })

        _ = try? await client.send(request: request)
        #expect(await recorder.traceHeadersBeforeInterception == [nil, nil, nil, nil])
    }

    @Test
    func `a maximum retry count of zero sends the request once`() async throws {
        let request = Request(id: UUID())
        let mock = Mock(request: request.makeURLRequest(environment: Self.environment), statusCode: 500)
        mock.register()
        let recorder = AttemptRecorder()
        let client = client(
            recorder: recorder,
            errorInterceptor: ClosureErrorInterceptor { _ in .retryRequest },
            maximumRetryCount: 0
        )

        await #expect(throws: NetworkSendError.self) {
            try await client.send(request: request)
        }
        #expect(await recorder.retryCounts == [0])
    }

    @Test
    func `a response interceptor can stop retrying by reading the retry count`() async throws {
        let request = Request(id: UUID())
        let mock = Mock(request: request.makeURLRequest(environment: Self.environment), statusCode: 200)
        mock.register()
        let recorder = AttemptRecorder()
        let client = client(
            recorder: recorder,
            responseInterceptor: ClosureResponseInterceptor { response in
                response.request.retryCount < 2 ? .retryRequest : .defaultHandling
            }
        )

        let response = try await client.send(request: request)
        #expect(response.httpResponse.request.retryCount == 2)
        #expect(await recorder.retryCounts == [0, 1, 2])
    }

    @Test
    func `a response interceptor retry at the limit returns the response`() async throws {
        let request = Request(id: UUID())
        let mock = Mock(request: request.makeURLRequest(environment: Self.environment), statusCode: 200)
        mock.register()
        let recorder = AttemptRecorder()
        let client = client(
            recorder: recorder,
            responseInterceptor: ClosureResponseInterceptor { _ in .retryRequest },
            maximumRetryCount: 1
        )

        let response = try await client.send(request: request)
        #expect(response.httpResponse.request.retryCount == 1)
        #expect(await recorder.retryCounts == [0, 1])
    }
}

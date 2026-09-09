//
//  NetworkErrorInterceptorTests.swift
//  Networking
//
//  Created by Kay Kartschewsky on 25.02.26.
//  Copyright 2026 adesso SE
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//

@testable import Networking
import Testing

// MARK: - NetworkErrorInterceptorResult Tests

struct NetworkErrorInterceptorResultTests {
    @Test("combine when using two results returns highest precedence",
          arguments: [
              (NetworkErrorInterceptorResult.defaultHandling, NetworkErrorInterceptorResult.defaultHandling, NetworkErrorInterceptorResult.defaultHandling),
              (NetworkErrorInterceptorResult.retryRequest, NetworkErrorInterceptorResult.defaultHandling, NetworkErrorInterceptorResult.retryRequest),
              (NetworkErrorInterceptorResult.defaultHandling, NetworkErrorInterceptorResult.retryRequest, NetworkErrorInterceptorResult.retryRequest),
              (NetworkErrorInterceptorResult.retryRequest, NetworkErrorInterceptorResult.retryRequest, NetworkErrorInterceptorResult.retryRequest)
          ]
    )
    func combine_returnsHighestPrecedence(
        first: NetworkErrorInterceptorResult,
        second: NetworkErrorInterceptorResult,
        expected: NetworkErrorInterceptorResult
    ) {
        let result = first.combine(with: second)
        #expect(result == expected)
    }
}

// MARK: - ClosureErrorInterceptor Tests

struct ClosureErrorInterceptorTests {
    @Test
    func `intercept when closureReturnsDefaultHandling then ReturnsDefaultHandling`() async {
        let interceptor = ClosureErrorInterceptor { _ in .defaultHandling }
        let result = await interceptor.intercept(error: .secureConnectionNotPossible)
        #expect(result == .defaultHandling)
    }

    @Test
    func `intercept when closureReturnsRetryRequest then ReturnsRetryRequest`() async {
        let interceptor = ClosureErrorInterceptor { _ in .retryRequest }
        let result = await interceptor.intercept(error: .secureConnectionNotPossible)
        #expect(result == .retryRequest)
    }

    actor ErrorRecorder {
        var error: NetworkTransportError?
        func set(_ value: NetworkTransportError) { error = value }
        func get() -> NetworkTransportError? { error }
    }

    @Test
    func `intercept when closureReceivesError then ForwardsCorrectError`() async {
        let recorder = ErrorRecorder()
        let interceptor = ClosureErrorInterceptor { error in
            await recorder.set(error)
            return .defaultHandling
        }

        _ = await interceptor.intercept(error: .secureConnectionNotPossible)
        let first = await recorder.get()
        #expect(first == .secureConnectionNotPossible)

        _ = await interceptor.intercept(error: .noNetworkConnection)
        let second = await recorder.get()
        #expect(second == .noNetworkConnection)
    }
}

// MARK: - ChainedErrorInterceptor Tests

struct ChainedErrorInterceptorTests {
    @Test
    func `chainAfter when bothReturnDefaultHandling then ReturnsDefaultHandling`() async {
        let first = ClosureErrorInterceptor { _ in .defaultHandling }
        let second = ClosureErrorInterceptor { _ in .defaultHandling }

        let chained = second.chain(after: first)
        let result = await chained.intercept(error: .secureConnectionNotPossible)

        #expect(result == .defaultHandling)
    }

    @Test
    func `chainAfter when firstReturnsRetry then ReturnsRetry`() async {
        let first = ClosureErrorInterceptor { _ in .retryRequest }
        let second = ClosureErrorInterceptor { _ in .defaultHandling }

        let chained = second.chain(after: first)
        let result = await chained.intercept(error: .secureConnectionNotPossible)

        #expect(result == .retryRequest)
    }

    @Test
    func `chainAfter when secondReturnsRetry then ReturnsRetry`() async {
        let first = ClosureErrorInterceptor { _ in .defaultHandling }
        let second = ClosureErrorInterceptor { _ in .retryRequest }

        let chained = second.chain(after: first)
        let result = await chained.intercept(error: .secureConnectionNotPossible)

        #expect(result == .retryRequest)
    }

    actor OrderRecorder {
        var order: [String] = []
        func append(_ value: String) { order.append(value) }
        func get() -> [String] { order }
    }

    actor IntOrderRecorder {
        var order: [Int] = []
        func append(_ value: Int) { order.append(value) }
        func get() -> [Int] { order }
    }

    @Test
    func `chainBefore when executionOrder then FirstRunsBeforeSecond`() async {
        let recorder = OrderRecorder()
        let first = ClosureErrorInterceptor { _ in await recorder.append("first"); return .defaultHandling }
        let second = ClosureErrorInterceptor { _ in await recorder.append("second"); return .defaultHandling }

        let chained = first.chain(before: second)
        _ = await chained.intercept(error: .secureConnectionNotPossible)

        let order = await recorder.get()
        #expect(order == ["first", "second"])
    }

    @Test
    func `chainInOrder when multipleInterceptors then ExecutesInArrayOrder`() async {
        let recorder = IntOrderRecorder()
        let interceptors: [NetworkErrorInterceptor] = [
            ClosureErrorInterceptor { _ in await recorder.append(1); return .defaultHandling },
            ClosureErrorInterceptor { _ in await recorder.append(2); return .defaultHandling },
            ClosureErrorInterceptor { _ in await recorder.append(3); return .defaultHandling }
        ]

        let chained = ClosureErrorInterceptor.chain(inOrder: interceptors)
        _ = await chained.intercept(error: .secureConnectionNotPossible)

        let order = await recorder.get()
        #expect(order == [1, 2, 3])
    }

    @Test
    func `chainInOrder when emptyArray then ReturnsDefaultHandling`() async {
        let chained = ClosureErrorInterceptor.chain(inOrder: [])
        let result = await chained.intercept(error: .secureConnectionNotPossible)

        #expect(result == .defaultHandling)
    }

    @Test
    func `chainInOrder when anyReturnsRetry then CombinedReturnsRetry`() async {
        let interceptors: [NetworkErrorInterceptor] = [
            ClosureErrorInterceptor { _ in .defaultHandling },
            ClosureErrorInterceptor { _ in .retryRequest },
            ClosureErrorInterceptor { _ in .defaultHandling }
        ]

        let chained = ClosureErrorInterceptor.chain(inOrder: interceptors)
        let result = await chained.intercept(error: .secureConnectionNotPossible)

        #expect(result == .retryRequest)
    }
}

// MARK: - NetworkTransportError.secureConnectionNotPossible Tests

struct NetworkTransportErrorSecureConnectionTests {
    @Test
    func `secureConnectionNotPossible is Equatable`() {
        #expect(NetworkTransportError.secureConnectionNotPossible == .secureConnectionNotPossible)
        #expect(NetworkTransportError.secureConnectionNotPossible != .noNetworkConnection)
    }
}

// MARK: - GetResponse Error Interceptor Tests

/// Tests the error handling paths inside `NetworkClientImpl.getResponse`:
///
/// - TLS errors → mapped to `NetworkTransportError.secureConnectionNotPossible`
/// - Non-TLS errors → rethrown as-is
/// - Response interceptor `NetworkTransportError` throws → forwarded to error interceptors
///
/// A `ThrowingURLProtocol` is injected so `URLSession.data(for:)` throws a controlled
/// error without hitting the network.  `@Suite(.serialized)` prevents concurrent tests
/// from racing over the `nonisolated(unsafe)` static `thrownError` variable.
@Suite(.serialized)
@NetworkActor
struct GetResponseErrorInterceptorTests {
    // MARK: - Helpers

    private func makeNetworkClient(
        throwing error: Error,
        errorInterceptor: NetworkErrorInterceptor = ClosureErrorInterceptor { _ in .defaultHandling }
    ) -> NetworkClientImpl {
        ThrowingURLProtocol.thrownError = error
        let sessionConfig = URLSessionConfiguration.ephemeral
        sessionConfig.protocolClasses = [ThrowingURLProtocol.self]
        let nmConfig = NetworkClientConfiguration(
            environment: testNetworkEnvironment,
            errorInterceptor: errorInterceptor
        )
        let session = URLSession(configuration: sessionConfig)
        return NetworkClientImpl(urlSession: session, configuration: nmConfig)
    }

    private var httpRequest: HTTPRequest {
        HTTPRequest(urlRequest: URLRequest(url: URL(string: "https://api.test.com/test")!))
    }

    // MARK: - TLS Error Mapping Tests

    /// When `URLSession` throws `serverCertificateUntrusted` (e.g. `NSPinnedDomains` violation),
    /// `getResponse` must map it to `NetworkTransportError.secureConnectionNotPossible`.
    @Test
    func `getResponse when URLSessionThrowsServerCertificateUntrusted then ThrowsSecureConnectionNotPossible`() async {
        let nm = makeNetworkClient(throwing: URLError(.serverCertificateUntrusted))

        await #expect(throws: NetworkTransportError.secureConnectionNotPossible) {
            _ = try await nm.getResponse(for: httpRequest, requestConfiguration: AnyNetworkRequest())
        }
    }

    /// When `URLSession` throws `secureConnectionFailed`, `getResponse` must map it
    /// to `NetworkTransportError.secureConnectionNotPossible`.
    @Test
    func `getResponse when URLSessionThrowsSecureConnectionFailed then ThrowsSecureConnectionNotPossible`() async {
        let nm = makeNetworkClient(throwing: URLError(.secureConnectionFailed))

        await #expect(throws: NetworkTransportError.secureConnectionNotPossible) {
            _ = try await nm.getResponse(for: httpRequest, requestConfiguration: AnyNetworkRequest())
        }
    }

    /// When `URLSession` throws `serverCertificateHasBadDate`, `getResponse` must map it
    /// to `NetworkTransportError.secureConnectionNotPossible`.
    @Test
    func `getResponse when URLSessionThrowsCertificateHasBadDate then ThrowsSecureConnectionNotPossible`() async {
        let nm = makeNetworkClient(throwing: URLError(.serverCertificateHasBadDate))

        await #expect(throws: NetworkTransportError.secureConnectionNotPossible) {
            _ = try await nm.getResponse(for: httpRequest, requestConfiguration: AnyNetworkRequest())
        }
    }

    /// When `URLSession` throws `serverCertificateHasUnknownRoot`, `getResponse` must map it
    /// to `NetworkTransportError.secureConnectionNotPossible`.
    @Test
    func `getResponse when URLSessionThrowsCertificateHasUnknownRoot then ThrowsSecureConnectionNotPossible`() async {
        let nm = makeNetworkClient(throwing: URLError(.serverCertificateHasUnknownRoot))

        await #expect(throws: NetworkTransportError.secureConnectionNotPossible) {
            _ = try await nm.getResponse(for: httpRequest, requestConfiguration: AnyNetworkRequest())
        }
    }

    /// When `URLSession` throws `serverCertificateNotYetValid`, `getResponse` must map it
    /// to `NetworkTransportError.secureConnectionNotPossible`.
    @Test
    func `getResponse when URLSessionThrowsCertificateNotYetValid then ThrowsSecureConnectionNotPossible`() async {
        let nm = makeNetworkClient(throwing: URLError(.serverCertificateNotYetValid))

        await #expect(throws: NetworkTransportError.secureConnectionNotPossible) {
            _ = try await nm.getResponse(for: httpRequest, requestConfiguration: AnyNetworkRequest())
        }
    }

    // MARK: - Non-TLS Error Wrapping

    /// An unrelated `URLError` (e.g. no network) is wrapped in `NetworkTransportError.unknownURLError`.
    @Test
    func `getResponse when URLSessionThrowsGenericError then WrapsInUnknownURLError`() async {
        let nm = makeNetworkClient(throwing: URLError(.networkConnectionLost))

        await #expect(throws: NetworkTransportError.self) {
            _ = try await nm.getResponse(for: httpRequest, requestConfiguration: AnyNetworkRequest())
        }
    }

    /// A `.cancelled` error is wrapped in `NetworkTransportError.unknownURLError`.
    @Test
    func `getResponse when URLSessionThrowsCancelled then WrapsInUnknownURLError`() async {
        let nm = makeNetworkClient(throwing: URLError(.cancelled))

        await #expect(throws: NetworkTransportError.self) {
            _ = try await nm.getResponse(for: httpRequest, requestConfiguration: AnyNetworkRequest())
        }
    }

    // MARK: - Error Interceptor Invocation

    /// Verifies that the error interceptor receives `secureConnectionNotPossible` when
    /// a TLS error occurs.
    actor ErrorRecorder {
        var error: NetworkTransportError?
        func set(_ value: NetworkTransportError) { error = value }
        func get() -> NetworkTransportError? { error }
    }

    actor BoolRecorder {
        var value: Bool = false
        func setTrue() { value = true }
        func get() -> Bool { value }
    }

    @Test
    func `getResponse when TLSError then ErrorInterceptorReceivesSecureConnectionNotPossible`() async {
        let recorder = ErrorRecorder()
        let errorInterceptor = ClosureErrorInterceptor { error in
            await recorder.set(error)
            return .defaultHandling
        }
        let nm = makeNetworkClient(
            throwing: URLError(.serverCertificateUntrusted),
            errorInterceptor: errorInterceptor
        )

        _ = try? await nm.getResponse(for: httpRequest, requestConfiguration: AnyNetworkRequest())

        let receivedError = await recorder.get()
        #expect(receivedError == .secureConnectionNotPossible)
    }

    /// Verifies that the error interceptor IS called for non-TLS URLErrors (wrapped as unknownURLError).
    @Test
    func `getResponse when nonTLSError then ErrorInterceptorIsCalled`() async {
        let recorder = ErrorRecorder()
        let errorInterceptor = ClosureErrorInterceptor { error in
            await recorder.set(error)
            return .defaultHandling
        }
        let nm = makeNetworkClient(
            throwing: URLError(.networkConnectionLost),
            errorInterceptor: errorInterceptor
        )

        _ = try? await nm.getResponse(for: httpRequest, requestConfiguration: AnyNetworkRequest())

        let receivedError = await recorder.get()
        // Verify the error interceptor was called with unknownURLError
        if case .unknownURLError = receivedError {
            // Expected
        } else {
            Issue.record("Expected unknownURLError but got \(String(describing: receivedError))")
        }
    }
}

// MARK: - Response Interceptor Error Forwarding Tests

/// Tests that when a response interceptor throws an `NetworkTransportError`, the error
/// interceptors are called before the error is rethrown.
@Suite(.serialized)
@NetworkActor
struct ResponseInterceptorErrorForwardingTests {
    // MARK: - Helpers

    /// Creates a `NetworkClientImpl` whose URLSession succeeds (via `SucceedingURLProtocol`)
    /// but whose response interceptor throws the given `NetworkTransportError`.
    private func makeNetworkClient(
        responseInterceptorError: NetworkTransportError,
        errorInterceptor: NetworkErrorInterceptor = ClosureErrorInterceptor { _ in .defaultHandling }
    ) -> NetworkClientImpl {
        let sessionConfig = URLSessionConfiguration.ephemeral
        sessionConfig.protocolClasses = [SucceedingURLProtocol.self]
        let nmConfig = NetworkClientConfiguration(
            environment: testNetworkEnvironment,
            responseInterceptor: ClosureResponseInterceptor { (_: inout HTTPResponse) async throws(NetworkTransportError) -> NetworkResponseInterceptorResult in
                throw responseInterceptorError
            },
            errorInterceptor: errorInterceptor
        )
        let session = URLSession(configuration: sessionConfig)
        return NetworkClientImpl(urlSession: session, configuration: nmConfig)
    }

    private var httpRequest: HTTPRequest {
        HTTPRequest(urlRequest: URLRequest(url: URL(string: "https://api.test.com/test")!))
    }

    // MARK: - Tests

    /// When a response interceptor throws `NetworkTransportError.errorStatusCode`, the error
    /// interceptor must receive that error before it is rethrown.
    actor ErrorRecorder {
        var error: NetworkTransportError?
        func set(_ value: NetworkTransportError) { error = value }
        func get() -> NetworkTransportError? { error }
    }

    @Test
    func `getResponse when responseInterceptorThrowsNetworkTransportError then ErrorInterceptorIsCalled`() async {
        let expectedResponse = HTTPResponse(
            request: HTTPRequest(urlRequest: URLRequest(url: URL(string: "https://api.test.com/test")!)),
            urlResponse: HTTPURLResponse(),
            data: Data()
        )
        let thrownError = NetworkTransportError.errorStatusCode(code: 403, response: expectedResponse)
        let recorder = ErrorRecorder()
        let errorInterceptor = ClosureErrorInterceptor { error in
            await recorder.set(error)
            return .defaultHandling
        }

        let nm = makeNetworkClient(
            responseInterceptorError: thrownError,
            errorInterceptor: errorInterceptor
        )

        _ = try? await nm.getResponse(for: httpRequest, requestConfiguration: AnyNetworkRequest())

        let receivedError = await recorder.get()
        #expect(receivedError == thrownError)
    }

    /// When a response interceptor throws `secureConnectionNotPossible`, the error
    /// interceptor must receive it.
    @Test
    func `getResponse when responseInterceptorThrowsSecureConnectionNotPossible then ErrorInterceptorReceivesIt`() async {
        let recorder = ErrorRecorder()
        let errorInterceptor = ClosureErrorInterceptor { error in
            await recorder.set(error)
            return .defaultHandling
        }

        let nm = makeNetworkClient(
            responseInterceptorError: .secureConnectionNotPossible,
            errorInterceptor: errorInterceptor
        )

        _ = try? await nm.getResponse(for: httpRequest, requestConfiguration: AnyNetworkRequest())

        let receivedError = await recorder.get()
        #expect(receivedError == .secureConnectionNotPossible)
    }
}

// MARK: - Per-Request Error Interceptor Tests
@NetworkActor
struct PerRequestErrorInterceptorTests {
    // MARK: - Helpers

    private func makeNetworkClient(
        throwing error: Error,
        globalErrorInterceptor: NetworkErrorInterceptor = ClosureErrorInterceptor { _ in .defaultHandling }
    ) -> NetworkClientImpl {
        ThrowingURLProtocol.thrownError = error
        let sessionConfig = URLSessionConfiguration.ephemeral
        sessionConfig.protocolClasses = [ThrowingURLProtocol.self]
        let nmConfig = NetworkClientConfiguration(
            environment: testNetworkEnvironment,
            errorInterceptor: globalErrorInterceptor
        )
        let session = URLSession(configuration: sessionConfig)
        return NetworkClientImpl(urlSession: session, configuration: nmConfig)
    }

    // MARK: - Tests

    /// When a request conforms to `NetworkRequestWithErrorInterceptor`, its per-request
    /// error interceptor must be called after the global one.
    actor BoolRecorder {
        var value: Bool = false
        func setTrue() { value = true }
        func get() -> Bool { value }
    }

    @Test
    func `getResponse when requestHasErrorInterceptor then BothGlobalAndPerRequestAreCalled`() async {
        let globalRecorder = BoolRecorder()
        let perRequestRecorder = BoolRecorder()

        let globalInterceptor = ClosureErrorInterceptor { _ in
            await globalRecorder.setTrue()
            return .defaultHandling
        }
        let nm = makeNetworkClient(
            throwing: URLError(.serverCertificateUntrusted),
            globalErrorInterceptor: globalInterceptor
        )

        let request = AnyNetworkRequestWithErrorInterceptor(
            errorInterceptor: ClosureErrorInterceptor { _ in
                await perRequestRecorder.setTrue()
                return .defaultHandling
            }
        )

        _ = try? await nm.getResponse(
            for: HTTPRequest(urlRequest: URLRequest(url: URL(string: "https://api.test.com/test")!)),
            requestConfiguration: request
        )

        let globalCalled = await globalRecorder.get()
        let perRequestCalled = await perRequestRecorder.get()
        #expect(globalCalled == true)
        #expect(perRequestCalled == true)
    }
}

// MARK: - NetworkClientConfiguration Error Interceptor Tests

struct NetworkClientConfigurationErrorInterceptorTests {
    actor BoolRecorder {
        var value: Bool = false
        func setTrue() { value = true }
        func get() -> Bool { value }
    }

    @Test
    func `configuration when initialisedWithErrorInterceptor then StoresIt`() async {
        let recorder = BoolRecorder()
        let interceptor = ClosureErrorInterceptor { _ in
            await recorder.setTrue()
            return .defaultHandling
        }
        let config = NetworkClientConfiguration(
            environment: testNetworkEnvironment,
            errorInterceptor: interceptor
        )

        _ = await config.errorInterceptor.intercept(error: .secureConnectionNotPossible)
        let called = await recorder.get()
        #expect(called == true)
    }

    @Test
    func `configuration when initialisedWithoutErrorInterceptor then DefaultIsNoOp`() async {
        let config = NetworkClientConfiguration(environment: testNetworkEnvironment)

        let result = await config.errorInterceptor.intercept(error: .secureConnectionNotPossible)
        #expect(result == .defaultHandling)
    }
}

// MARK: - Test Helpers

/// A `URLProtocol` subclass that immediately fails every request with a configurable error.
///
/// - Important: Access is guarded by `@Suite(.serialized)` on the consuming test suite so
///   that `thrownError` is not mutated concurrently.
private final class ThrowingURLProtocol: URLProtocol {
    nonisolated(unsafe) static var thrownError: Error = URLError(.cancelled)

    override class func canInit(with _: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        client?.urlProtocol(self, didFailWithError: Self.thrownError)
    }

    override func stopLoading() { }
}

/// A `URLProtocol` subclass that succeeds every request with a 200 response and empty body.
/// Used to test response interceptor error forwarding paths.
private final class SucceedingURLProtocol: URLProtocol {
    override class func canInit(with _: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: nil
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data())
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() { }
}

/// A minimal `NetworkRequest` used as `requestConfiguration` in `getResponse` tests.
/// The actual request URL is supplied via `HTTPRequest`, so the endpoint here is unused.
private struct AnyNetworkRequest: NetworkRequest {
    let path = URLPath(unsafeValue: "stub")
    let method: HTTPMethod = .get
    let headers: [HTTPHeader: String] = [:]
}

/// A `NetworkRequest` with a per-request error interceptor for testing `NetworkRequestWithErrorInterceptor`.
private struct AnyNetworkRequestWithErrorInterceptor: NetworkRequestWithErrorInterceptor {
    let path = URLPath(unsafeValue: "stub")
    let method: HTTPMethod = .get
    let headers: [HTTPHeader: String] = [:]
    let errorInterceptor: NetworkErrorInterceptor
}

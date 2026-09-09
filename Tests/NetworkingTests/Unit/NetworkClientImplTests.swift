//
//  NetworkClientImplTests.swift
//  Networking
//
//  Created by Jan Frederik Zerrath on 19.08.25.
//  Copyright 2026 adesso SE
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//

// swiftlint:disable file_length

@testable import Networking
import Testing

@NetworkActor
struct NetworkClientImplTests {
    // MARK: - Initialization Tests

    @Test
    func `init when Using Default Initializer then Configures Ephemeral URLSession`() async {
        // Given / When
        let networkClient = NetworkClientImpl(environment: testNetworkEnvironment)
        // Then
        let policy = networkClient.urlSession.configuration.requestCachePolicy
        #expect(policy == URLSessionConfiguration.ephemeral.requestCachePolicy)
    }

    @Test
    func `init when Provided Environment then Sets Environment Correctly`() async {
        // Given / When
        let networkClient = NetworkClientImpl(environment: testNetworkEnvironment)
        // Then
        let base = networkClient.configuration.environment.base
        #expect(base == testNetworkEnvironment.base)
    }

    @Test
    func `init when Provided URLSession And Environment then ConfiguresBothCorrectly`() async {
        // Given
        let urlSession = URLSession.shared
        // When
        let networkClient = NetworkClientImpl(urlSession: urlSession, environment: testNetworkEnvironment)
        // Then
        #expect(networkClient.urlSession === urlSession)
        #expect(networkClient.configuration.environment.base == testNetworkEnvironment.base)
    }

    // MARK: - Query Items Tests

    @Test
    func `queryItems when RequestHasNoQuery then ReturnsNil`() async throws {
        // Given
        let networkClient = NetworkClientImpl(environment: testNetworkEnvironment)
        let request = TestNetworkRequest()
        // When
        let items = try networkClient.queryItems(request: request)
        // Then
        #expect(items == nil)
    }

    @Test
    func `queryItems when RequestHasQuery then ReturnsCorrectItems`() async throws {
        // Given
        let networkClient = NetworkClientImpl(environment: testNetworkEnvironment)
        let request = TestNetworkRequestWithQuery(query: .init(name: "test", value: 42, flag: true))
        // When
        let items = try networkClient.queryItems(request: request)
        // Then
        #expect(items?.count == 3)
        #expect(items?.contains(URLQueryItem(name: "flag", value: "true")) == true)
        #expect(items?.contains(URLQueryItem(name: "name", value: "test")) == true)
        #expect(items?.contains(URLQueryItem(name: "value", value: "42")) == true)
    }

    @Test
    func `queryItems when RequestHasEmptyQuery then ReturnsNil`() async throws {
        // Given
        let networkClient = NetworkClientImpl(environment: testNetworkEnvironment)
        let request = TestNetworkRequestWithEmptyQuery(query: EmptyQuery())
        // When
        let items = try networkClient.queryItems(request: request)
        // Then
        #expect(items == nil)
    }

    @Test
    func `queryItems when RequestHasDateQuery then UsesDefaultDateOnlyStrategy`() async throws {
        // Given
        let networkClient = NetworkClientImpl(environment: testNetworkEnvironment)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let date = try #require(calendar.date(from: DateComponents(year: 2026, month: 1, day: 31, hour: 12, minute: 45, second: 6)))
        let request = TestNetworkRequestWithDateQuery(query: .init(date: date))

        // When
        let items = try networkClient.queryItems(request: request)

        // Then
        #expect(items == [URLQueryItem(name: "date", value: "2026-01-31")])
    }

    @Test
    func `queryItems when RequestOverridesDateEncodingStrategy then UsesDateTimeWithOffset`() async throws {
        // Given
        let networkClient = NetworkClientImpl(environment: testNetworkEnvironment)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let date = try #require(calendar.date(from: DateComponents(year: 2026, month: 1, day: 31, hour: 12, minute: 45, second: 6)))
        let request = TestNetworkRequestWithDateTimeQuery(query: .init(date: date))

        // When
        let items = try networkClient.queryItems(request: request)

        // Then
        #expect(items == [URLQueryItem(name: "date", value: expectedISO8601DateTimeWithOffset(for: date))])
    }

    // MARK: - Body Encoding Tests

    @Test
    func `body when UsingDefaultEncoder then UsesJSONEncoder`() async throws {
        // Given
        let networkClient = NetworkClientImpl(environment: testNetworkEnvironment)
        let request = TestNetworkRequestWithBody(body: .init(id: "123", name: "test"))
        // When
        let data = try networkClient.body(request: request)
        // Then
        let decoded = try JSONDecoder().decode(TestRequestBody.self, from: data)
        #expect(decoded.id == "123")
        #expect(decoded.name == "test")
    }

    @Test
    func `body when UsingCustomEncoder then UsesCustomEncoder`() async throws {
        // Given
        let networkClient = NetworkClientImpl(environment: testNetworkEnvironment)
        let request = TestNetworkRequestWithBodyAndEncoder(body: .init(id: "456", name: "custom"), encoder: TestDataEncoder())
        // When
        let data = try networkClient.body(request: request)
        // Then
        #expect(String(data: data, encoding: .utf8) == "TestDataEncoder")
    }

    @Test
    func `body when EncodingFails then ThrowsRequestBuildingFailure`() async {
        // Given
        let networkClient = NetworkClientImpl(environment: testNetworkEnvironment)
        let request = TestNetworkRequestWithBodyAndEncoder(body: .init(id: "789", name: "failing"), encoder: FailingDataEncoder())
        // When / Then
        do {
            _ = try networkClient.body(request: request)
            Issue.record("Expected RequestBuildingFailure.cannotEncodeRequestBody to be thrown")
        } catch {
            if case .cannotEncodeRequestBody = error {
                // Expected
            } else {
                Issue.record("Expected cannotEncodeRequestBody but got \(error)")
            }
        }
    }

    // MARK: - Content Type Header Tests

    @Test
    func `makeHTTPRequest when BodyPresent then SetsDefaultContentTypeHeader`() async throws {
        // Given
        let networkClient = NetworkClientImpl(environment: testNetworkEnvironment)
        let request = TestNetworkRequestWithBody(body: .init(id: "abc", name: "contentType"))
        // When
        let urlRequest = try networkClient.makeHTTPRequest(requestConfiguration: request).urlRequest
        // Then
        #expect(urlRequest.value(forHTTPHeaderField: "Content-Type") == "application/json")
    }

    @Test
    func `makeHTTPRequest when BodyWithCustomContentType then SetsCustomContentTypeHeader`() async throws {
        // Given
        let custom = "application/x-test-\(UUID().uuidString)"
        let networkClient = NetworkClientImpl(environment: testNetworkEnvironment)
        let request = TestRequestWithCustomContentType(
            body: .init(id: "def", name: "custom"),
            contentType: .init(contentTypeString: custom)
        )
        // When
        let urlRequest = try networkClient.makeHTTPRequest(requestConfiguration: request).urlRequest
        // Then
        #expect(urlRequest.value(forHTTPHeaderField: "Content-Type") == custom)
    }

    // MARK: - Request Interceptor Tests

    @Test
    func `intercept when NoCustomInterceptor then UsesDefaultInterceptor`() async throws {
        // Given
        let called = ActorBox(false)
        let defaultInterceptor = ClosureRequestInterceptor { _ in
            await called.set(true)
        }
        let nm = NetworkClientImpl(configuration: .init(environment: testNetworkEnvironment, requestInterceptor: defaultInterceptor))
        var req = HTTPRequest(urlRequest: URLRequest(url: URL(string: "https://test.com")!))
        let request = TestNetworkRequest()
        // When
        try await nm.intercept(request: request, httpRequest: &req)
        // Then
        #expect(await called.get())
    }

    @Test
    func `intercept when CustomInterceptorProvided then ChainsAndExecutesBoth`() async throws {
        // Given
        let defaultCalled = ActorBox(false)
        let customCalled = ActorBox(false)
        let defaultInterceptor = ClosureRequestInterceptor { _ in
            await defaultCalled.set(true)
        }
        let nm = NetworkClientImpl(configuration: .init(environment: testNetworkEnvironment, requestInterceptor: defaultInterceptor))
        let custom = ClosureRequestInterceptor { _ in
            await customCalled.set(true)
        }
        let request = TestNetworkRequestWithRequestInterceptor(requestInterceptor: custom)
        var httpReq = HTTPRequest(urlRequest: URLRequest(url: URL(string: "https://test.com")!))
        // When
        try await nm.intercept(request: request, httpRequest: &httpReq)
        // Then
        #expect(await customCalled.get())
        #expect(await defaultCalled.get())
    }

    // MARK: - Response Interceptor Tests

    @Test
    func `interceptResponse when NoCustomInterceptor then UsesDefaultInterceptorResult`() async throws {
        // Given
        let defaultInterceptor = ClosureResponseInterceptor { _ in .retryRequest }
        let nm = NetworkClientImpl(configuration: .init(environment: testNetworkEnvironment, responseInterceptor: defaultInterceptor))
        var httpResponse = generateHTTPResponse()
        let request = TestNetworkRequest()
        // When
        let result = try await nm.intercept(request: request, httpResponse: &httpResponse)
        // Then
        #expect(result == .retryRequest)
    }

    @Test
    func `interceptResponse when CustomInterceptorProvided then CustomResultTakesPrecedence`() async throws {
        // Given
        let defaultInterceptor = ClosureResponseInterceptor { _ in .defaultHandling }
        let custom = ClosureResponseInterceptor { _ in .retryRequest }
        let nm = NetworkClientImpl(configuration: .init(environment: testNetworkEnvironment, responseInterceptor: defaultInterceptor))
        var httpResponse = generateHTTPResponse()
        let request = TestRequestWithResponseInterceptor(responseInterceptor: custom)
        // When
        let result = try await nm.intercept(request: request, httpResponse: &httpResponse)
        // Then
        #expect(result == .retryRequest)
    }
}

@NetworkActor
extension NetworkClientImplTests {
    // MARK: - Response Decoding Tests

    @Test
    func `decodeResponse when UsingDefaultDecoder then UsesJSONDecoder`() async throws {
        // Given
        let nm = NetworkClientImpl(environment: testNetworkEnvironment)
        let body = TestResponseBody(id: "123", success: true)
        let data = try JSONEncoder().encode(body)
        let httpResponse = generateHTTPResponse(data: data)
        let request = TestNetworkRequestWithResponse()
        // When
        let decoded = try nm.decodeResponse(request: request, httpResponse: httpResponse)
        // Then
        #expect(decoded.id == "123" && decoded.success)
    }

    @Test
    func `decodeResponse when UsingCustomDecoder then UsesCustomDecoder`() async throws {
        // Given
        let nm = NetworkClientImpl(environment: testNetworkEnvironment)
        let httpResponse = generateHTTPResponse(data: Data("ignored".utf8))
        let request = TestNetworkRequestWithResponseAndDecoder(decoder: TestDataDecoder())
        // When
        let decoded = try nm.decodeResponse(request: request, httpResponse: httpResponse)
        // Then
        #expect(decoded.id == "TestDataDecoder" && decoded.success)
    }

    @Test
    func `decodeResponse when DataIsEmpty then ThrowsResponseHasNoData`() async {
        // Given
        let nm = NetworkClientImpl(environment: testNetworkEnvironment)
        let httpResponse = generateHTTPResponse(data: Data())
        let request = TestNetworkRequestWithResponse()
        // When / Then
        #expect(throws: ResponseDecodingFailure.responseHasNoData) {
            _ = try nm.decodeResponse(request: request, httpResponse: httpResponse)
        }
    }

    // MARK: - URL Request Creation Tests

    @Test
    func `makeHTTPRequest when UsingBasicRequest then BuildsCorrectURLRequest`() async throws {
        // Given
        let nm = NetworkClientImpl(environment: testNetworkEnvironment)
        let request = TestNetworkRequest(path: URLPath(unsafeValue: "users"), method: .get, headers: ["Authorization": "Bearer token"])
        // When
        let urlRequest = try nm.makeHTTPRequest(requestConfiguration: request).urlRequest
        // Then
        #expect(urlRequest.url?.absoluteString == "https://api.test.com/users")
        #expect(urlRequest.httpMethod == "GET")
        #expect(urlRequest.value(forHTTPHeaderField: "Authorization") == "Bearer token")
    }

    @Test
    func `makeHTTPRequest when RequestHasQuery then AppendsQueryParameters`() async throws {
        // Given
        let nm = NetworkClientImpl(environment: testNetworkEnvironment)
        let request = TestNetworkRequestWithQuery(path: URLPath(unsafeValue: "search"), query: .init(name: "test", value: 42, flag: true))
        // When
        let urlRequest = try nm.makeHTTPRequest(requestConfiguration: request).urlRequest
        // Then
        let comps = URLComponents(url: urlRequest.url!, resolvingAgainstBaseURL: false)
        #expect(comps?.queryItems?.count == 3)
        #expect(comps?.queryItems?.contains(URLQueryItem(name: "name", value: "test")) == true)
    }

    // MARK: - Property Configuration Tests

    @Test
    func `httpBodyEncoder when Default then IsJSONEncoder`() async {
        let nm = NetworkClientImpl(environment: testNetworkEnvironment)
        #expect(nm.configuration.httpBodyEncoder is JSONEncoder)
    }

    @Test
    func `httpBodyDecoder when Default then IsJSONDecoder`() async {
        let nm = NetworkClientImpl(environment: testNetworkEnvironment)
        #expect(nm.configuration.httpBodyDecoder is JSONDecoder)
    }

    @Test
    func `requestInterceptor when Default then IsChainedRequestInterceptor`() async {
        let nm = NetworkClientImpl(environment: testNetworkEnvironment)
        #expect(nm.configuration.requestInterceptor is ChainedRequestInterceptor)
    }

    @Test
    func `responseInterceptor when Default then IsChainedResponseInterceptor`() async {
        // Status validation is now built into NetworkClient via NetworkRequest.allowedStatusCodes;
        // the default responseInterceptor is therefore a no-op ChainedResponseInterceptor.
        let nm = NetworkClientImpl(environment: testNetworkEnvironment)
        #expect(nm.configuration.responseInterceptor is ChainedResponseInterceptor)
    }

    // MARK: - allowedStatusCodes Tests

    @Test
    func `allowedStatusCodes when Default then Is200To300`() {
        let request = TestNetworkRequest()
        #expect(request.allowedStatusCodes == 200 ..< 300)
    }

    @Test
    func `allowedStatusCodes when CustomRange then UsesCustomRange`() {
        struct CustomRequest: NetworkRequest {
            let path: URLPath = .init(unsafeValue: "stub")
            let method: HTTPMethod = .get
            var allowedStatusCodes: Range<Int> { 200 ..< 202 }
        }
        let request = CustomRequest()
        #expect(request.allowedStatusCodes == 200 ..< 202)
    }

    // MARK: - Environment Based URL Composition

    @Test
    func `makeHTTPRequest when UsingBaseURLRequest then CombinesBaseURLWithPath`() async throws {
        let nm = NetworkClientImpl(environment: testNetworkEnvironment)
        let request = TestNetworkRequestWithBaseURL(path: "users/123", method: .get)
        let urlRequest = try nm.makeHTTPRequest(requestConfiguration: request).urlRequest
        #expect(urlRequest.url?.absoluteString == "https://api.test.com/users/123")
    }

    @Test
    func `makeHTTPRequest when UsingBaseURLRequest then MergesEnvironmentHeaders`() async throws {
        let nm = NetworkClientImpl(environment: testNetworkEnvironment)
        let request = TestNetworkRequestWithBaseURL(path: "data", method: .post, headers: ["Authorization": "Bearer token"])
        let urlRequest = try nm.makeHTTPRequest(requestConfiguration: request).urlRequest
        #expect(urlRequest.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(urlRequest.value(forHTTPHeaderField: "X-API-Key") == "test-key")
        #expect(urlRequest.value(forHTTPHeaderField: "Authorization") == "Bearer token")
    }

    @Test
    func `makeHTTPRequest when UsingBaseURLRequestAndRequestHeadersOverrideEnvironment then UsesRequestHeaders`() async throws {
        let nm = NetworkClientImpl(environment: testNetworkEnvironment)
        let request = TestNetworkRequestWithBaseURL(path: "override", method: .put, headers: ["Content-Type": "application/xml"])
        let urlRequest = try nm.makeHTTPRequest(requestConfiguration: request).urlRequest
        #expect(urlRequest.value(forHTTPHeaderField: "Content-Type") == "application/xml")
        #expect(urlRequest.value(forHTTPHeaderField: "X-API-Key") == "test-key")
    }

    @Test
    func `makeHTTPRequest when UsingBaseURLRequestAndQuery then AppendsQueryToEnvironmentURL`() async throws {
        let nm = NetworkClientImpl(environment: testNetworkEnvironment)
        let request = TestNetworkRequestWithBaseURLAndQuery(path: "search", query: .init(name: "search", value: 100, flag: false))
        let urlRequest = try nm.makeHTTPRequest(requestConfiguration: request).urlRequest
        let comps = URLComponents(url: urlRequest.url!, resolvingAgainstBaseURL: false)
        #expect(comps?.path == "/search")
        #expect(comps?.queryItems?.contains(URLQueryItem(name: "value", value: "100")) == true)
    }

    @Test
    func `makeHTTPRequest when UsingBaseURLRequestWithEmptyPath then UsesOnlyBaseURL`() async throws {
        let nm = NetworkClientImpl(environment: testNetworkEnvironment)
        let request = TestNetworkRequestWithBaseURL(path: "", method: .get)
        let urlRequest = try nm.makeHTTPRequest(requestConfiguration: request).urlRequest
        #expect(urlRequest.url?.absoluteString == "https://api.test.com/")
    }

    @Test
    func `makeHTTPRequest when UsingBaseURLRequestWithRootPath then UsesBaseURLWithSlash`() async throws {
        let nm = NetworkClientImpl(environment: testNetworkEnvironment)
        let request = TestNetworkRequestWithBaseURL(path: "/", method: .get)
        let urlRequest = try nm.makeHTTPRequest(requestConfiguration: request).urlRequest
        #expect(urlRequest.url?.absoluteString == "https://api.test.com/")
    }

    @Test
    func `makeHTTPRequest when UsingBaseURLRequestWithNestedPath then BuildsCorrectURL`() async throws {
        let nm = NetworkClientImpl(environment: testNetworkEnvironment)
        let request = TestNetworkRequestWithBaseURL(path: "api/v1/users/profile", method: .get)
        let urlRequest = try nm.makeHTTPRequest(requestConfiguration: request).urlRequest
        #expect(urlRequest.url?.absoluteString == "https://api.test.com/api/v1/users/profile")
    }

    @Test
    func `makeHTTPRequest when UsingDifferentEnvironment then UsesEnvironmentBaseURL`() async throws {
        let custom = NetworkEnvironment(
            base: URLBase(unsafeValue: "https://staging.example.com"),
            defaultHeaders: ["Environment": "staging"]
        )
        let nm = NetworkClientImpl(environment: custom)
        let request = TestNetworkRequestWithBaseURL(path: "test", method: .get)
        let urlRequest = try nm.makeHTTPRequest(requestConfiguration: request).urlRequest
        #expect(urlRequest.url?.absoluteString == "https://staging.example.com/test")
        #expect(urlRequest.value(forHTTPHeaderField: "Environment") == "staging")
    }
}

// MARK: - NetworkRequestWithTimeout Tests

@NetworkActor
extension NetworkClientImplTests {
    // MARK: - NetworkRequestWithTimeout Tests

    @Test
    func `makeHTTPRequest when PlainRequestConformsToNetworkRequestWithTimeout then SetsTimeoutInterval`() async throws {
        // Given
        let nm = NetworkClientImpl(environment: testNetworkEnvironment)
        let expectedTimeout: TimeInterval = 60
        let request = TestNetworkRequestWithTimeout(
            path: URLPath(unsafeValue: "slow"),
            method: .get,
            timeout: expectedTimeout
        )
        // When
        let urlRequest = try nm.makeHTTPRequest(requestConfiguration: request).urlRequest
        // Then
        #expect(urlRequest.timeoutInterval == expectedTimeout)
    }

    @Test
    func `makeHTTPRequest when PlainRequestDoesNotConformToNetworkRequestWithTimeout then UsesDefaultTimeoutInterval`() async throws {
        // Given
        let nm = NetworkClientImpl(environment: testNetworkEnvironment)
        let request = TestNetworkRequest(
            path: URLPath(unsafeValue: "fast"),
            method: .get
        )
        // When
        let urlRequest = try nm.makeHTTPRequest(requestConfiguration: request).urlRequest
        // Then – URLRequest default is 60s unless explicitly set; the session config (20s) only
        // applies once handed to URLSession, not on the URLRequest value itself.
        // We verify the timeout was NOT overridden (i.e. it equals URLRequest's own default).
        #expect(urlRequest.timeoutInterval == 60) // URLRequest.init default
    }

    @Test
    func `makeHTTPRequest when EnvironmentRequestConformsToNetworkRequestWithTimeout then SetsTimeoutInterval`() async throws {
        // Given
        let nm = NetworkClientImpl(environment: testNetworkEnvironment)
        let expectedTimeout: TimeInterval = 120
        let request = TestNetworkRequestWithBaseURLAndTimeout(
            path: "upload",
            method: .post,
            timeout: expectedTimeout
        )
        // When
        let urlRequest = try nm.makeHTTPRequest(requestConfiguration: request).urlRequest
        // Then
        #expect(urlRequest.timeoutInterval == expectedTimeout)
    }

    @Test
    func `makeHTTPRequest when EnvironmentRequestDoesNotConformToNetworkRequestWithTimeout then UsesDefaultTimeoutInterval`() async throws {
        // Given
        let nm = NetworkClientImpl(environment: testNetworkEnvironment)
        let request = TestNetworkRequestWithBaseURL(path: "normal", method: .get)
        // When
        let urlRequest = try nm.makeHTTPRequest(requestConfiguration: request).urlRequest
        // Then – no override applied; URLRequest default value expected
        #expect(urlRequest.timeoutInterval == 60) // URLRequest.init default
    }

    @Test
    func `makeHTTPRequest when TimeoutIsZero then SetsTimeoutIntervalToZero`() async throws {
        // Given
        let nm = NetworkClientImpl(environment: testNetworkEnvironment)
        let request = TestNetworkRequestWithTimeout(
            path: URLPath(unsafeValue: "zero"),
            method: .get,
            timeout: 0
        )
        // When
        let urlRequest = try nm.makeHTTPRequest(requestConfiguration: request).urlRequest
        // Then
        #expect(urlRequest.timeoutInterval == 0)
    }

    @Test
    func `makeHTTPRequest when EnvironmentRequestTimeoutDiffersFromSessionDefault then OverridesCorrectly`() async throws {
        // Given – session is configured with 20s default
        let nm = NetworkClientImpl(environment: testNetworkEnvironment)
        let expectedTimeout: TimeInterval = 5
        let request = TestNetworkRequestWithBaseURLAndTimeout(
            path: "health",
            method: .get,
            timeout: expectedTimeout
        )
        // When
        let urlRequest = try nm.makeHTTPRequest(requestConfiguration: request).urlRequest
        // Then – per-request timeout wins over session default
        #expect(urlRequest.timeoutInterval == expectedTimeout)
    }

    // MARK: - HTTPRequest Configuration & Environment Injection Tests

    @Test
    func `makeHTTPRequest when PlainRequest then SetsConfigurationToRequestConfiguration`() async throws {
        // Given
        let nm = NetworkClientImpl(environment: testNetworkEnvironment)
        let request = TestNetworkRequest(path: URLPath(unsafeValue: "config"), method: .post, headers: ["X-Custom": "value"])
        // When
        let httpRequest = try nm.makeHTTPRequest(requestConfiguration: request)
        // Then
        #expect(httpRequest.configuration.path.value == request.path.value)
        #expect(httpRequest.configuration.method == request.method)
    }

    @Test
    func `makeHTTPRequest when PlainRequest then EnvironmentIsSet`() async throws {
        // Given
        let nm = NetworkClientImpl(environment: testNetworkEnvironment)
        let request = TestNetworkRequest()
        // When
        let httpRequest = try nm.makeHTTPRequest(requestConfiguration: request)
        // Then — all requests carry the manager's environment
        #expect(httpRequest.environment.base == testNetworkEnvironment.base)
    }

    @Test
    func `makeHTTPRequest when EnvironmentRequest then SetsConfigurationToRequestConfiguration`() async throws {
        // Given
        let nm = NetworkClientImpl(environment: testNetworkEnvironment)
        let request = TestNetworkRequestWithBaseURL(path: "users", method: .get, headers: ["Authorization": "Bearer token"])
        // When
        let httpRequest = try nm.makeHTTPRequest(requestConfiguration: request)
        // Then – configuration should be the original request
        let config = httpRequest.configuration as? TestNetworkRequestWithBaseURL
        #expect(config != nil)
        #expect(config?.path.value == "users")
        #expect(config?.method == .get)
    }

    @Test
    func `makeHTTPRequest when EnvironmentRequest then SetsEnvironmentToManagerEnvironment`() async throws {
        // Given
        let nm = NetworkClientImpl(environment: testNetworkEnvironment)
        let request = TestNetworkRequestWithBaseURL(path: "data", method: .get)
        // When
        let httpRequest = try nm.makeHTTPRequest(requestConfiguration: request)
        // Then
        #expect(httpRequest.environment.base == testNetworkEnvironment.base)
        #expect(httpRequest.environment.defaultHeaders == testNetworkEnvironment.defaultHeaders)
    }

    @Test
    func `makeHTTPRequest when DifferentEnvironment then InjectsCorrectEnvironment`() async throws {
        // Given
        let customEnv = NetworkEnvironment(
            base: URLBase(unsafeValue: "https://staging.example.com"),
            defaultHeaders: ["Environment": "staging"]
        )
        let nm = NetworkClientImpl(environment: customEnv)
        let request = TestNetworkRequestWithBaseURL(path: "test", method: .get)
        // When
        let httpRequest = try nm.makeHTTPRequest(requestConfiguration: request)
        // Then
        #expect(httpRequest.environment.base == customEnv.base)
        #expect(httpRequest.environment.defaultHeaders == customEnv.defaultHeaders)
    }
}

// MARK: - Test Helpers

private extension NetworkClientImplTests {
    func generateHTTPResponse(data: Data = Data("test".utf8)) -> HTTPResponse {
        let urlRequest = URLRequest(url: URL(string: "https://test.com")!)
        let httpRequest = HTTPRequest(urlRequest: urlRequest)
        let urlResponse = HTTPURLResponse(
            url: URL(string: "https://test.com")!,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
        return HTTPResponse(request: httpRequest, urlResponse: urlResponse, data: data)
    }

    func expectedISO8601DateTimeWithOffset(for date: Date) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current

        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let offsetSeconds = TimeZone.current.secondsFromGMT(for: date)
        let sign = offsetSeconds >= 0 ? "+" : "-"
        let absoluteOffsetSeconds = abs(offsetSeconds)
        let offsetHours = absoluteOffsetSeconds / 3600
        let offsetMinutes = (absoluteOffsetSeconds % 3600) / 60

        return String(
            format: "%04d-%02d-%02dT%02d:%02d:%02d%@%02d:%02d",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0,
            components.hour ?? 0,
            components.minute ?? 0,
            components.second ?? 0,
            sign,
            offsetHours,
            offsetMinutes
        )
    }
}

// MARK: - Test Types

private struct TestNetworkRequest: NetworkRequest {
    let path: URLPath
    let method: HTTPMethod
    let headers: [HTTPHeader: String]
    init(path: URLPath = URLPath(unsafeValue: "stub"), method: HTTPMethod = .get, headers: [HTTPHeader: String] = [:]) {
        self.path = path; self.method = method; self.headers = headers
    }
}

private struct TestNetworkRequestWithQuery: NetworkRequest, NetworkRequestWithQuery {
    let path: URLPath
    let method: HTTPMethod
    let headers: [HTTPHeader: String]
    let query: TestQuery
    init(path: URLPath = URLPath(unsafeValue: "stub"), method: HTTPMethod = .get, headers: [HTTPHeader: String] = [:], query: TestQuery) {
        self.path = path; self.method = method; self.headers = headers; self.query = query
    }
}

private struct TestNetworkRequestWithEmptyQuery: NetworkRequest, NetworkRequestWithQuery {
    let path: URLPath = .init(unsafeValue: "stub")
    let method: HTTPMethod = .get
    let headers: [HTTPHeader: String] = [:]
    let query: EmptyQuery
}

private struct TestNetworkRequestWithDateQuery: NetworkRequest, NetworkRequestWithQuery {
    let path: URLPath = .init(unsafeValue: "stub")
    let method: HTTPMethod = .get
    let headers: [HTTPHeader: String] = [:]
    let query: TestDateQuery
}

private struct TestNetworkRequestWithDateTimeQuery: NetworkRequest, NetworkRequestWithQuery {
    let path: URLPath = .init(unsafeValue: "stub")
    let method: HTTPMethod = .get
    let headers: [HTTPHeader: String] = [:]
    let query: TestDateQuery
    let dateEncodingStrategy: QueryDateEncodingStrategy = .dateTimeWithOffset
}

private struct TestNetworkRequestWithBody: NetworkRequestWithBody {
    let path: URLPath = .init(unsafeValue: "stub")
    let method: HTTPMethod = .post
    let headers: [HTTPHeader: String] = [:]
    let body: TestRequestBody
    let httpBodyEncoder: DataEncoding? = nil
}

private struct TestNetworkRequestWithBodyAndEncoder: NetworkRequestWithBody {
    let path: URLPath = .init(unsafeValue: "stub")
    let method: HTTPMethod = .post
    let headers: [HTTPHeader: String] = [:]
    let body: TestRequestBody
    let httpBodyEncoder: DataEncoding?
    init(body: TestRequestBody, encoder: DataEncoding) { self.body = body; httpBodyEncoder = encoder }
}

private struct TestRequestWithCustomContentType: NetworkRequestWithBody {
    let path: URLPath = .init(unsafeValue: "stub")
    let method: HTTPMethod = .post
    let headers: [HTTPHeader: String] = [:]
    let body: TestRequestBody
    let contentType: ContentType
    var httpBodyEncoder: DataEncoding? { nil }
}

private struct TestNetworkRequestWithResponse: NetworkRequestWithResponse {
    let path: URLPath = .init(unsafeValue: "stub")
    let method: HTTPMethod = .get
    let headers: [HTTPHeader: String] = [:]
    let httpBodyDecoder: DataDecoding? = nil
    typealias ResponseBody = TestResponseBody
}

private struct TestNetworkRequestWithResponseAndDecoder: NetworkRequestWithResponse {
    let path: URLPath = .init(unsafeValue: "stub")
    let method: HTTPMethod = .get
    let headers: [HTTPHeader: String] = [:]
    let httpBodyDecoder: DataDecoding?
    typealias ResponseBody = TestResponseBody
    init(decoder: DataDecoding) { httpBodyDecoder = decoder }
}

private struct TestNetworkRequestWithRequestInterceptor: NetworkRequest, NetworkRequestWithRequestInterceptor {
    let path: URLPath = .init(unsafeValue: "stub")
    let method: HTTPMethod = .get
    let headers: [HTTPHeader: String] = [:]
    let requestInterceptor: NetworkRequestInterceptor
}

private struct TestRequestWithResponseInterceptor: NetworkRequest, NetworkRequestWithResponseInterceptor {
    let path: URLPath = .init(unsafeValue: "stub")
    let method: HTTPMethod = .get
    let headers: [HTTPHeader: String] = [:]
    let responseInterceptor: NetworkResponseInterceptor
}

private struct TestNetworkRequestWithBaseURL: NetworkRequest {
    let path: URLPath
    let method: HTTPMethod
    let headers: [HTTPHeader: String]
    init(path: String, method: HTTPMethod = .get, headers: [HTTPHeader: String] = [:]) {
        self.path = URLPath(unsafeValue: path); self.method = method; self.headers = headers
    }
}

private struct TestNetworkRequestWithBaseURLAndQuery: NetworkRequest, NetworkRequestWithQuery {
    let path: URLPath
    let method: HTTPMethod = .get
    let headers: [HTTPHeader: String] = [:]
    let query: TestQuery
    init(path: String, query: TestQuery) { self.path = URLPath(unsafeValue: path); self.query = query }
}

// MARK: - Timeout Test Types

private struct TestNetworkRequestWithTimeout: NetworkRequest, NetworkRequestWithTimeout {
    let path: URLPath
    let method: HTTPMethod
    let headers: [HTTPHeader: String]
    let timeout: TimeInterval
    init(
        path: URLPath = URLPath(unsafeValue: "stub"),
        method: HTTPMethod = .get,
        headers: [HTTPHeader: String] = [:],
        timeout: TimeInterval
    ) {
        self.path = path; self.method = method; self.headers = headers; self.timeout = timeout
    }
}

private struct TestNetworkRequestWithBaseURLAndTimeout: NetworkRequest, NetworkRequestWithTimeout {
    let path: URLPath
    let method: HTTPMethod
    let headers: [HTTPHeader: String]
    let timeout: TimeInterval
    init(path: String, method: HTTPMethod = .get, headers: [HTTPHeader: String] = [:], timeout: TimeInterval) {
        self.path = URLPath(unsafeValue: path); self.method = method; self.headers = headers; self.timeout = timeout
    }
}

private struct TestQuery: Encodable { let name: String; let value: Int; let flag: Bool }
private struct TestDateQuery: Encodable { let date: Date }
private struct EmptyQuery: Encodable { }
private struct TestRequestBody: Codable { let id: String; let name: String }
private struct TestResponseBody: Codable { let id: String; let success: Bool }
let testNetworkEnvironment: NetworkEnvironment = .init(
    base: URLBase(unsafeValue: "https://api.test.com"),
    defaultHeaders: ["Content-Type": "application/json", "X-API-Key": "test-key"]
)

private struct TestDataEncoder: DataEncoding {
    func encode(_: some Encodable) throws -> Data { Data("TestDataEncoder".utf8) }
}

private struct FailingDataEncoder: DataEncoding {
    func encode(_: some Encodable) throws -> Data { throw TestError.encodingFailed }
}

private struct TestDataDecoder: DataDecoding {
    func decode<T: Decodable>(_: T.Type, from _: Data) throws -> T {
        guard let body = TestResponseBody(id: "TestDataDecoder", success: true) as? T else {
            throw TestError.responseIsNotT
        }

        return body
    }
}

private enum TestError: Error {
    case encodingFailed
    case responseIsNotT
}

// swiftlint:enable file_length

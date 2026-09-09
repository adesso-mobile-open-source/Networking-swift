//
//  NetworkClient.swift
//  Networking
//
//  Created by Niklas Holloh on 25.04.22.
//  Copyright 2026 adesso SE
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//

import Foundation

// MARK: - Configuration

/// Configuration for the `NetworkClient`.
public struct NetworkClientConfiguration: Sendable {
    /// The network environment that provides the base URL and default headers for all requests.
    var environment: NetworkEnvironment
    /// Gets or sets the default encoder for HTTP bodies.
    var httpBodyEncoder: DataEncoding
    /// Gets or sets the default decoder for HTTP bodies.
    var httpBodyDecoder: DataDecoding
    /// Gets or sets the default request interceptor, which is used to inspect or mutate a request
    /// after its construction (URLRequest), right before it is passed to `URLSession` for sending it
    /// to a web host.
    var requestInterceptor: NetworkRequestInterceptor
    /// Gets or sets the default response interceptor, which is used to inspect or mutate a response
    /// after receiving it from `URLSession`, before its data may be decoded and passed back to
    /// the call site.
    var responseInterceptor: NetworkResponseInterceptor
    /// Gets or sets the default error interceptor, which is called when a `URLSession` error can be
    /// mapped to a `NetworkTransportError` (e.g. TLS failures map to `.secureConnectionNotPossible`),
    /// or when a response interceptor throws a `NetworkTransportError`.
    /// Errors that cannot be mapped to a `NetworkTransportError` are rethrown directly to the caller.
    var errorInterceptor: NetworkErrorInterceptor
    /// The URLSession configuration used to create the underlying URLSession.
    /// Default is an ephemeral configuration with a 20-second timeout for requests.
    var sessionConfiguration: URLSessionConfiguration

    /// Initializes a new instance of `NetworkClientConfiguration`.
    /// - Parameters:
    ///   - environment: The network environment that provides the base URL and default headers for all requests.
    ///   - httpBodyEncoder: The default encoder for HTTP bodies. Default is `JSONEncoder()`.
    ///   - httpBodyDecoder: The default decoder for HTTP bodies. Default is `JSONDecoder()`.
    ///   - requestInterceptor: The default request interceptor. Default is an empty interceptor.
    ///   - responseInterceptor: The default response interceptor. Default is a no-op
    ///     (status validation is handled by `NetworkClient` using `NetworkRequest.allowedStatusCodes`).
    ///   - errorInterceptor: The default error interceptor for TLS/connection errors and response-interceptor failures.
    ///     Default is a no-op.
    ///   - sessionConfiguration: The URLSession configuration. Default is an ephemeral configuration with a 20-second timeout.
    public init(
        environment: NetworkEnvironment,
        httpBodyEncoder: DataEncoding = JSONEncoder(),
        httpBodyDecoder: DataDecoding = JSONDecoder(),
        requestInterceptor: NetworkRequestInterceptor = ClosureRequestInterceptor { _ in },
        responseInterceptor: NetworkResponseInterceptor = ClosureResponseInterceptor { _ in .defaultHandling },
        errorInterceptor: NetworkErrorInterceptor = ClosureErrorInterceptor { _ in .defaultHandling },
        sessionConfiguration: URLSessionConfiguration? = nil
    ) {
        self.httpBodyEncoder = httpBodyEncoder
        self.httpBodyDecoder = httpBodyDecoder
        self.requestInterceptor = requestInterceptor
        self.responseInterceptor = responseInterceptor
        self.errorInterceptor = errorInterceptor
        self.environment = environment

        // Default session configuration: ephemeral with 20-second timeout
        if let sessionConfiguration {
            self.sessionConfiguration = sessionConfiguration
        } else {
            let defaultConfiguration = URLSessionConfiguration.ephemeral
            defaultConfiguration.timeoutIntervalForRequest = 20.0
            self.sessionConfiguration = defaultConfiguration
        }
    }

    /// Initializes a new instance of `NetworkClientConfiguration`.
    /// - Parameters:
    ///   - environment: The network environment that provides the base URL and default headers for all requests.
    ///   - httpBodyEncoder: The default encoder for HTTP bodies. Default is `JSONEncoder()`.
    ///   - httpBodyDecoder: The default decoder for HTTP bodies. Default is `JSONDecoder()`.
    ///   - requestInterceptor: The default request interceptor. Default is an empty interceptor.
    ///   - responseInterceptor: The default response interceptor. Default is a no-op
    ///     (status validation is handled by `NetworkClient` using `NetworkRequest.allowedStatusCodes`).
    ///   - errorInterceptor: The default error interceptor for TLS/connection errors and response-interceptor failures.
    ///     Default is a no-op.
    ///   - sessionConfiguration: The URLSession configuration. Default is an ephemeral configuration with a 20-second timeout.
    public init(
        environment: NetworkEnvironment,
        httpBodyEncoder: DataEncoding = JSONEncoder(),
        httpBodyDecoder: DataDecoding = JSONDecoder(),
        requestInterceptor: ChainedRequestInterceptor = [],
        responseInterceptor: ChainedResponseInterceptor = [],
        errorInterceptor: ChainedErrorInterceptor = [],
        sessionConfiguration: URLSessionConfiguration? = nil
    ) {
        self.httpBodyEncoder = httpBodyEncoder
        self.httpBodyDecoder = httpBodyDecoder
        self.requestInterceptor = requestInterceptor
        self.responseInterceptor = responseInterceptor
        self.errorInterceptor = errorInterceptor
        self.environment = environment

        // Default session configuration: ephemeral with 20-second timeout
        if let sessionConfiguration {
            self.sessionConfiguration = sessionConfiguration
        } else {
            let defaultConfiguration = URLSessionConfiguration.ephemeral
            defaultConfiguration.timeoutIntervalForRequest = 20.0
            self.sessionConfiguration = defaultConfiguration
        }
    }
}

// MARK: - Public Protocol

/// A protocol around the `NetworkClientImpl` to be used for dependency injection.
@NetworkActor
public protocol NetworkClient: AnyObject, Sendable {
    // MARK: - Public Configuration

    /// Gets or sets the current `NetworkClientConfiguration`.
    var configuration: NetworkClientConfiguration { get set }

    /// Gets or sets the current `NetworkEnvironment`. Setting it mutates the
    /// environment within the `configuration`.
    var environment: NetworkEnvironment { get set }

    // MARK: - Send

    /// Sends a preconfigured instance of a `NetworkRequest`, which does not expect a response.
    /// May throw in case the request was not successful.
    /// - Parameter requestConfiguration: The `NetworkRequest` to be sent.
    @discardableResult
    func send(request requestConfiguration: some NetworkRequest) async throws(NetworkSendError) -> NetworkResponse<EmptyBody>

    /// Sends a preconfigured instance of a `NetworkRequest`, which does not expect a response and
    /// contains a request body. May throw in case the request was not successful.
    /// - Parameter requestConfiguration: The `NetworkRequestWithBody` to be sent.
    @discardableResult
    func send(request requestConfiguration: some NetworkRequestWithBody) async throws(NetworkSendError) -> NetworkResponse<EmptyBody>

    /// Sends a preconfigured instance of a `NetworkRequest`, which expects a response of `ResponseType`.
    /// May throw in case the request was not successful.
    /// - Parameter requestConfiguration: The `NetworkRequestWithResponse` to be sent.
    func send<R>(
        request requestConfiguration: R
    ) async throws(NetworkSendResponseError) -> NetworkResponse<R.ResponseBody> where R: NetworkRequestWithResponse

    /// Sends a preconfigured instance of a `NetworkRequest`, which expects a response of `ResponseType`and
    /// contains a request body. May throw in case the request was not successful.
    /// - Parameter requestConfiguration: The `NetworkRequestWithResponse & NetworkRequestWithBody` to be sent.
    func send<R>(request requestConfiguration: R) async throws(NetworkSendResponseError)
        -> NetworkResponse<R.ResponseBody> where R: NetworkRequestWithResponse, R: NetworkRequestWithBody

    /// Sends a preconfigured instance of a `NetworkRequest` with an optional response body.
    /// Returns `NetworkResponse<ResponseBody?>` where the body is `nil` if the server returned an empty response.
    ///
    /// Use this when your `ResponseBody` is defined as an optional type (e.g., `typealias ResponseBody = Draft?`).
    /// This allows the library to handle empty responses gracefully instead of throwing a decoding error.
    ///
    /// - Parameter requestConfiguration: The `NetworkRequestWithResponse` with optional `ResponseBody` to be sent.
    func send<R, T>(request requestConfiguration: R) async throws(NetworkSendOptionalResponseError)
        -> NetworkResponse<R.ResponseBody> where R: NetworkRequestWithResponse, R.ResponseBody == T?

    /// Sends a preconfigured instance of a `NetworkRequest` with both a request body and an optional response body.
    /// Returns `NetworkResponse<ResponseBody?>` where the body is `nil` if the server returned an empty response.
    ///
    /// Use this when your request sends a body and expects an optional response (e.g., `typealias ResponseBody = UpdateResult?`).
    ///
    /// - Parameter requestConfiguration: The `NetworkRequestWithResponse & NetworkRequestWithBody` with optional `ResponseBody` to be sent.
    func send<R, T>(
        request requestConfiguration: R
    ) async throws(NetworkSendOptionalResponseError) -> NetworkResponse<R.ResponseBody>
        where R: NetworkRequestWithResponse, R: NetworkRequestWithBody, R.ResponseBody == T?

    /// Sends a network request and returns specific headers from the response.
    /// - Parameter requestConfiguration: The request configuration specifying which headers are required.
    /// - Returns: A dictionary containing the required header field names and their values.
    func send(
        request requestConfiguration: some NetworkRequestWithHeaderResponse
    ) async throws(NetworkSendHeaderResponseError) -> [String: String]
}

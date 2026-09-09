//
//  NetworkClientImpl.swift
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

/// Used to convert `NetworkRequest`configurations to `URLRequests` and
/// send them through `URLSession`.
@NetworkActor
public final class NetworkClientImpl: NetworkClient {
    // MARK: - Public Configuration

    public var configuration: NetworkClientConfiguration

    public var environment: NetworkEnvironment {
        get { configuration.environment }
        set { configuration.environment = newValue }
    }

    /// Creates a new `NetworkClientImpl` with the specified environment and default configuration.
    /// - Parameter environment: The network environment supplying the base URL and default headers.
    public convenience init(environment: NetworkEnvironment) {
        self.init(configuration: .init(environment: environment))
    }

    /// Creates a new instance of NetworkClientImpl with the specified configuration.
    ///
    /// The URLSession is created using the `sessionConfiguration` from the provided configuration,
    /// allowing different timeout and retry behaviors for different network managers (e.g., public vs. non-public).
    ///
    /// - Parameter configuration: The network manager configuration to be used.
    public convenience init(configuration: NetworkClientConfiguration) {
        self.init(
            urlSession: URLSession(configuration: configuration.sessionConfiguration),
            configuration: configuration
        )
    }

    /// Creates a new `NetworkClientImpl` with an explicit `URLSession` and full configuration.
    ///
    /// Use this initializer in tests to inject a `URLSession` backed by a custom
    /// `URLProtocol` (e.g. `MockingURLProtocol`).
    /// - Parameters:
    ///   - urlSession: The `URLSession` used to perform requests.
    ///   - configuration: The full configuration to apply.
    public init(urlSession: URLSession, configuration: NetworkClientConfiguration) {
        self.urlSession = urlSession
        self.configuration = configuration
    }

    /// Creates a new `NetworkClientImpl` with an explicit `URLSession` and environment.
    /// - Parameters:
    ///   - urlSession: The `URLSession` used to perform requests.
    ///   - environment: The network environment supplying the base URL and default headers.
    public convenience init(urlSession: URLSession, environment: NetworkEnvironment) {
        self.init(urlSession: urlSession, configuration: .init(environment: environment))
    }

    // MARK: - Internal properties

    let urlSession: URLSession
}

// MARK: - NetworkRequestWithQuery

extension NetworkClientImpl {
    /// Produces query items for a given request.
    /// - Parameter request: The configured NetworkRequest object.
    /// - Returns: A list of query items or `nil`, if no query items are found.
    // swiftlint:disable:next discouraged_optional_collection
    func queryItems(request: any NetworkRequest) throws(RequestBuildingFailure) -> [URLQueryItem]? {
        guard let requestWithQuery = request as? (any NetworkRequestWithQuery) else {
            // We need to return nil here, otherwise URLRequest will
            // append ? with no query items if the array is empty.
            return nil
        }

        do {
            let urlQueryItems = try requestWithQuery.query.dictionaryRepresentation(
                dateEncodingStrategy: requestWithQuery.dateEncodingStrategy.dictionaryDateEncodingStrategy
            )
                .sorted { $0.key < $1.key }
                .reduce(into: [URLQueryItem]()) { $0.append(URLQueryItem(name: $1.key, value: "\($1.value)")) }
            return urlQueryItems.isEmpty ? nil : urlQueryItems
        } catch {
            throw .cannotEncodeQuery(error.localizedDescription)
        }
    }
}

// MARK: NetworkRequestWithBody

extension NetworkClientImpl {
    /// Encodes the requestBody property of the NetworkRequest.
    /// - Parameter request: The request to encode.
    /// - Returns: The data in a format corresponding to the chosen encoder.
    func body(request: some NetworkRequestWithBody) throws(RequestBuildingFailure) -> Data {
        let encoder = request.httpBodyEncoder ?? configuration.httpBodyEncoder
        do {
            return try encoder.encode(request.body)
        } catch {
            throw .cannotEncodeRequestBody(error.localizedDescription)
        }
    }
}

// MARK: - NetworkRequestWithRequestInterceptor

extension NetworkClientImpl {
    /// Intercepts a request by executing the custom request interceptors before network managers general request interceptors.
    /// - Parameters:
    ///   - request: The request configuration.
    ///   - httpRequest: The HTTPRequest to intercept.
    func intercept(request: some Any, httpRequest: inout HTTPRequest) async throws(NetworkTransportError) {
        guard let requestWithCustomInterceptor = request as? NetworkRequestWithRequestInterceptor else {
            try await configuration.requestInterceptor.intercept(request: &httpRequest)
            return
        }

        try await requestWithCustomInterceptor.requestInterceptor
            .chain(before: configuration.requestInterceptor)
            .intercept(request: &httpRequest)
    }
}

// MARK: - NetworkRequestWithResponseInterceptor

extension NetworkClientImpl {
    /// Intercepts a response by executing the global response interceptor first, then the per-request interceptor.
    /// - Parameters:
    ///   - request: The request configuration.
    ///   - httpResponse: The HTTPResponse to intercept.
    /// - Returns: A joint interception result, indicating abort, retry or similar.
    func intercept(
        request: some Any, httpResponse: inout HTTPResponse
    ) async throws(NetworkTransportError) -> NetworkResponseInterceptorResult {
        guard let requestWithCustomInterceptor = request as? NetworkRequestWithResponseInterceptor else {
            return try await configuration.responseInterceptor.intercept(response: &httpResponse)
        }

        return try await requestWithCustomInterceptor.responseInterceptor
            .chain(after: configuration.responseInterceptor)
            .intercept(response: &httpResponse)
    }
}

// MARK: - NetworkRequestWithErrorInterceptor

extension NetworkClientImpl {
    /// Intercepts an error by executing the custom error interceptors after the network manager's general error interceptors.
    /// - Parameters:
    ///   - request: The request configuration.
    ///   - error: The `NetworkTransportError` to handle.
    /// - Returns: A result indicating whether to retry the request or proceed with default handling.
    func intercept(request: some Any, error: NetworkTransportError) async -> NetworkErrorInterceptorResult {
        guard let requestWithCustomInterceptor = request as? NetworkRequestWithErrorInterceptor else {
            return await configuration.errorInterceptor.intercept(error: error)
        }

        return await requestWithCustomInterceptor.errorInterceptor
            .chain(after: configuration.errorInterceptor)
            .intercept(error: error)
    }
}

// MARK: - NetworkRequestWithResponse

extension NetworkClientImpl {
    /// Decodes data received from a web request into a predefined type using a configured decoder.
    /// - Parameters:
    ///   - request: The request configuration, specifying the expected ResponseBody type.
    ///   - httpResponse: The HTTPResponse containing raw data.
    /// - Returns: An instance of `ResponseBody`. Throws if decoding was unsuccessful.
    func decodeResponse<R: NetworkRequestWithResponse>(request: R, httpResponse: HTTPResponse) throws(ResponseDecodingFailure)
    -> R.ResponseBody {
        guard !httpResponse.data.isEmpty else {
            throw ResponseDecodingFailure.responseHasNoData
        }

        let decoder = request.httpBodyDecoder ?? configuration.httpBodyDecoder
        do {
            return try decoder.decode(R.ResponseBody.self, from: httpResponse.data)
        } catch {
            throw .cannotDecodeResponseBody(error.localizedDescription)
        }
    }
}

//
//  NetworkClientImpl+Send.swift
//  Networking
//
//  Created by Niklas Holloh on 12.05.22.
//  Copyright 2026 adesso SE
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//

import Foundation

public extension NetworkClientImpl {
    /// Sends a preconfigured instance of a `NetworkRequest`, which does not expect a response.
    /// May throw in case the request was not successful.
    /// - Parameter requestConfiguration: The `NetworkRequest` to be sent.
    @discardableResult
    func send(request requestConfiguration: some NetworkRequest) async throws(NetworkSendError) -> NetworkResponse<EmptyBody> {
        let httpRequest: HTTPRequest
        do {
            httpRequest = try makeHTTPRequest(requestConfiguration: requestConfiguration)
        } catch {
            throw NetworkSendError(error)
        }

        let httpResponse: HTTPResponse
        do {
            httpResponse = try await getResponse(for: httpRequest, requestConfiguration: requestConfiguration)
        } catch {
            throw NetworkSendError(error)
        }

        return .init(httpResponse: httpResponse)
    }

    /// Sends a preconfigured instance of a `NetworkRequest`, which does not expect a response and
    /// contains a request body. May throw in case the request was not successful.
    /// - Parameter requestConfiguration: The `NetworkRequestWithBody` to be sent.
    @discardableResult
    func send(request requestConfiguration: some NetworkRequestWithBody) async throws(NetworkSendError) -> NetworkResponse<EmptyBody> {
        let httpRequest: HTTPRequest
        do {
            httpRequest = try makeHTTPRequest(requestConfiguration: requestConfiguration)
        } catch {
            throw NetworkSendError(error)
        }

        let httpResponse: HTTPResponse
        do {
            httpResponse = try await getResponse(for: httpRequest, requestConfiguration: requestConfiguration)
        } catch {
            throw NetworkSendError(error)
        }

        return .init(httpResponse: httpResponse)
    }
}

/// With Response
public extension NetworkClientImpl {
    /// Sends a preconfigured instance of a `NetworkRequest`, which expects a response of `ResponseType`.
    /// May throw in case the request was not successful.
    /// - Parameter requestConfiguration: The `NetworkRequestWithResponse` to be sent.
    func send<R>(
        request requestConfiguration: R
    ) async throws(NetworkSendResponseError) -> NetworkResponse<R.ResponseBody> where R: NetworkRequestWithResponse {
        let httpRequest: HTTPRequest
        do {
            httpRequest = try makeHTTPRequest(requestConfiguration: requestConfiguration)
        } catch {
            throw NetworkSendResponseError(error)
        }

        let httpResponse: HTTPResponse
        do {
            httpResponse = try await getResponse(for: httpRequest, requestConfiguration: requestConfiguration)
        } catch {
            throw NetworkSendResponseError(error)
        }

        let responseBody: R.ResponseBody
        do {
            responseBody = try decodeResponse(request: requestConfiguration, httpResponse: httpResponse)
        } catch {
            throw NetworkSendResponseError(error)
        }

        return .init(httpResponse: httpResponse, body: responseBody)
    }

    /// Sends a preconfigured instance of a `NetworkRequest`, which expects a response of `ResponseType`and
    /// contains a request body. May throw in case the request was not successful.
    /// - Parameter requestConfiguration: The `NetworkRequestWithResponse & NetworkRequestWithBody` to be sent.
    func send<R>(
        request requestConfiguration: R
    ) async throws(NetworkSendResponseError) -> NetworkResponse<R.ResponseBody>
    where R: NetworkRequestWithResponse, R: NetworkRequestWithBody {
        let httpRequest: HTTPRequest
        do {
            httpRequest = try makeHTTPRequest(requestConfiguration: requestConfiguration)
        } catch {
            throw NetworkSendResponseError(error)
        }

        let httpResponse: HTTPResponse
        do {
            httpResponse = try await getResponse(for: httpRequest, requestConfiguration: requestConfiguration)
        } catch {
            throw NetworkSendResponseError(error)
        }

        let responseBody: R.ResponseBody
        do {
            responseBody = try decodeResponse(request: requestConfiguration, httpResponse: httpResponse)
        } catch {
            throw NetworkSendResponseError(error)
        }

        return .init(httpResponse: httpResponse, body: responseBody)
    }
}

/// With Optional Response
public extension NetworkClientImpl {
    /// Sends a preconfigured instance of a `NetworkRequest`, which expects a response of `ResponseType`
    /// that may be empty (hence return value of `ResponseType?`).
    /// May throw in case the request was not successful.
    /// - Parameter requestConfiguration: The `NetworkRequestWithResponse` to be sent.
    func send<R, T>(
        request requestConfiguration: R
    ) async throws(NetworkSendOptionalResponseError) -> NetworkResponse<R.ResponseBody>
    where R: NetworkRequestWithResponse, R.ResponseBody == T? {
        let httpRequest: HTTPRequest
        do {
            httpRequest = try makeHTTPRequest(requestConfiguration: requestConfiguration)
        } catch {
            throw NetworkSendOptionalResponseError(error)
        }

        let httpResponse: HTTPResponse
        do {
            httpResponse = try await getResponse(for: httpRequest, requestConfiguration: requestConfiguration)
        } catch {
            throw NetworkSendOptionalResponseError(error)
        }

        guard !httpResponse.data.isEmpty else {
            return .init(httpResponse: httpResponse, body: nil)
        }

        do {
            let responseBody = try decodeResponse(request: requestConfiguration, httpResponse: httpResponse)
            return .init(httpResponse: httpResponse, body: responseBody)
        } catch {
            switch error {
            case .responseHasNoData:
                return .init(httpResponse: httpResponse, body: nil)
            case let .cannotDecodeResponseBody(message):
                throw NetworkSendOptionalResponseError.cannotDecodeResponseBody(message)
            }
        }
    }

    /// Sends a preconfigured instance of a `NetworkRequest`, which expects a response of `ResponseType`
    /// that may be empty (hence return value of `ResponseType?`) and contains a request body.
    /// May throw in case the request was not successful.
    /// - Parameter requestConfiguration: The `NetworkRequestWithResponse & NetworkRequestWithBody` to be sent.
    func send<R, T>(
        request requestConfiguration: R
    ) async throws(NetworkSendOptionalResponseError) -> NetworkResponse<R.ResponseBody>
    where R: NetworkRequestWithResponse, R: NetworkRequestWithBody, R.ResponseBody == T? {
        let httpRequest: HTTPRequest
        do {
            httpRequest = try makeHTTPRequest(requestConfiguration: requestConfiguration)
        } catch {
            throw NetworkSendOptionalResponseError(error)
        }

        let httpResponse: HTTPResponse
        do {
            httpResponse = try await getResponse(for: httpRequest, requestConfiguration: requestConfiguration)
        } catch {
            throw NetworkSendOptionalResponseError(error)
        }

        guard !httpResponse.data.isEmpty else {
            return .init(httpResponse: httpResponse, body: nil)
        }

        do {
            let responseBody = try decodeResponse(request: requestConfiguration, httpResponse: httpResponse)
            return .init(httpResponse: httpResponse, body: responseBody)
        } catch {
            switch error {
            case .responseHasNoData:
                return .init(httpResponse: httpResponse, body: nil)
            case let .cannotDecodeResponseBody(message):
                throw NetworkSendOptionalResponseError.cannotDecodeResponseBody(message)
            }
        }
    }
}

/// With Header Response
public extension NetworkClientImpl {
    /// Sends a network request that expects specific headers to be returned in the HTTP response.
    /// - Parameter requestConfiguration: The network request configuration specifying required headers.
    /// - Returns: A dictionary containing the required header field names and their values.
    /// - Throws: `NetworkSendHeaderResponseError.headerFieldsMissing` if any required headers are missing from the response.
    func send(
        request requestConfiguration: some NetworkRequestWithHeaderResponse
    ) async throws(NetworkSendHeaderResponseError) -> [String: String] {
        let httpRequest: HTTPRequest
        do {
            httpRequest = try makeHTTPRequest(requestConfiguration: requestConfiguration)
        } catch {
            throw NetworkSendHeaderResponseError(error)
        }

        let response: HTTPResponse
        do {
            response = try await getResponse(for: httpRequest, requestConfiguration: requestConfiguration)
        } catch {
            throw NetworkSendHeaderResponseError(error)
        }

        let urlResponse = response.urlResponse
        var headersToReturn = [String: String]()
        for requiredHeader in requestConfiguration.requiredHeaders {
            guard let header = urlResponse.value(forHTTPHeaderField: requiredHeader) else {
                throw .headerFieldsMissing
            }

            headersToReturn[requiredHeader] = header
        }
        return headersToReturn
    }
}

/// These do not belong to Networking's public interface, however can be used for testing.
extension NetworkClientImpl {
    /// Creates a `HTTPRequest` from the given request configuration.
    ///
    /// The full URL is always composed by combining `configuration.environment.base`
    /// with `requestConfiguration.path` via the type-safe `+` operator.
    ///
    /// - Parameter requestConfiguration: The request configuration.
    /// - Returns: A fully configured `HTTPRequest`.
    func makeHTTPRequest(requestConfiguration: some NetworkRequest) throws(RequestBuildingFailure) -> HTTPRequest {
        // Always compose: URLBase + URLPath → ResolvedURL
        let resolvedURL = configuration.environment.base + requestConfiguration.path

        let queryItems = try queryItems(request: requestConfiguration)
        let finalURL: URL = resolvedURL.appending(queryItems: queryItems ?? []).url

        var urlRequest = URLRequest(url: finalURL)

        var additionalHeaders: [HTTPHeader: String] = [:]
        if let bodyRequest = requestConfiguration as? any NetworkRequestWithBody {
            additionalHeaders[.contentType] = bodyRequest.contentType.contentTypeString
            urlRequest.httpBody = try body(request: bodyRequest)
        }

        // Merge: environment defaults < content-type < request-specific (request wins)
        urlRequest.allHTTPHeaderFields = mergeHeaders(
            configuration.environment.defaultHeaders,
            additionalHeaders,
            requestConfiguration.headers
        )

        urlRequest.httpMethod = requestConfiguration.method.methodString

        if let networkRequestWithTimeout = requestConfiguration as? NetworkRequestWithTimeout {
            urlRequest.timeoutInterval = networkRequestWithTimeout.timeout
        }

        return HTTPRequest(urlRequest: urlRequest, configuration: requestConfiguration, environment: configuration.environment)
    }

    /// Get a response for a manually configured HTTPRequest object.
    /// - Parameters:
    ///   - httpRequest: The HTTPRequest to send.
    ///   - requestConfiguration: The request configuration.
    /// - Returns: A HTTPResponse as provided by server or stubs.
    func getResponse(
        for httpRequest: HTTPRequest,
        requestConfiguration: some NetworkRequest
    ) async throws(NetworkTransportError) -> HTTPResponse {
        var httpRequest = httpRequest
        try await intercept(request: requestConfiguration, httpRequest: &httpRequest)

        let rawResponse: (Data, URLResponse)
        do {
            rawResponse = try await urlSession.data(for: httpRequest.urlRequest)
        } catch {
            // Try to map the URLSession error to a NetworkTransportError so registered error
            // interceptors get a chance to handle it (e.g. logging, retry, lockout display).
            // Errors that have no NetworkTransportError mapping are rethrown directly to the caller.
            guard let urlError = error as? URLError else {
                throw .unknownError(error.localizedDescription)
            }

            let networkError = urlError.networkError
            let result = await intercept(request: requestConfiguration, error: networkError)
            if case .retryRequest = result {
                return try await getResponse(for: httpRequest, requestConfiguration: requestConfiguration)
            }
            throw networkError
        }

        guard let httpUrlResponse = rawResponse.1 as? HTTPURLResponse else {
            throw NetworkTransportError.responseIsNoHTTPURLResponse
        }

        var httpResponse = HTTPResponse(request: httpRequest, urlResponse: httpUrlResponse, data: rawResponse.0)

        // Validate status code against the per-request allowedStatusCodes (default: 200..<300).
        let statusCode = httpUrlResponse.statusCode
        guard requestConfiguration.allowedStatusCodes.contains(statusCode) else {
            let networkError = NetworkTransportError.errorStatusCode(code: statusCode, response: httpResponse)
            let result = await intercept(request: requestConfiguration, error: networkError)
            if case .retryRequest = result {
                return try await getResponse(for: httpRequest, requestConfiguration: requestConfiguration)
            }
            throw networkError
        }

        do {
            let interceptResult = try await intercept(request: requestConfiguration, httpResponse: &httpResponse)

            if case .retryRequest = interceptResult {
                return try await getResponse(for: httpRequest, requestConfiguration: requestConfiguration)
            }
        } catch {
            // When a response interceptor throws a NetworkTransportError, give the error
            // interceptors a chance to handle it (e.g. logging, lock-out display).
            let result = await intercept(request: requestConfiguration, error: error)
            if case .retryRequest = result {
                return try await getResponse(for: httpRequest, requestConfiguration: requestConfiguration)
            }
            throw error
        }

        return httpResponse
    }
}

/// Helper to merge multiple [HTTPHeader: String] dictionaries into a [String: String] dictionary.
/// Later dictionaries in the argument list override earlier ones for duplicate keys.
private func mergeHeaders(_ dicts: [HTTPHeader: String]...) -> [String: String] {
    var result: [String: String] = [:]
    for dict in dicts {
        for (key, value) in dict {
            result[key.headerKey] = value
        }
    }
    return result
}

private extension URLError {
    /// Maps a `URLSession` error to a `NetworkTransportError`, if a mapping exists.
    ///
    /// Returns `nil` for errors that have no defined mapping — those are rethrown directly
    /// to the caller without passing through error interceptors.
    ///
    /// Current mappings:
    /// - TLS/ATS `URLError` codes → `.secureConnectionNotPossible`:
    ///   - `serverCertificateUntrusted` — `NSPinnedDomains` identity pinning violation
    ///   - `serverCertificateHasBadDate` — expired server certificate
    ///   - `serverCertificateHasUnknownRoot` — untrusted root CA
    ///   - `serverCertificateNotYetValid` — certificate not yet valid
    ///   - `secureConnectionFailed` — general TLS handshake failure
    ///   - `clientCertificateRejected` — client certificate rejected by server
    ///   - `clientCertificateRequired` — server requires client certificate
    var networkError: NetworkTransportError {
        switch code {
        case .serverCertificateUntrusted,
             .serverCertificateHasBadDate,
             .serverCertificateHasUnknownRoot,
             .serverCertificateNotYetValid,
             .secureConnectionFailed,
             .clientCertificateRejected,
             .clientCertificateRequired:
            return .secureConnectionNotPossible
        default:
            return .unknownURLError(self)
        }
    }
}

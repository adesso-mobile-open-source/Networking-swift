//
//  NetworkSendResponseError.swift
//  Networking
//
//  Created by Niklas Holloh on 09.09.26.
//  Copyright 2026 adesso SE
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//

/// Errors that can be thrown when sending a request that decodes a non-optional response body.
///
/// Thrown by:
/// - `NetworkClient.send<R: NetworkRequestWithResponse>(request: R)`
/// - `NetworkClient.send<R: NetworkRequestWithResponse & NetworkRequestWithBody>(request: R)`
public enum NetworkSendResponseError: Error, Equatable {
    /// A failure originating from network transport, connectivity, TLS, status-code
    /// validation, or the request/response interceptor pipeline.
    case transport(NetworkTransportError)

    /// The request query submitted cannot be encoded.
    case cannotEncodeQuery(String)

    /// The request body submitted cannot be encoded.
    case cannotEncodeRequestBody(String)

    /// The response has no data, but was expected to have data.
    ///
    /// > Tip: If empty responses are a valid outcome for this endpoint, declare
    /// > `ResponseBody` as an optional type and use one of the `send` overloads
    /// > that returns `NetworkSendOptionalResponseError` instead — it treats an
    /// > empty body as `nil` rather than an error.
    case responseHasNoData

    /// The response body received does not match the specified type. DecoderError.
    case cannotDecodeResponseBody(String)
}

extension NetworkSendResponseError {
    init(_ error: NetworkTransportError) {
        self = .transport(error)
    }

    init(_ error: RequestBuildingFailure) {
        switch error {
        case let .cannotEncodeQuery(message):
            self = .cannotEncodeQuery(message)
        case let .cannotEncodeRequestBody(message):
            self = .cannotEncodeRequestBody(message)
        }
    }

    init(_ error: ResponseDecodingFailure) {
        switch error {
        case .responseHasNoData:
            self = .responseHasNoData
        case let .cannotDecodeResponseBody(message):
            self = .cannotDecodeResponseBody(message)
        }
    }
}

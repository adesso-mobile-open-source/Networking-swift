//
//  NetworkSendOptionalResponseError.swift
//  Networking
//
//  Created by Niklas Holloh on 09.09.26.
//  Copyright 2026 adesso SE
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//

/// Errors that can be thrown when sending a request that decodes an optional response body.
///
/// An empty response body is treated as a valid `nil` result rather than an error, so — unlike
/// `NetworkSendResponseError` — there is no `responseHasNoData` case here.
///
/// Thrown by:
/// - `NetworkClient.send<R, T>(request: R)` where `R: NetworkRequestWithResponse, R.ResponseBody == T?`
/// - `NetworkClient.send<R, T>(request: R)` where `R: NetworkRequestWithResponse & NetworkRequestWithBody, R.ResponseBody == T?`
public enum NetworkSendOptionalResponseError: Error, Equatable {
    /// A failure originating from network transport, connectivity, TLS, status-code
    /// validation, or the request/response interceptor pipeline.
    case transport(NetworkTransportError)

    /// The request query submitted cannot be encoded.
    case cannotEncodeQuery(String)

    /// The request body submitted cannot be encoded.
    case cannotEncodeRequestBody(String)

    /// The response body received does not match the specified type. DecoderError.
    case cannotDecodeResponseBody(String)
}

extension NetworkSendOptionalResponseError {
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
}

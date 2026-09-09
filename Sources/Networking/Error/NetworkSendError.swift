//
//  NetworkSendError.swift
//  Networking
//
//  Created by Niklas Holloh on 09.09.26.
//  Copyright 2026 adesso SE
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//

/// Errors that can be thrown when sending a request that does not decode a response body.
///
/// Thrown by:
/// - `NetworkClient.send(request: some NetworkRequest)`
/// - `NetworkClient.send(request: some NetworkRequestWithBody)`
public enum NetworkSendError: Error, Equatable {
    /// A failure originating from network transport, connectivity, TLS, status-code
    /// validation, or the request/response interceptor pipeline.
    case transport(NetworkTransportError)

    /// The request query submitted cannot be encoded.
    case cannotEncodeQuery(String)

    /// The request body submitted cannot be encoded.
    case cannotEncodeRequestBody(String)
}

extension NetworkSendError {
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

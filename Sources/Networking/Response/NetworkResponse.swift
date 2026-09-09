//
//  NetworkResponse.swift
//  Networking
//
//  Created by Niklas Holloh on 25.06.26.
//  Copyright 2026 adesso SE
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//

import Foundation

/// A wrapper that bundles the HTTP response together with the decoded data object
/// that is expected by a `NetworkRequestWithResponse`. `EmptyBody` in case
/// the request configuration did not indicate an expected response body type.
///
/// ## Accessing raw response data
///
/// For advanced scenarios where you need the raw response data alongside (or instead of)
/// the decoded body, use the `rawBody`, `statusCode`, and `headerFields` properties.
///
/// See [Advanced Response Handling](Documentation/Advanced_Response_Handling.md) for
/// patterns like manual decoding based on status codes or response headers.
@dynamicMemberLookup
public struct NetworkResponse<T>: Sendable where T: Sendable {
    /// The decoded response body returned by the request.
    ///
    /// This is automatically decoded from `rawBody` using the decoder configured
    /// for the request (or the global decoder from `NetworkClientConfiguration`).
    public let body: T
    
    /// The `HTTPResponse` that wraps around the raw body data, the
    /// request sent and the SDK's `URLResponse`.
    public let httpResponse: HTTPResponse
    
    /// The raw data in the response body.
    ///
    /// Use this for:
    /// - Manual decoding when different status codes return different types
    /// - Logging or debugging raw responses
    /// - Validating response signatures
    /// - Accessing data when `NetworkRequest` (without response) is used
    ///
    /// See [Advanced Response Handling](Documentation/Advanced_Response_Handling.md) for examples.
    public var rawBody: Data {
        httpResponse.data
    }
    
    /// The header fields returned in the server's response.
    public var headerFields: [AnyHashable: Any] {
        httpResponse.urlResponse.allHeaderFields
    }
    
    /// The status code that the server sent.
    public var statusCode: Int {
        httpResponse.urlResponse.statusCode
    }
    
    /// Dynamically look up members of the decoded response body type as if they were members of
    /// this struct.
    public subscript<V>(dynamicMember dynamicMember: KeyPath<T, V>) -> V {
        body[keyPath: dynamicMember]
    }
    
    init(httpResponse: HTTPResponse, body: T = EmptyBody()) {
        self.httpResponse = httpResponse
        self.body = body
    }
}

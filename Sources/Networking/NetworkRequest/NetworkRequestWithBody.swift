//
//  NetworkRequestWithBody.swift
//  Networking
//
//  Created by Niklas Holloh on 24.04.22.
//  Copyright 2026 adesso SE
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//

import Foundation

/// Extends the basic `NetworkRequest` so that a body can be sent along
/// with the request.
public protocol NetworkRequestWithBody: NetworkRequest {
    /// The type that defines the request body. Needs to conform to `Encodable`.
    associatedtype RequestBody: Encodable

    /// The instance of `RequestBody` to be sent with the request.
    var body: RequestBody { get }

    /// You can use this property to override the encoder used for the body of this request, if required.
    /// If `nil`, the `NetworkClient` encoders will be used. Default: `nil`.
    var httpBodyEncoder: DataEncoding? { get }

    /// Define the content type of your request. Default: `application/json`.
    var contentType: ContentType { get }
}

public extension NetworkRequestWithBody {
    /// You can use this property to override the encoder used for the body of this request, if required.
    /// If `nil`, the `NetworkClient` encoders will be used. Default: `nil`.
    var httpBodyEncoder: DataEncoding? { nil }

    /// Define the content type of your request. Default: `application/json`.
    var contentType: ContentType { .applicationJson }
}

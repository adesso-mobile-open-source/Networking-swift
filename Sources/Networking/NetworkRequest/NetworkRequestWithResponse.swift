//
//  NetworkRequestWithResponse.swift
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

/// Extends a basic `NetworkRequest` so that it expects a response.
public protocol NetworkRequestWithResponse: NetworkRequest {
    /// The type of response it is expecting. Needs to conform to `Decodable` and `Sendable`.
    associatedtype ResponseBody: Decodable, Sendable

    /// You can use this property to override the decoder used for the body of this response, if required.
    /// If `nil`, the `NetworkClient` decoders will be used. Default: `nil`.
    var httpBodyDecoder: DataDecoding? { get }
}

public extension NetworkRequestWithResponse {
    /// You can use this property to override the decoder used for the body of this response, if required.
    /// If `nil`, the `NetworkClient` decoders will be used. Default: `nil`.
    var httpBodyDecoder: DataDecoding? { nil }
}

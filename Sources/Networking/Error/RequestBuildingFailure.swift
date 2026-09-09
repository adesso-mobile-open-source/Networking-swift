//
//  RequestBuildingFailure.swift
//  Networking
//
//  Created by Niklas Holloh on 09.09.26.
//  Copyright 2026 adesso SE
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//

/// Internal error used while composing an `HTTPRequest` from a `NetworkRequest` — encoding
/// query items or a request body.
///
/// This capability is cross-cutting: any `NetworkRequest` can additionally conform to
/// `NetworkRequestWithQuery` and/or `NetworkRequestWithBody`, independent of which `send`
/// overload is used to dispatch it, so every public `send` overload can encounter either
/// case here and converts it into its own error type via `init(_:)`.
enum RequestBuildingFailure: Error, Equatable {
    /// The request query submitted cannot be encoded.
    case cannotEncodeQuery(String)

    /// The request body submitted cannot be encoded.
    case cannotEncodeRequestBody(String)
}

//
//  HTTPResponse.swift
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

/// A wrapper object, grouping request and response properties.
public struct HTTPResponse: Sendable, Equatable {
    /// The `HTTPRequest` that was sent.
    public let request: HTTPRequest

    /// The `HTTPURLResponse` that was received.
    public var urlResponse: HTTPURLResponse

    /// The data of the body. Check `isEmpty` to validate that the body was not empty.
    public var data: Data
}

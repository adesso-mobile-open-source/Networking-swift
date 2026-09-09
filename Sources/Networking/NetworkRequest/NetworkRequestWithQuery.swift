//
//  NetworkRequestWithQuery.swift
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

/// Extends a basic `NetworkRequest` to include query parameters.
public protocol NetworkRequestWithQuery: NetworkRequest {
    /// The type that describes the keys and values of your query. Needs to conform to `Encodable`.
    associatedtype Query: Encodable
    /// The query object to be URL-encoded into `key=value` pairs and appended to the URL.
    var query: Query { get }

    /// Defines how `Date` values inside `query` should be encoded.
    var dateEncodingStrategy: QueryDateEncodingStrategy { get }
}

public extension NetworkRequestWithQuery {
    /// Default query date encoding strategy used when a request does not override it.
    ///
    /// This keeps URL query date transport stable by encoding `Date` values as `yyyy-MM-dd`.
    var dateEncodingStrategy: QueryDateEncodingStrategy {
        .dateOnly
    }
}

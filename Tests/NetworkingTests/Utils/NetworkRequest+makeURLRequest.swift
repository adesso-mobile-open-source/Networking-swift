//
//  NetworkRequest+makeURLRequest.swift
//  Networking
//
//  Created by Niklas Holloh on 13.08.25.
//  Copyright 2026 adesso SE
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//

@testable import Networking

extension NetworkRequest {
    /// Creates a `URLRequest` that mirrors what `NetworkClientImpl` produces for this request.
    ///
    /// Useful for registering Mocker stubs that match the exact URL the manager will call.
    ///
    /// - Parameters:
    ///   - environment: The `NetworkEnvironment` whose `base` is combined with `path`.
    ///   - method: The HTTP method. Defaults to `GET`.
    ///   - query: Query items to append. Empty by default.
    ///   - headers: Header fields, or `nil` to omit. Avoid passing an empty dictionary.
    /// - Returns: A `URLRequest` equivalent to the one `NetworkClientImpl` would build.
    func makeURLRequest(
        environment: NetworkEnvironment,
        method: HTTPMethod = .get,
        query: [URLQueryItem] = [],
        headers: [String: String]? = nil // swiftlint:disable:this discouraged_optional_collection
    ) -> URLRequest {
        let resolved = environment.base + path
        let url = query.isEmpty ? resolved.url : resolved.appending(queryItems: query).url
        var request = URLRequest(url: url)
        request.httpMethod = method.methodString
        request.allHTTPHeaderFields = headers
        return request
    }
}

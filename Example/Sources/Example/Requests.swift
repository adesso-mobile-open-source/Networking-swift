//
//  Requests.swift
//  Networking
//
//  Created by Niklas Holloh on 09.09.26.
//  Copyright 2026 adesso SE
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//

// Every API endpoint is declared as a small value type that conforms to
// `NetworkRequest` plus the relevant trait protocols.
//
// Patterns demonstrated:
//   1. Static path, response body          — GetUserRequest
//   2. Dynamic path via @URLPathTemplate   — GetPostRequest
//   3. Query parameters + response body    — ListPostsRequest
//   4. POST with request body + response   — CreatePostRequest
//   5. Custom allowedStatusCodes           — GetTodoRequest (accepts 200 only)

import Networking

// MARK: - 1. Static path, response body

/// Fetches a single user by a hardcoded ID.
///
/// Demonstrates the most minimal `NetworkRequest` with a response body:
/// just a static `#URLPath` and a `ResponseBody` type alias.
struct GetUserRequest: NetworkRequestWithResponse {
    typealias ResponseBody = User

    let method: HTTPMethod = .get
    var path: URLPath { #URLPath("users/1") }
}

// MARK: - 2. Dynamic path via @URLPathTemplate

/// Fetches a single post whose ID is supplied at call time.
///
/// `@URLPathTemplate` extracts the `{id}` placeholder and generates
/// a memberwise `init(id:)` automatically — no manual `path` property needed.
@URLPathTemplate("posts/{id}")
struct GetPostRequest: NetworkRequestWithResponse {
    typealias ResponseBody = Post
    let method: HTTPMethod = .get
}

// MARK: - 3. Query parameters + response body

/// Lists all posts authored by a given user.
///
/// `NetworkRequestWithQuery` encodes the `Query` struct as URL query parameters,
/// so the final URL becomes `/posts?userId=<n>`.
struct ListPostsRequest: NetworkRequestWithQuery, NetworkRequestWithResponse {
    struct Query: Encodable, Sendable {
        let userId: Int
    }

    typealias ResponseBody = [Post]

    let method: HTTPMethod = .get
    var path: URLPath { #URLPath("posts") }
    let query: Query
}

// MARK: - 4. POST with request body and response body

/// Creates a new post and returns the server-assigned resource.
///
/// `NetworkRequestWithBody` attaches the encoded `NewPost` as the HTTP body.
/// The server echoes it back with an `id` field added — decoded as `CreatedPost`.
struct CreatePostRequest: NetworkRequestWithBody, NetworkRequestWithResponse {
    typealias RequestBody = NewPost
    typealias ResponseBody = CreatedPost

    let method: HTTPMethod = .post
    var path: URLPath { #URLPath("posts") }
    let body: NewPost

    /// JSONPlaceholder returns 201 Created for successful POST requests.
    /// Override the default 200..<300 range to only accept exactly 201,
    /// making the intent explicit and catching unexpected 200 responses.
    var allowedStatusCodes: Range<Int> { 201 ..< 202 }
}

// MARK: - 5. GET todo — narrowed allowedStatusCodes

/// Fetches a single todo item and accepts only an exact 200 OK response.
///
/// By narrowing `allowedStatusCodes` to `200..<201` (a range containing only
/// 200), any 2xx response other than 200 will be treated as an error, giving
/// you precise control over what your endpoint considers "success".
@URLPathTemplate("todos/{id}")
struct GetTodoRequest: NetworkRequestWithResponse {
    typealias ResponseBody = Todo
    let method: HTTPMethod = .get

    var allowedStatusCodes: Range<Int> { 200 ..< 201 }
}

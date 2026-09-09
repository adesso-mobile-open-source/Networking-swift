//
//  Models.swift
//  Networking
//
//  Created by Niklas Holloh on 09.09.26.
//  Copyright 2026 adesso SE
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//

// Codable response types that mirror the shapes returned by
// https://jsonplaceholder.typicode.com — a free, public, read-only REST API
// used throughout this example.

import Foundation

// MARK: - User

/// A user resource from the JSONPlaceholder API.
struct User: Codable, Sendable {
    let id: Int
    let name: String
    let username: String
    let email: String
    let address: Address
    let phone: String
    let website: String
    let company: Company

    struct Address: Codable, Sendable {
        let street: String
        let suite: String
        let city: String
        let zipcode: String
    }

    struct Company: Codable, Sendable {
        let name: String
        let catchPhrase: String
    }
}

// MARK: - Post

/// A blog-post resource from the JSONPlaceholder API.
struct Post: Codable, Sendable {
    let userId: Int
    let id: Int
    let title: String
    let body: String
}

// MARK: - Todo

/// A todo item resource from the JSONPlaceholder API.
struct Todo: Codable, Sendable {
    let userId: Int
    let id: Int
    let title: String
    let completed: Bool
}

// MARK: - NewPost

/// Request body sent when creating a new post via POST /posts.
struct NewPost: Encodable, Sendable {
    let title: String
    let body: String
    let userId: Int
}

/// Response body returned when a new post is successfully created.
struct CreatedPost: Codable, Sendable {
    let id: Int
    let title: String
    let body: String
    let userId: Int
}

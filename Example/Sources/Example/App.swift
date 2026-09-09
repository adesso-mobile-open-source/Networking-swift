//
//  App.swift
//  Networking
//
//  Created by Niklas Holloh on 09.09.26.
//  Copyright 2026 adesso SE
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//

// End-to-end example for the Networking library.
//
// Runs against https://jsonplaceholder.typicode.com — a free, public,
// read-only REST API that requires no authentication.
//
// RUNNING
//   cd Example
//   swift run
//
// WHAT THIS SHOWS
//   Step 1 — How to create a NetworkEnvironment and a NetworkClientImpl.
//   Step 2 — GET a single resource with a static path.
//   Step 3 — GET a resource with a dynamic path (@URLPathTemplate).
//   Step 4 — GET a list of resources filtered by a query parameter.
//   Step 5 — POST a new resource with a request body.
//   Step 6 — GET with a narrowed allowedStatusCodes range.
//   Step 7 — How errors surface (404 treated as an error).

import Networking

@main
struct ExampleApp {
    // ============================================================
    // MARK: Step 1 — Create the environment and NetworkClient

    // ============================================================
    //
    // NetworkEnvironment holds the base URL for all requests sent through
    // a given NetworkClientImpl. Use #URLBase to get compile-time validation
    // of the scheme, host, and path — typos become build errors, not crashes.
    //
    // NetworkClientImpl is an actor, so all calls are automatically
    // data-race safe in a concurrent context.
    //
    // For dependency injection in a real app you would store a reference to
    // the `NetworkClient` protocol rather than the concrete type, and
    // inject the manager where it is needed rather than using a global.

    static let environment = NetworkEnvironment(
        base: #URLBase("https://jsonplaceholder.typicode.com")
    )

    @NetworkActor
    static let networkClient = NetworkClientImpl(environment: environment)

    // ============================================================
    // MARK: Entry point

    // ============================================================

    static func main() async {
        print("=== Networking Library — Live Example ===\n")

        await step2_getUser()
        await step3_getPostByDynamicId()
        await step4_listPostsByQuery()
        await step5_createPost()
        await step6_getTodoNarrowStatusCode()
        await step7_demonstrateError()

        print("\n=== Done ===")
    }

    // ============================================================
    // MARK: Step 2 — Static path, response body

    // ============================================================
    //
    // GetUserRequest uses a fixed #URLPath("users/1").
    // The return type is inferred automatically from `ResponseBody`.

    static func step2_getUser() async {
        print("── Step 2: GET user with static path ──────────────────")
        do {
            let user: User = try await networkClient.send(request: GetUserRequest()).body
            print("  User #\(user.id): \(user.name) (@\(user.username))")
            print("  Email  : \(user.email)")
            print("  Company: \(user.company.name)")
        } catch {
            print("  ERROR: \(error)")
        }
        print()
    }

    // ============================================================
    // MARK: Step 3 — Dynamic path via @URLPathTemplate

    // ============================================================
    //
    // GetPostRequest is annotated with @URLPathTemplate("posts/{id}").
    // The macro generates `let id: String` and `var path: URLPath` inside
    // the struct, and Swift synthesises the memberwise `init(id:)`.
    // Any value can be passed at the call site — the path is assembled
    // at runtime from the validated template.

    static func step3_getPostByDynamicId() async {
        print("── Step 3: GET post with dynamic path template ─────────")
        do {
            let post: Post = try await networkClient.send(request: GetPostRequest(id: "7")).body
            print("  Post #\(post.id) by user \(post.userId)")
            print("  Title: \(post.title)")
        } catch {
            print("  ERROR: \(error)")
        }
        print()
    }

    // ============================================================
    // MARK: Step 4 — Query parameters + response body

    // ============================================================
    //
    // ListPostsRequest conforms to NetworkRequestWithQuery.
    // The Query struct is encoded as URL query parameters automatically
    // (e.g. ?userId=1), so no manual URL building is required.

    static func step4_listPostsByQuery() async {
        print("── Step 4: GET posts filtered by query parameter ────────")
        do {
            let posts: [Post] = try await networkClient.send(
                request: ListPostsRequest(query: .init(userId: 1))
            ).body
            print("  Found \(posts.count) posts for userId=1")
            for post in posts.prefix(3) {
                print("  • [\(post.id)] \(post.title.prefix(60))…")
            }
        } catch {
            print("  ERROR: \(error)")
        }
        print()
    }

    // ============================================================
    // MARK: Step 5 — POST with request body and response body

    // ============================================================
    //
    // CreatePostRequest conforms to both NetworkRequestWithBody and
    // NetworkRequestWithResponse. The library:
    //   • JSON-encodes `body` and attaches it as the HTTP body,
    //   • sets Content-Type: application/json automatically,
    //   • decodes the response JSON into CreatedPost.
    //
    // The request overrides allowedStatusCodes to 201..<202, so only
    // HTTP 201 Created is treated as success — anything else throws.

    static func step5_createPost() async {
        print("── Step 5: POST new post (body + response) ─────────────")
        do {
            let newPost = NewPost(
                title: "Networking library example",
                body: "Showcasing compile-time safe URL construction.",
                userId: 1
            )
            let created: CreatedPost = try await networkClient.send(
                request: CreatePostRequest(body: newPost)
            ).body
            // JSONPlaceholder echoes the body back and assigns id: 101.
            print("  Created post with server-assigned id: \(created.id)")
            print("  Title: \(created.title)")
        } catch {
            print("  ERROR: \(error)")
        }
        print()
    }

    // ============================================================
    // MARK: Step 6 — Narrowed allowedStatusCodes

    // ============================================================
    //
    // GetTodoRequest sets allowedStatusCodes to 200..<201, so only an
    // exact HTTP 200 is accepted. Any other 2xx (e.g. 204) would throw
    // a NetworkSendResponseError.transport(.errorStatusCode). The endpoint
    // returns 200 here, so the call succeeds normally.

    static func step6_getTodoNarrowStatusCode() async {
        print("── Step 6: GET todo — narrowed allowedStatusCodes ──────")
        do {
            let todo: Todo = try await networkClient.send(
                request: GetTodoRequest(id: "3")
            ).body
            let status = todo.completed ? "✓ done" : "○ pending"
            print("  Todo #\(todo.id) [\(status)]: \(todo.title)")
        } catch {
            print("  ERROR: \(error)")
        }
        print()
    }

    // ============================================================
    // MARK: Step 7 — Demonstrate error handling

    // ============================================================
    //
    // Requesting a non-existent resource (id 99999) causes the server to
    // return 404 Not Found. Because 404 is outside the default
    // allowedStatusCodes (200..<300), the library throws
    // NetworkSendResponseError.transport(.errorStatusCode(code: 404, ...)).
    //
    // All errors from send(request:) are Swift-typed and scoped to exactly
    // what that overload can throw — GetPostRequest conforms to
    // NetworkRequestWithResponse, so this call throws NetworkSendResponseError,
    // not a generic catch-all. Catch them with a standard do/catch block.

    static func step7_demonstrateError() async {
        print("── Step 7: Error handling — 404 Not Found ──────────────")
        do {
            let _: NetworkResponse<Post> = try await networkClient.send(
                request: GetPostRequest(id: "99999")
            )
            print("  (unexpected success)")
        } catch let NetworkSendResponseError.transport(.errorStatusCode(code, _)) {
            print("  Caught expected error: HTTP \(code)")
            print(
                "  → The library throws a typed, overload-specific error (NetworkSendResponseError)" +
                    " — no stringly-typed error handling needed."
            )
        } catch {
            print("  Caught error: \(error)")
        }
        print()
    }
}

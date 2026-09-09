//
//  URLPathTemplateMacroTests.swift
//  Networking
//
//  Created by Niklas Holloh on 14.06.26.
//  Copyright 2026 adesso SE
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//

#if os(macOS)
@testable import NetworkingMacros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

final class URLPathTemplateMacroTests: XCTestCase {
    private let macros: [String: any Macro.Type] = ["URLPathTemplate": URLPathTemplateMacro.self]

    // MARK: - Valid expansion

    func test_noParameters_generatesPathOnly() {
        assertMacroExpansion(
            """
            @URLPathTemplate("users/profile")
            struct GetProfileRequest {}
            """,
            expandedSource: """
            struct GetProfileRequest {

                var path: URLPath {
                    URLPath(unsafeValue: "users/profile")
                }
            }
            """,
            macros: macros
        )
    }

    func test_singleParameter_generatesPropertyAndPath() {
        assertMacroExpansion(
            """
            @URLPathTemplate("users/{id}")
            struct GetUserRequest {}
            """,
            expandedSource: """
            struct GetUserRequest {

                let id: PathParameterStringConvertible

                var path: URLPath {
                    URLPath(unsafeValue: "users/\\(id.stringRepresentation)")
                }
            }
            """,
            macros: macros
        )
    }

    func test_multipleParameters_generatesAllPropertiesAndPath() {
        assertMacroExpansion(
            """
            @URLPathTemplate("users/{userId}/posts/{postId}")
            struct GetPostRequest {}
            """,
            expandedSource: """
            struct GetPostRequest {

                let userId: PathParameterStringConvertible

                let postId: PathParameterStringConvertible

                var path: URLPath {
                    URLPath(unsafeValue: "users/\\(userId.stringRepresentation)/posts/\\(postId.stringRepresentation)")
                }
            }
            """,
            macros: macros
        )
    }

    func test_parameterAtStart_generatesCorrectPath() {
        assertMacroExpansion(
            """
            @URLPathTemplate("{version}/users")
            struct GetUsersRequest {}
            """,
            expandedSource: """
            struct GetUsersRequest {

                let version: PathParameterStringConvertible

                var path: URLPath {
                    URLPath(unsafeValue: "\\(version.stringRepresentation)/users")
                }
            }
            """,
            macros: macros
        )
    }

    func test_parameterAtEnd_generatesCorrectPath() {
        assertMacroExpansion(
            """
            @URLPathTemplate("users/{id}")
            struct DeleteUserRequest {}
            """,
            expandedSource: """
            struct DeleteUserRequest {

                let id: PathParameterStringConvertible

                var path: URLPath {
                    URLPath(unsafeValue: "users/\\(id.stringRepresentation)")
                }
            }
            """,
            macros: macros
        )
    }

    // swiftlint:disable line_length
    func test_parametersPreserveExtractionOrder() {
        assertMacroExpansion(
            """
            @URLPathTemplate("a/{first}/b/{second}/c/{third}")
            struct MultiParamRequest {}
            """,
            expandedSource: """
            struct MultiParamRequest {

                let first: PathParameterStringConvertible

                let second: PathParameterStringConvertible

                let third: PathParameterStringConvertible

                var path: URLPath {
                    URLPath(unsafeValue: "a/\\(first.stringRepresentation)/b/\\(second.stringRepresentation)/c/\\(third.stringRepresentation)")
                }
            }
            """,
            macros: macros
        )
    }

    // swiftlint:enable line_length

    // MARK: - Validation errors

    func test_emptyTemplate_emitsError() {
        assertMacroExpansion(
            """
            @URLPathTemplate("")
            struct BadRequest {}
            """,
            expandedSource: """
            struct BadRequest {}
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@URLPathTemplate path must not be empty",
                    line: 1,
                    column: 1,
                    severity: .error
                )
            ],
            macros: macros
        )
    }

    func test_duplicateParameters_emitsError() {
        assertMacroExpansion(
            """
            @URLPathTemplate("users/{id}/posts/{id}")
            struct DuplicateRequest {}
            """,
            expandedSource: """
            struct DuplicateRequest {}
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@URLPathTemplate contains duplicate parameter names",
                    line: 1,
                    column: 1,
                    severity: .error
                )
            ],
            macros: macros
        )
    }

    func test_unencodedSpace_outsideBraces_emitsError() {
        assertMacroExpansion(
            """
            @URLPathTemplate("users profile")
            struct BadRequest {}
            """,
            expandedSource: """
            struct BadRequest {}
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@URLPathTemplate contains an unencoded space — use %20",
                    line: 1,
                    column: 1,
                    severity: .error
                )
            ],
            macros: macros
        )
    }

    func test_queryCharacter_outsideBraces_emitsError() {
        assertMacroExpansion(
            """
            @URLPathTemplate("users?active=true")
            struct BadRequest {}
            """,
            expandedSource: """
            struct BadRequest {}
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@URLPathTemplate contains an unencoded '?' — query parameters belong in NetworkRequestWithQuery",
                    line: 1,
                    column: 1,
                    severity: .error
                )
            ],
            macros: macros
        )
    }

    func test_fragmentCharacter_outsideBraces_emitsError() {
        assertMacroExpansion(
            """
            @URLPathTemplate("users#section")
            struct BadRequest {}
            """,
            expandedSource: """
            struct BadRequest {}
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@URLPathTemplate contains an unencoded '#' — use %23",
                    line: 1,
                    column: 1,
                    severity: .error
                )
            ],
            macros: macros
        )
    }

    /// Interpolated string literals have no segments readable as plain text,
    /// so the macro falls through to the empty-string check after extracting "".
    func test_interpolation_emitsError() {
        assertMacroExpansion(
            #"""
            let prefix = "v2"
            @URLPathTemplate("\(prefix)/users/{id}")
            struct BadRequest {}
            """#,
            expandedSource: #"""
            let prefix = "v2"
            struct BadRequest {}
            """#,
            diagnostics: [
                DiagnosticSpec(
                    message: "@URLPathTemplate path must not be empty",
                    line: 2,
                    column: 1,
                    severity: .error
                )
            ],
            macros: macros
        )
    }
}
#endif

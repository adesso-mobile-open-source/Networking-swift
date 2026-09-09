//
//  URLPathMacroTests.swift
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
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

@testable import NetworkingMacros

final class URLPathMacroTests: XCTestCase {

    private let macros: [String: any Macro.Type] = ["URLPath": URLPathMacro.self]

    // MARK: - Valid expansion

    func test_validPath_expandsToURLPathInit() {
        assertMacroExpansion(
            """
            #URLPath(unsafeValue: "users/profile")
            """,
            expandedSource: """
            URLPath(unsafeValue: "users/profile")
            """,
            macros: macros
        )
    }

    func test_validPath_withMultipleSegments() {
        assertMacroExpansion(
            """
            #URLPath(unsafeValue: "v2/accounts/123/statements")
            """,
            expandedSource: """
            URLPath(unsafeValue: "v2/accounts/123/statements")
            """,
            macros: macros
        )
    }

    func test_validPath_withPercentEncoding() {
        assertMacroExpansion(
            """
            #URLPath(unsafeValue: "search/my%20query")
            """,
            expandedSource: """
            URLPath(unsafeValue: "search/my%20query")
            """,
            macros: macros
        )
    }

    func test_validPath_singleSegment() {
        assertMacroExpansion(
            """
            #URLPath(unsafeValue: "users")
            """,
            expandedSource: """
            URLPath(unsafeValue: "users")
            """,
            macros: macros
        )
    }

    // MARK: - Scheme rejection

    func test_pathWithScheme_emitsError() {
        assertMacroExpansion(
            """
            #URLPath(unsafeValue: "https://api.example.com/users")
            """,
            expandedSource: """
            #URLPath(unsafeValue: "https://api.example.com/users")
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "#URLPath must be a relative path — place the scheme and host in #URLBase instead",
                    line: 1,
                    column: 1,
                    severity: .error
                )
            ],
            macros: macros
        )
    }

    // MARK: - Empty path

    func test_emptyPath_emitsError() {
        assertMacroExpansion(
            """
            #URLPath(unsafeValue: "")
            """,
            expandedSource: """
            #URLPath(unsafeValue: "")
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "#URLPath path must not be empty",
                    line: 1,
                    column: 1,
                    severity: .error
                )
            ],
            macros: macros
        )
    }

    // MARK: - Forbidden characters

    func test_unencodedSpace_emitsError() {
        assertMacroExpansion(
            """
            #URLPath(unsafeValue: "users profile")
            """,
            expandedSource: """
            #URLPath(unsafeValue: "users profile")
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "#URLPath contains unencoded space — use %20",
                    line: 1,
                    column: 1,
                    severity: .error
                )
            ],
            macros: macros
        )
    }

    func test_queryCharacter_emitsError() {
        assertMacroExpansion(
            """
            #URLPath(unsafeValue: "users?page=1")
            """,
            expandedSource: """
            #URLPath(unsafeValue: "users?page=1")
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "#URLPath contains unencoded '?' — query parameters belong in NetworkRequestWithQuery",
                    line: 1,
                    column: 1,
                    severity: .error
                )
            ],
            macros: macros
        )
    }

    func test_fragmentCharacter_emitsError() {
        assertMacroExpansion(
            """
            #URLPath(unsafeValue: "users#section")
            """,
            expandedSource: """
            #URLPath(unsafeValue: "users#section")
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "#URLPath contains unencoded '#' — use %23",
                    line: 1,
                    column: 1,
                    severity: .error
                )
            ],
            macros: macros
        )
    }

    func test_openBrace_emitsError() {
        assertMacroExpansion(
            """
            #URLPath(unsafeValue: "users/{id}")
            """,
            expandedSource: """
            #URLPath(unsafeValue: "users/{id}")
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "#URLPath contains unencoded '{' — use @URLPathTemplate for dynamic paths",
                    line: 1,
                    column: 1,
                    severity: .error
                )
            ],
            macros: macros
        )
    }

    // MARK: - Interpolation rejection

    func test_stringInterpolation_emitsError() {
        assertMacroExpansion(
            """
            let id = "42"
            #URLPath(unsafeValue: "users/\\(id)")
            """,
            expandedSource: """
            let id = "42"
            #URLPath(unsafeValue: "users/\\(id)")
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "#URLPath requires a simple string literal with no interpolations",
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

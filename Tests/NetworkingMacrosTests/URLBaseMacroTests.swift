//
//  URLBaseMacroTests.swift
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

final class URLBaseMacroTests: XCTestCase {
    private let macros: [String: any Macro.Type] = ["URLBase": URLBaseMacro.self]

    // MARK: - Valid expansion

    func test_validBase_expandsToURLBaseInit() {
        assertMacroExpansion(
            """
            #URLBase(unsafeValue: "https://api.example.com")
            """,
            expandedSource: """
            URLBase(unsafeValue: "https://api.example.com")
            """,
            macros: macros
        )
    }

    func test_validBase_withPathPrefix() {
        assertMacroExpansion(
            """
            #URLBase(unsafeValue: "https://api.example.com/v2")
            """,
            expandedSource: """
            URLBase(unsafeValue: "https://api.example.com/v2")
            """,
            macros: macros
        )
    }

    func test_validBase_withPort() {
        assertMacroExpansion(
            """
            #URLBase(unsafeValue: "https://api.example.com:8080")
            """,
            expandedSource: """
            URLBase(unsafeValue: "https://api.example.com:8080")
            """,
            macros: macros
        )
    }

    func test_validBase_httpScheme() {
        assertMacroExpansion(
            """
            #URLBase(unsafeValue: "http://staging.example.com")
            """,
            expandedSource: """
            URLBase(unsafeValue: "http://staging.example.com")
            """,
            macros: macros
        )
    }

    // MARK: - Empty

    func test_emptyString_emitsError() {
        assertMacroExpansion(
            """
            #URLBase(unsafeValue: "")
            """,
            expandedSource: """
            #URLBase(unsafeValue: "")
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "#URLBase value must not be empty",
                    line: 1,
                    column: 1,
                    severity: .error
                )
            ],
            macros: macros
        )
    }

    // MARK: - Missing scheme

    func test_missingScheme_emitsError() {
        assertMacroExpansion(
            """
            #URLBase(unsafeValue: "api.example.com")
            """,
            expandedSource: """
            #URLBase(unsafeValue: "api.example.com")
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "#URLBase must include a scheme, e.g. \"https://api.example.com\"",
                    line: 1,
                    column: 1,
                    severity: .error
                )
            ],
            macros: macros
        )
    }

    func test_emptyScheme_emitsError() {
        assertMacroExpansion(
            """
            #URLBase(unsafeValue: "://api.example.com")
            """,
            expandedSource: """
            #URLBase(unsafeValue: "://api.example.com")
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "#URLBase scheme must not be empty",
                    line: 1,
                    column: 1,
                    severity: .error
                )
            ],
            macros: macros
        )
    }

    // MARK: - Missing host

    func test_emptyHost_emitsError() {
        assertMacroExpansion(
            """
            #URLBase(unsafeValue: "https://")
            """,
            expandedSource: """
            #URLBase(unsafeValue: "https://")
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "#URLBase must include a non-empty host, e.g. \"https://api.example.com\"",
                    line: 1,
                    column: 1,
                    severity: .error
                )
            ],
            macros: macros
        )
    }

    // MARK: - Forbidden components

    func test_queryString_emitsError() {
        assertMacroExpansion(
            """
            #URLBase(unsafeValue: "https://api.example.com?key=value")
            """,
            expandedSource: """
            #URLBase(unsafeValue: "https://api.example.com?key=value")
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "#URLBase must not contain a query string — add query parameters via NetworkRequestWithQuery",
                    line: 1,
                    column: 1,
                    severity: .error
                )
            ],
            macros: macros
        )
    }

    func test_fragment_emitsError() {
        assertMacroExpansion(
            """
            #URLBase(unsafeValue: "https://api.example.com#section")
            """,
            expandedSource: """
            #URLBase(unsafeValue: "https://api.example.com#section")
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "#URLBase must not contain a fragment — use %23 if a literal '#' is needed in the path",
                    line: 1,
                    column: 1,
                    severity: .error
                )
            ],
            macros: macros
        )
    }

    func test_templateParameter_emitsError() {
        assertMacroExpansion(
            """
            #URLBase(unsafeValue: "https://api.example.com/{version}")
            """,
            expandedSource: """
            #URLBase(unsafeValue: "https://api.example.com/{version}")
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "#URLBase must not contain template parameters — use #URLPath or @URLPathTemplate for dynamic segments",
                    line: 1,
                    column: 1,
                    severity: .error
                )
            ],
            macros: macros
        )
    }

    func test_unencodedSpace_emitsError() {
        assertMacroExpansion(
            """
            #URLBase(unsafeValue: "https://api.example .com")
            """,
            expandedSource: """
            #URLBase(unsafeValue: "https://api.example .com")
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "#URLBase must not contain unencoded spaces — use %20",
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
            let host = "api.example.com"
            #URLBase(unsafeValue: "https://\\(host)")
            """,
            expandedSource: """
            let host = "api.example.com"
            #URLBase(unsafeValue: "https://\\(host)")
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "#URLBase requires a simple string literal with no interpolations",
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

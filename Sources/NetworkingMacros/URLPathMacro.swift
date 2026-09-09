//
//  URLPathMacro.swift
//  Networking
//
//  Created by Niklas Holloh on 14.06.26.
//  Copyright 2026 adesso SE
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//

import SwiftSyntax
import SwiftSyntaxMacros

/// Implementation of the `#URLPath` freestanding expression macro.
///
/// Validates the path string at compile time and expands to
/// `URLPath("<path>")`.
public struct URLPathMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        guard
            let argument = node.arguments.first?.expression,
            let stringLiteral = argument.as(StringLiteralExprSyntax.self),
            stringLiteral.segments.count == 1,
            let segment = stringLiteral.segments.first?.as(StringSegmentSyntax.self)
        else {
            throw MacroExpansionErrorMessage("#URLPath requires a simple string literal with no interpolations")
        }

        let path = segment.content.text

        // Validate: non-empty
        guard !path.isEmpty else {
            throw MacroExpansionErrorMessage("#URLPath path must not be empty")
        }

        // Validate: no scheme — paths must be relative, use #URLBase for the host/scheme
        if path.contains("://") {
            throw MacroExpansionErrorMessage("#URLPath must be a relative path — place the scheme and host in #URLBase instead")
        }

        // Validate: no unencoded invalid characters
        let forbidden: [(Character, String)] = [
            (" ", "unencoded space — use %20"),
            ("?", "unencoded '?' — query parameters belong in NetworkRequestWithQuery"),
            ("#", "unencoded '#' — use %23"),
            ("{", "unencoded '{' — use @URLPathTemplate for dynamic paths"),
            ("}", "unencoded '}'")
        ]

        for (char, hint) in forbidden where path.contains(char) {
            throw MacroExpansionErrorMessage("#URLPath contains \(hint)")
        }

        for scalar in path.unicodeScalars {
            if scalar.value <= 0x1F || scalar.value == 0x7F {
                let hex = String(scalar.value, radix: 16, uppercase: true)
                let padded = String(repeating: "0", count: max(0, 4 - hex.count)) + hex
                throw MacroExpansionErrorMessage("#URLPath contains an unencoded control character (U+\(padded))")
            }
        }

        return "URLPath(unsafeValue: \(literal: path))"
    }
}

//
//  URLBaseMacro.swift
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

/// Implementation of the `#URLBase` freestanding expression macro.
///
/// Validates the base URL string at compile time and expands to
/// `URLBase("<value>")`.
///
/// Validation rules:
/// - Must have a scheme (e.g. `https://`)
/// - Must have a non-empty host
/// - Must not contain a query string (`?`)
/// - Must not contain a fragment (`#`)
/// - Must not contain template parameters (`{`, `}`)
/// - Must not contain unencoded spaces or control characters
public struct URLBaseMacro: ExpressionMacro {
    // swiftlint:disable:next cyclomatic_complexity
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in _: some MacroExpansionContext
    ) throws -> ExprSyntax {
        guard
            let argument = node.arguments.first?.expression,
            let stringLiteral = argument.as(StringLiteralExprSyntax.self),
            stringLiteral.segments.count == 1,
            let segment = stringLiteral.segments.first?.as(StringSegmentSyntax.self)
        else {
            throw MacroExpansionErrorMessage("#URLBase requires a simple string literal with no interpolations")
        }

        let raw = segment.content.text

        // Must not be empty
        guard !raw.isEmpty else {
            throw MacroExpansionErrorMessage("#URLBase value must not be empty")
        }

        // Must have a scheme (contains "://")
        guard let schemeRange = raw.firstRange(of: "://") else {
            throw MacroExpansionErrorMessage("#URLBase must include a scheme, e.g. \"https://api.example.com\"")
        }

        // Scheme must be non-empty (something before "://")
        guard schemeRange.lowerBound > raw.startIndex else {
            throw MacroExpansionErrorMessage("#URLBase scheme must not be empty")
        }

        // Host must be non-empty (text after "://")
        let afterScheme = raw[schemeRange.upperBound...]
        let hostPart = afterScheme.prefix(while: { $0 != "/" && $0 != "?" && $0 != "#" })
        guard !hostPart.isEmpty else {
            throw MacroExpansionErrorMessage("#URLBase must include a non-empty host, e.g. \"https://api.example.com\"")
        }

        // No query string
        guard !raw.contains("?") else {
            throw MacroExpansionErrorMessage("#URLBase must not contain a query string — add query parameters via NetworkRequestWithQuery")
        }

        // No fragment
        guard !raw.contains("#") else {
            throw MacroExpansionErrorMessage("#URLBase must not contain a fragment — use %23 if a literal '#' is needed in the path")
        }

        // No template parameters
        guard !raw.contains("{"), !raw.contains("}") else {
            throw MacroExpansionErrorMessage(
                "#URLBase must not contain template parameters — use #URLPath or @URLPathTemplate for dynamic segments"
            )
        }

        // No unencoded spaces or control characters
        guard !raw.contains(" ") else {
            throw MacroExpansionErrorMessage("#URLBase must not contain unencoded spaces — use %20")
        }

        for scalar in raw.unicodeScalars {
            if scalar.value <= 0x1F || scalar.value == 0x7F {
                let hex = String(scalar.value, radix: 16, uppercase: true)
                let padded = String(repeating: "0", count: max(0, 4 - hex.count)) + hex
                throw MacroExpansionErrorMessage("#URLBase contains an unencoded control character (U+\(padded))")
            }
        }

        return "URLBase(unsafeValue: \(literal: raw))"
    }
}

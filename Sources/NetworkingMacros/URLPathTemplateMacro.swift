//
//  URLPathTemplateMacro.swift
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

/// Implementation of the `@URLPathTemplate` attached member macro.
///
/// Given `@URLPathTemplate("users/{id}/posts/{postId}")` on a type, generates:
/// ```swift
/// let id: PathParameterStringConvertible
/// let postId: PathParameterStringConvertible
///
/// var path: URLPath { URLPath(unsafeValue: "users/\(id.stringRepresentation)/posts/\(postId.stringRepresentation)") }
/// ```
public struct URLPathTemplateMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf _: some DeclGroupSyntax,
        conformingTo _: [TypeSyntax],
        in _: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard
            let stringLiteral = node.arguments?
            .as(LabeledExprListSyntax.self)?
            .first?.expression
            .as(StringLiteralExprSyntax.self)
        else {
            throw MacroExpansionErrorMessage("@URLPathTemplate requires a simple string literal with no interpolations")
        }

        let templateString = stringLiteral.segments.first?.as(StringSegmentSyntax.self)?.content.text ?? ""

        // Validate: non-empty
        guard !templateString.isEmpty else {
            throw MacroExpansionErrorMessage("@URLPathTemplate path must not be empty")
        }

        // Validate: no unencoded spaces or query/fragment characters outside braces
        try validateTemplate(templateString, node: stringLiteral)

        let parameterNames = extractParameters(from: templateString)

        // Validate: no duplicate parameter names
        guard parameterNames.count == Set(parameterNames).count else {
            throw MacroExpansionErrorMessage("@URLPathTemplate contains duplicate parameter names")
        }

        let interpolatedString = transformToInterpolation(templateString, parameters: parameterNames)

        var members: [DeclSyntax] = []

        // Generate `let <param>: PathParameterStringConvertible` stored properties
        for param in parameterNames {
            members.append("let \(raw: param): PathParameterStringConvertible")
        }

        // Generate path computed property calling .stringRepresentation on each parameter
        members.append("""
        var path: URLPath {
            URLPath(unsafeValue: "\(raw: interpolatedString)")
        }
        """)

        return members
    }

    // MARK: - Validation

    private static func validateTemplate(_ template: String, node _: some SyntaxProtocol) throws {
        var inBraces = false
        for char in template {
            if char == "{" {
                inBraces = true
                continue
            } else if char == "}" {
                inBraces = false
                continue
            }
            guard !inBraces else { continue }

            switch char {
            case " ":
                throw MacroExpansionErrorMessage("@URLPathTemplate contains an unencoded space — use %20")
            case "?":
                throw MacroExpansionErrorMessage(
                    "@URLPathTemplate contains an unencoded '?' — query parameters belong in NetworkRequestWithQuery"
                )
            case "#":
                throw MacroExpansionErrorMessage("@URLPathTemplate contains an unencoded '#' — use %23")
            default:
                break
            }
        }

        for scalar in template.unicodeScalars {
            if scalar.value <= 0x1F || scalar.value == 0x7F {
                let hex = String(scalar.value, radix: 16, uppercase: true)
                let padded = String(repeating: "0", count: max(0, 4 - hex.count)) + hex
                throw MacroExpansionErrorMessage("@URLPathTemplate contains an unencoded control character (U+\(padded))")
            }
        }
    }

    // MARK: - Helpers

    /// Extracts `{param}` names from a template string, in order of appearance.
    private static func extractParameters(from template: String) -> [String] {
        var parameters: [String] = []
        var current = ""
        var inBraces = false

        for char in template {
            if char == "{" {
                inBraces = true
                current = ""
            } else if char == "}" {
                inBraces = false
                if !current.isEmpty {
                    parameters.append(current)
                }
            } else if inBraces {
                current.append(char)
            }
        }

        return parameters
    }

    /// Converts `{param}` → `\(param.stringRepresentation)` for Swift string interpolation.
    ///
    /// Parameters are replaced in extraction order. Overlap between tokens is impossible
    /// because each placeholder is fully delimited by its own `{` and `}` braces —
    /// `{id}` can never appear as a substring inside `{userId}` in a well-formed template.
    private static func transformToInterpolation(_ template: String, parameters: [String]) -> String {
        var result = template
        for param in parameters {
            result = result.replacing("{\(param)}", with: "\\(\(param).stringRepresentation)")
        }
        return result
    }
}

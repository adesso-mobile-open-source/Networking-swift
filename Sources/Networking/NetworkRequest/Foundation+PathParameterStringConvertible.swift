//
//  Foundation+PathParameterStringConvertible.swift
//  Networking
//
//  Created by Niklas Holloh on 16.06.26.
//  Copyright 2026 adesso SE
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//

import Foundation

// MARK: - Swift standard library

// Signed integers
extension Int: PathParameterStringConvertible {
    public var stringRepresentation: String { description }
}

extension Int8: PathParameterStringConvertible {
    public var stringRepresentation: String { description }
}

extension Int16: PathParameterStringConvertible {
    public var stringRepresentation: String { description }
}

extension Int32: PathParameterStringConvertible {
    public var stringRepresentation: String { description }
}

extension Int64: PathParameterStringConvertible {
    public var stringRepresentation: String { description }
}

// Unsigned integers
extension UInt: PathParameterStringConvertible {
    public var stringRepresentation: String { description }
}

extension UInt8: PathParameterStringConvertible {
    public var stringRepresentation: String { description }
}

extension UInt16: PathParameterStringConvertible {
    public var stringRepresentation: String { description }
}

extension UInt32: PathParameterStringConvertible {
    public var stringRepresentation: String { description }
}

extension UInt64: PathParameterStringConvertible {
    public var stringRepresentation: String { description }
}

// Floating point
extension Float: PathParameterStringConvertible {
    public var stringRepresentation: String { description }
}

extension Double: PathParameterStringConvertible {
    public var stringRepresentation: String { description }
}

// Boolean
extension Bool: PathParameterStringConvertible {
    public var stringRepresentation: String { description }
}

// String
extension String: PathParameterStringConvertible {
    public var stringRepresentation: String { self }
}

// MARK: - Foundation

// UUID — uses uuidString (uppercase, hyphenated) rather than description,
// which on some platforms adds additional formatting.
extension UUID: PathParameterStringConvertible {
    public var stringRepresentation: String { uuidString }
}

// Decimal — preferred over Double for monetary/precise numeric path segments.
extension Decimal: PathParameterStringConvertible {
    public var stringRepresentation: String { description }
}

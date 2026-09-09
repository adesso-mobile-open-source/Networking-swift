//
//  NetworkActor.swift
//  Networking
//
//  Created by Niklas Holloh on 25.06.26.
//  Copyright 2026 adesso SE
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//

/// Global actor for isolating Network operations to ensure thread-safe access.
@globalActor
public actor NetworkActor {
    /// Shared instance of the NetworkActor.
    public static let shared = NetworkActor()
    private init() { }
}

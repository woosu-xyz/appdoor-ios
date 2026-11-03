//
//  EventResponse.swift
//  AppDoorSDK
//
//  Copyright (c) 2025 AppDoor
//  Licensed under the MIT License
//

import Foundation

/// Response from event tracking endpoint
struct EventResponse: Codable {
    /// Whether the event was successfully tracked
    let success: Bool
}

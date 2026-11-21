//
//  AppDoorConfig.swift
//  AppDoorSDK
//
//  Copyright (c) 2025 AppDoor
//  Licensed under the MIT License
//

import Foundation

/// Configuration for the AppDoor SDK
public struct AppDoorConfig {
    // MARK: - Properties

    /// Your app's own AppDoor link domain, e.g. `https://link.nelloom.app` (required)
    /// - Note: One AppDoor backend serves many apps, each on its own custom link
    ///   domain; the request host decides the app. The SDK sends its API calls here
    ///   and only resolves incoming links whose host matches this one.
    ///   Must be HTTPS (HTTP allowed for localhost testing only).
    public let baseURL: URL

    /// Public workspace token for AppDoor Cloud (optional)
    /// - Note: Recommended for Cloud — required for organic installs
    ///   (App Store discovery, social mentions, etc.) to be attributed
    ///   to your workspace. Find it in the dashboard under Workspace
    ///   Settings → App Token. Safe to ship in your app bundle —
    ///   identifies the workspace only, can't authenticate API actions.
    /// - Format: `at_<32 hex chars>`
    public let appToken: String?

    /// Enable debug logging
    /// - Note: Logs network requests, responses, and SDK operations
    public let debug: Bool

    /// Attribution window in hours (1-2160, default: 168 = 7 days)
    /// - Note: How long after a click an install can be attributed
    public let attributionWindowHours: Int

    // MARK: - Initialization

    /// Creates a new AppDoor configuration
    ///
    /// - Parameters:
    ///   - baseURL: Your app's link domain (required, e.g. https://link.nelloom.app)
    ///   - appToken: Optional public workspace token (AppDoor Cloud only)
    ///   - debug: Enable debug logging (default: false)
    ///   - attributionWindowHours: Attribution window in hours (default: 168 = 7 days)
    ///
    /// - Note: For self-hosted AppDoor Core, omit the appToken parameter
    public init(
        baseURL: URL,
        appToken: String? = nil,
        debug: Bool = false,
        attributionWindowHours: Int = 168
    ) {
        self.baseURL = baseURL
        self.appToken = appToken
        self.debug = debug
        self.attributionWindowHours = attributionWindowHours
    }

    // MARK: - Validation

    /// Validates the configuration
    /// - Throws: `AppDoorError.invalidConfiguration` if validation fails
    func validate() throws {
        // Needs scheme + host: URL(string: "link.nelloom.app") parses as a bare path with no host
        guard let host = baseURL.host, !host.isEmpty else {
            throw AppDoorError.invalidConfiguration(
                "Base URL must include a scheme and host, e.g. https://link.nelloom.app " +
                "(got \"\(baseURL.absoluteString)\")"
            )
        }

        // Validate HTTPS (except localhost)
        if baseURL.scheme?.lowercased() != "https" && !isLocalhost {
            throw AppDoorError.invalidConfiguration(
                "Base URL must use HTTPS (HTTP only allowed for localhost)"
            )
        }

        // Validate attribution window (1 hour to 90 days)
        guard attributionWindowHours >= 1 && attributionWindowHours <= 2160 else {
            throw AppDoorError.invalidConfiguration(
                "Attribution window must be between 1 and 2160 hours"
            )
        }
    }

    // MARK: - Helpers

    /// Checks if the base URL is localhost
    private var isLocalhost: Bool {
        guard let host = baseURL.host?.lowercased() else { return false }
        return host == "localhost" || host == "127.0.0.1" || host == "0.0.0.0"
    }
}

// MARK: - CustomStringConvertible

extension AppDoorConfig: CustomStringConvertible {
    public var description: String {
        """
        AppDoorConfig(
            baseURL: \(baseURL.absoluteString),
            appToken: \(appToken != nil ? "***" : "nil"),
            debug: \(debug),
            attributionWindowHours: \(attributionWindowHours)
        )
        """
    }
}

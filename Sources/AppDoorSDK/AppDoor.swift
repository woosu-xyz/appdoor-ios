//
//  AppDoor.swift
//  AppDoorSDK
//
//  Copyright (c) 2025 AppDoor
//  Licensed under the MIT License
//

import Foundation

/// Main SDK class - singleton interface for AppDoor
@available(iOS 13.0, macOS 10.15, *)
public final class AppDoor {
    // MARK: - Singleton

    /// Shared instance
    public static let shared = AppDoor()

    // MARK: - Properties

    private var config: AppDoorConfig?
    private var networkManager: NetworkManager?
    private var attributionManager: AttributionManager?
    private var attributionContext: AttributionContext?
    private var eventTracker: EventTracker?
    private var deepLinkHandler: DeepLinkHandler?

    private let initQueue = DispatchQueue(label: "app.appdoor.sdk.init", qos: .userInitiated)
    private var isInitialized = false

    // MARK: - Initialization

    private init() {}

    /// Initializes the SDK with configuration
    /// - Parameters:
    ///   - config: SDK configuration
    ///   - attributionWindowHours: Attribution window in hours (default: 168 = 7 days)
    ///   - deviceId: Optional device identifier for attribution
    /// - Returns: InstallResponse with attribution data
    /// - Throws: AppDoorError if initialization fails
    @discardableResult
    public func initialize(
        config: AppDoorConfig,
        attributionWindowHours: Int = 168,
        deviceId: String? = nil
    ) async throws -> InstallResponse {
        // Synchronize access to initialization state
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            initQueue.async {
                // Check if already initialized
                guard !self.isInitialized else {
                    continuation.resume(throwing: AppDoorError.alreadyInitialized)
                    return
                }

                // Validate configuration
                do {
                    try config.validate()
                } catch {
                    continuation.resume(throwing: error)
                    return
                }

                // Store configuration
                self.config = config

                // Create and wire the managers
                self.setUpManagers(config: config)

                // Mark as initialized
                self.isInitialized = true

                continuation.resume()
            }
        }

        // Report install and get attribution data (outside the serial queue)
        let response = try await attributionManager!.reportInstall(
            attributionWindowHours: attributionWindowHours,
            deviceId: deviceId,
            appToken: config.appToken
        )

        // If attributed, notify deferred deep link handler
        if response.attributed, let deepLinkData = response.deepLinkData {
            deepLinkHandler?.deliverDeferredDeepLink(deepLinkData)
        }

        AppDoorLogger.log("SDK initialized successfully (attributed: \(response.attributed))")

        return response
    }

    /// Creates the SDK's managers and wires the shared attribution context into
    /// the event tracker and deep-link handler. Must be called on `initQueue`.
    private func setUpManagers(config: AppDoorConfig) {
        let storageManager = StorageManager()
        let networkManager = NetworkManager(config: config)
        let fingerprintCollector = FingerprintCollector()
        let attributionContext = AttributionContext(debug: config.debug)

        self.networkManager = networkManager
        self.attributionContext = attributionContext

        self.attributionManager = AttributionManager(
            networkManager: networkManager,
            storageManager: storageManager,
            fingerprintCollector: fingerprintCollector
        )

        self.eventTracker = EventTracker(
            networkManager: networkManager,
            storageManager: storageManager,
            attributionContext: attributionContext
        )

        let handler = DeepLinkHandler()
        handler.configure(
            networkManager: networkManager,
            fingerprintCollector: fingerprintCollector,
            baseURL: config.baseURL,
            attributionContext: attributionContext
        )
        self.deepLinkHandler = handler
    }

    // MARK: - Deep Linking

    /// Handles a deep link URL (Universal Link or custom scheme)
    /// - Parameter url: Deep link URL to handle
    public func handleDeepLink(url: URL) {
        guard isInitialized else {
            AppDoorLogger.log("SDK not initialized. Call initialize() first.")
            return
        }

        deepLinkHandler?.handleDeepLink(url)
    }

    /// Registers a callback for deferred deep links (triggered on first launch after attributed install)
    /// - Parameter callback: Callback to invoke with deep link data
    public func onDeferredDeepLink(_ callback: @escaping DeferredDeepLinkCallback) {
        guard isInitialized else {
            AppDoorLogger.log("SDK not initialized. Call initialize() first.")
            return
        }

        deepLinkHandler?.onDeferredDeepLink(callback)
    }

    /// Registers a callback for deep links (triggered when app opens from link)
    /// - Parameter callback: Callback to invoke with deep link data
    public func onDeepLink(_ callback: @escaping DeepLinkCallback) {
        guard isInitialized else {
            AppDoorLogger.log("SDK not initialized. Call initialize() first.")
            return
        }

        deepLinkHandler?.onDeepLink(callback)
    }


    // MARK: - Event Tracking

    /// Tracks a custom event
    /// - Parameters:
    ///   - name: Event name (e.g., "purchase", "signup")
    ///   - properties: Optional event properties (must be JSON-serializable)
    /// - Throws: AppDoorError if tracking fails
    public func trackEvent(name: String, properties: [String: Any]? = nil) async throws {
        guard isInitialized else {
            throw AppDoorError.notInitialized
        }

        try await eventTracker?.trackEvent(name: name, properties: properties)
    }

    /// Tracks a revenue event
    /// - Parameters:
    ///   - amount: Revenue amount
    ///   - currency: Currency code (e.g., "USD")
    ///   - properties: Optional additional properties
    /// - Throws: AppDoorError if tracking fails
    public func trackRevenue(
        amount: Decimal,
        currency: String,
        properties: [String: Any]? = nil
    ) async throws {
        guard isInitialized else {
            throw AppDoorError.notInitialized
        }

        try await eventTracker?.trackRevenue(
            amount: amount,
            currency: currency,
            properties: properties
        )
    }

    /// Tracks a screen view.
    ///
    /// Emits a `screen_view` event stamped with the active last-click attribution
    /// context, so the dashboard can show which screens users reach after opening a
    /// deep link. Call from `viewDidAppear` (UIKit) or use the SwiftUI
    /// `.appDoorScreen("Name")` modifier.
    ///
    /// - Parameters:
    ///   - name: Screen name (e.g., "ProductDetail")
    ///   - properties: Optional additional properties
    /// - Throws: AppDoorError if tracking fails
    public func trackScreenView(name: String, properties: [String: Any]? = nil) async throws {
        guard isInitialized else {
            throw AppDoorError.notInitialized
        }

        try await eventTracker?.trackScreenView(name: name, properties: properties)
    }

    /// Flushes the event queue, attempting to send all queued events
    public func flushEvents() async {
        guard isInitialized else {
            AppDoorLogger.log("SDK not initialized. Call initialize() first.")
            return
        }

        await eventTracker?.flushQueue()
    }

    /// Returns the number of queued events
    public var queuedEventCount: Int {
        guard isInitialized else {
            return 0
        }

        return eventTracker?.queuedEventCount ?? 0
    }

    /// Clears the event queue
    public func clearEventQueue() {
        guard isInitialized else {
            AppDoorLogger.log("SDK not initialized. Call initialize() first.")
            return
        }

        eventTracker?.clearQueue()
    }

    // MARK: - Attribution Data

    /// Returns the install ID if available
    public func getInstallId() -> String? {
        guard isInitialized else {
            return nil
        }

        return attributionManager?.getInstallId()
    }

    /// Returns the install attribution data if available
    public func getInstallData() -> DeepLinkData? {
        guard isInitialized else {
            return nil
        }

        return attributionManager?.getInstallData()
    }

    /// Returns whether this is the first launch
    public func isFirstLaunch() -> Bool {
        guard isInitialized else {
            return true
        }

        return attributionManager?.isFirstLaunch() ?? true
    }

    // MARK: - Data Management

    /// Clears all stored SDK data
    public func clearData() {
        attributionManager?.clearData()
        attributionContext?.clear()
        eventTracker?.clearQueue()
        deepLinkHandler?.clearCallbacks()

        AppDoorLogger.log("All SDK data cleared")
    }

    /// Resets the SDK to uninitialized state
    /// Note: This does NOT clear stored data. Call clearData() first if needed.
    public func reset() {
        initQueue.sync {
            config = nil
            networkManager = nil
            attributionManager = nil
            attributionContext = nil
            eventTracker = nil
            deepLinkHandler = nil
            isInitialized = false

            AppDoorLogger.log("SDK reset to uninitialized state")
        }
    }
}

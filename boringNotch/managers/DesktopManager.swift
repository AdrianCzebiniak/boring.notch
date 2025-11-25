//
//  DesktopManager.swift
//  boringNotch
//
//  Manages desktop/Space detection and naming
//

import Foundation
import AppKit
import Combine
import Defaults

// Notification for desktop changes
extension Notification.Name {
    static let desktopDidChange = Notification.Name("desktopDidChange")
}

/// Manages desktop Space tracking and custom naming
class DesktopManager: ObservableObject {

    static let shared = DesktopManager()

    @Published var currentSpaceID: UInt64 = 0
    @Published var currentSpaceName: String = ""

    private var cancellables = Set<AnyCancellable>()

    private init() {
        // Get initial active space
        updateCurrentSpace()

        // Observe space changes
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(spaceChanged),
            name: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil
        )

        // Observe changes to desktop names in Defaults
        Defaults.publisher(.desktopNames)
            .sink { [weak self] _ in
                self?.updateCurrentSpaceName()
            }
            .store(in: &cancellables)
    }

    deinit {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    /// Called when the active Space changes
    @objc private func spaceChanged() {
        updateCurrentSpace()
    }

    /// Updates the current space ID and name
    private func updateCurrentSpace() {
        let spaceID = getCurrentActiveSpaceID()
        let didChange = spaceID != currentSpaceID && currentSpaceID != 0

        currentSpaceID = spaceID
        updateCurrentSpaceName()

        // Post notification if desktop changed
        if didChange {
            NotificationCenter.default.post(name: .desktopDidChange, object: nil)
        }
    }

    /// Updates the current space name from stored preferences
    private func updateCurrentSpaceName() {
        let desktopNames = Defaults[.desktopNames]
        let spaceKey = String(currentSpaceID)
        currentSpaceName = desktopNames[spaceKey] ?? "Desktop \(getSpaceDisplayNumber())"
    }

    /// Gets a human-readable display number for the space
    private func getSpaceDisplayNumber() -> Int {
        // If we have a stored order, use it; otherwise use a simple counter
        let desktopNames = Defaults[.desktopNames]
        let existingKeys = desktopNames.keys.sorted()

        if let index = existingKeys.firstIndex(of: String(currentSpaceID)) {
            return index + 1
        }

        // Default to 1 if not found
        return 1
    }

    /// Sets a custom name for a specific desktop
    func setDesktopName(_ name: String, forSpaceID spaceID: UInt64) {
        var desktopNames = Defaults[.desktopNames]
        desktopNames[String(spaceID)] = name
        Defaults[.desktopNames] = desktopNames
    }

    /// Gets all known desktop spaces with their names
    func getAllDesktops() -> [(spaceID: String, name: String)] {
        let desktopNames = Defaults[.desktopNames]
        return desktopNames.map { (spaceID: $0.key, name: $0.value) }
            .sorted { $0.spaceID < $1.spaceID }
    }

    /// Removes a desktop name from preferences
    func removeDesktopName(forSpaceID spaceID: UInt64) {
        var desktopNames = Defaults[.desktopNames]
        desktopNames.removeValue(forKey: String(spaceID))
        Defaults[.desktopNames] = desktopNames
    }
}

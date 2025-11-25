# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Boring Notch** is a macOS application that transforms the MacBook's notch into an interactive Dynamic Island-style interface featuring music controls with visualizer, calendar integration, battery status, file shelf with AirDrop support, and system HUD replacements.

- **Platform**: macOS 14 Sonoma or later (Apple Silicon and Intel)
- **Framework**: SwiftUI with AppKit integration
- **Language**: Swift

## Build and Development Commands

### Building the Project

```bash
# Open in Xcode
open boringNotch.xcodeproj

# Build from command line (requires Xcode installation)
xcodebuild -project boringNotch.xcodeproj -scheme boringNotch -configuration Release build
```

### Running the App

- In Xcode: Click Run button or press `Cmd + R`
- The app creates floating windows positioned at the top-center of the screen(s)

### CI/CD

The project uses GitHub Actions for builds:
- `.github/workflows/cicd.yml` - Automated builds using Xcode 16+ on macOS
- Builds use the `boringNotch` scheme with Release configuration

## Architecture Overview

### Core Application Structure

The app follows **MVVM** architecture with heavy use of **Coordinator** and **Singleton** patterns:

```
DynamicNotchApp (@main)
    ↓
AppDelegate
    ├── Multi-screen window management
    ├── BoringNotchWindow creation/positioning per screen
    ├── Keyboard shortcut registration
    └── Onboarding flow
    ↓
ContentView → NotchLayout
    ├── BoringViewModel (notch state: open/closed)
    ├── BoringViewCoordinator (view transitions: home ↔ shelf)
    └── Dynamic content based on state
```

### Key Directory Structure

- **`/models/`** - View models and data structures
  - `BoringViewModel.swift` - Main notch state (open/closed, size calculations)
  - `BatteryStatusViewModel.swift` - Battery monitoring
  - `Constants.swift` - App-wide configuration using Defaults library
  - Calendar and music playback models

- **`/managers/`** - Business logic singletons
  - `MusicManager.swift` - Music playback control with strategy pattern
  - `CalendarManager.swift` - EventKit integration
  - `WebcamManager.swift` - Camera preview
  - `BatteryActivityManager.swift` - Battery notifications
  - `NotchSpaceManager.swift` - Window space management
  - `BoringExtensionManager.swift` - Extension system

- **`/components/`** - Reusable SwiftUI views
  - `/Notch/` - Core notch UI (NotchHomeView, NotchShelfView, BoringHeader)
  - `/Music/` - Visualizer and Lottie animations
  - `/Shelf/` - File management (TrayDrop, AirDrop)
  - `/Live activities/` - HUD elements (battery, downloads, system events)
  - `/Settings/` - Settings UI
  - `/Calendar/` - Calendar components
  - `/Webcam/` - Camera preview UI

- **`/MediaControllers/`** - Media playback abstraction
  - `MediaControllerProtocol.swift` - Controller interface
  - `AppleMusicController.swift`, `SpotifyController.swift`, `YouTubeMusicController.swift` - AppleScript-based controllers
  - `NowPlayingController.swift` - macOS Now Playing API (deprecated in 15.4+)

- **`/extensions/`** - Swift extensions (Button animations, pan gestures, keyboard shortcuts, NSImage)
- **`/helpers/`** - Utilities (AudioPlayer, AppleScriptHelper, MediaChecker)
- **`/observers/`** - System observers (fullscreen media detection)

### State Management

**Defaults Library** (`sindresorhus/Defaults`)
- Centralized preferences in `models/Constants.swift`
- Categories: General, Behavior, Appearance, Gestures, Media Playback, Battery, Downloads, HUD, Shelf, Calendar
- Access via `@Default(.keyName)` property wrapper or `Defaults[.keyName]`

**Published Properties & Combine**
- ViewModels use `@Published` for reactive updates
- Views observe with `@ObservedObject` or `@EnvironmentObject`
- NotificationCenter for cross-component communication

**BoringViewCoordinator Singleton**
- Manages current view state (`.home` or `.shelf`)
- Sneak peek system for HUD-style notifications
- Expanding views (battery/download notifications)
- Worker communication via `TheBoringWorkerNotifier`

### Multi-Screen Support

- The app can display on all screens simultaneously OR a single preferred screen (controlled by `Defaults[.showOnAllDisplays]`)
- AppDelegate manages separate `BoringNotchWindow` and `BoringViewModel` instances per screen
- Windows positioned dynamically at top-center of each display
- Screen lock/unlock events trigger window cleanup and repositioning

### Media Controller Strategy Pattern

The `MusicManager` uses a strategy pattern to support multiple music sources:

```swift
MediaControllerProtocol
    ├── AppleMusicController (AppleScript)
    ├── SpotifyController (AppleScript)
    ├── YouTubeMusicController (browser integration)
    └── NowPlayingController (macOS API, deprecated 15.4+)
```

Selection via `Defaults[.mediaController]` (enum: `.nowPlaying`, `.appleMusic`, `.spotify`, `.youtubeMusic`)

**Important**: macOS 15.4+ deprecated Now Playing API. The app gracefully falls back to Apple Music controller on newer systems.

### Window Management

- Custom `BoringNotchWindow` class extends NSWindow
- Windows use specific style masks for floating, non-activating behavior
- `NotchSpaceManager` prevents conflicts with other app windows
- Windows positioned relative to screen notch or menu bar depending on device

## Important Code Patterns

### AppleScript Integration

Music controllers use AppleScript for Apple Music and Spotify control:
- `AppleScriptHelper.swift` provides script execution utilities
- Controllers run scripts to get playback state, artwork, control playback
- Requires `com.apple.security.scripting-targets` entitlements

### Reactive Data Flow

Key data flows use Combine publishers:
```swift
MusicManager.shared.$currentArtwork
    .sink { artwork in /* update UI */ }
    .store(in: &cancellables)
```

### Entitlements & Permissions

Required entitlements in `boringNotch.entitlements`:
- App Sandbox enabled
- Camera access (`com.apple.security.device.camera`)
- Calendar access (`com.apple.security.personal-information.calendars`)
- Apple Events (`com.apple.security.scripting-targets.apple-events.com.apple.Music`, `.com.spotify.client`)
- Network client/server
- File access permissions

### Notch State Transitions

```
Closed → Open: hover, tap, gesture down, keyboard shortcut
Open → Closed: mouse exit, gesture up, keyboard shortcut, timeout
```

Special states:
- **Sneak peek**: Temporary HUD notifications (coordinator manages)
- **Expanding views**: Battery/download status
- **First launch**: Onboarding flow with HelloAnimation

## Dependencies (Swift Package Manager)

- **Sparkle** - Auto-update framework
- **LaunchAtLogin** - Login item management
- **KeyboardShortcuts** - Global shortcuts
- **Defaults** - Type-safe UserDefaults wrapper
- **SwiftUIIntrospect** - Access AppKit from SwiftUI
- **Collections** - Swift Collections
- **LottieUI** - Lottie animations
- **TheBoringWorkerNotifier** - Custom worker framework
- **MacroVisionKit** - Camera utilities

### System Frameworks

- SwiftUI, Combine, AVFoundation, EventKit, IOKit (battery info), AppKit
- MediaRemote.framework (private framework) - Custom adapter in `mediaremote-adapter/`

## Contributing Workflow

**Base branch**: `dev` (not `main`)

1. Fork and clone the repository
2. Create feature branch: `git checkout -b feature/descriptive-name` (lowercase, hyphens)
3. Make changes and commit
4. Push to fork and create PR against **`dev`** branch

## Common Development Scenarios

### Adding a New Settings Preference

1. Add key to `Defaults.Keys` extension in `models/Constants.swift`
2. Add UI control in appropriate settings view (`components/Settings/`)
3. Bind with `@Default(.yourKey)` property wrapper
4. Access in code via `Defaults[.yourKey]`

### Adding a New View to NotchLayout

1. Create view component in appropriate `/components/` subdirectory
2. Add view state to `BoringViewModel` if needed
3. Integrate into `ContentView.swift` NotchLayout logic
4. Consider coordinator integration for view transitions

### Supporting a New Music Service

1. Create new controller implementing `MediaControllerProtocol` in `/MediaControllers/`
2. Add enum case to `MediaControllerType` in `models/Constants.swift`
3. Update `MusicManager.swift` to initialize and switch to new controller
4. Add necessary AppleScript helpers or API integration
5. Update entitlements if scripting target access required

### Debugging Multi-Screen Issues

- Check `AppDelegate.adjustWindowPosition()` for window positioning logic
- Verify `Defaults[.showOnAllDisplays]` setting
- Review `viewModels` dictionary in AppDelegate (maps screens to ViewModels)
- Test screen lock/unlock events (`onScreenLocked`/`onScreenUnlocked`)

## Known Architecture Decisions

### Why Singletons for Managers?

Managers like `MusicManager`, `CalendarManager`, and `BoringViewCoordinator` use singletons because:
- They manage system-wide resources (music playback, calendar, window coordination)
- Multiple instances would cause conflicts (duplicate observers, racing updates)
- Accessed from multiple views across the app

### Why Strategy Pattern for Media Controllers?

- Supports multiple music services (Apple Music, Spotify, YouTube Music)
- Allows runtime switching without app restart
- Isolates service-specific implementation details
- Handles API deprecations gracefully (Now Playing → Apple Music fallback)

### Why Defaults Library vs UserDefaults?

- Type-safety: Compile-time checking of keys and values
- Observation: Built-in Combine publisher support
- Defaults: Cleaner syntax than UserDefaults with default values
- Serialization: Protocol-based serialization for custom types

## Testing

Currently, the project does not have a dedicated test target. Development testing is manual through Xcode's Run command.

## Update System

The app uses **Sparkle** for auto-updates:
- Update feed: `https://TheBoredTeam.github.io/boring.notch/appcast.xml`
- Configuration in `Info.plist` and `Configuration/sparkle/`
- Update checks managed by `SPUStandardUpdaterController`
- Release process automated via `.github/workflows/release.yml`

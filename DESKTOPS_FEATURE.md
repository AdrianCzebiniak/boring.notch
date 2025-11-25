# Desktops Feature Implementation

## Overview

The Desktops feature allows you to configure custom names for each macOS Space/Desktop and displays the current desktop name in the notch. The name updates automatically when you switch between desktops.

## Files Added

1. **`boringNotch/managers/DesktopManager.swift`**
   - Singleton manager that tracks the active desktop using CGSGetActiveSpace
   - Observes `NSWorkspace.activeSpaceDidChangeNotification` for desktop switches
   - Manages desktop name storage and retrieval via Defaults
   - Posts `desktopDidChange` notification when desktop switches
   - Published properties:
     - `currentSpaceID`: Current Space ID
     - `currentSpaceName`: Current desktop name

2. **`boringNotch/components/Notch/DesktopNameView.swift`**
   - SwiftUI view component that displays the desktop name
   - Shows a capsule-styled label with the current desktop name
   - Uses opacity fade transition when space changes
   - Applies `.id()` modifier to force view recreation on space changes
   - Only visible when `showDesktopName` setting is enabled

3. **`boringNotch/components/Settings/DesktopSettings.swift`**
   - Settings panel for configuring desktop names
   - Shows current desktop Space ID and name
   - Allows adding, editing, and removing desktop names
   - Quick action to name the current desktop

## Files Modified

1. **`boringNotch/private/CGSSpace.swift`**
   - Added `CGSGetActiveSpace` function declaration to get the active Space ID

2. **`boringNotch/models/Constants.swift`**
   - Added `desktopNames` key: `Key<[String: String]>` - Dictionary mapping Space IDs to names
   - Added `showDesktopName` key: `Key<Bool>` (default: `true`) - Toggle to show/hide desktop name in notch
   - Added `desktopNameAutoExpandOnNotch` key: `Key<Bool>` (default: `true`) - Auto-expand notch on desktop switch for notched screens
   - Added `desktopNameAutoHideDelay` key: `Key<Double>` (default: `2.0`) - Delay in seconds before auto-closing expanded notch

3. **`boringNotch/ContentView.swift`**
   - Added overlay to main VStack to display `DesktopNameView` when notch is closed
   - Ensures desktop name is always visible at the top of the notch

4. **`boringNotch/components/Notch/BoringHeader.swift`**
   - Integrated `DesktopNameView` component with smart positioning
   - During peek on notched screens: Shows desktop name on LEFT (avoids physical notch)
   - During peek on non-notched screens: Shows desktop name in CENTER
   - During full open: Shows desktop name in CENTER above notch shape

5. **`boringNotch/components/Settings/SettingsView.swift`**
   - Added "Desktops" navigation link with system icon "macwindow.on.rectangle"
   - Added case for "Desktops" in the detail view switch statement

6. **`boringNotch/boringNotchApp.swift`**
   - Initialized `DesktopManager.shared` in `applicationDidFinishLaunching`
   - Ensures desktop tracking starts when the app launches
   - Added observer for `desktopDidChange` notification
   - Implements auto-peek logic with `temporarilyExpandNotch()` method
   - Detects notched screens and triggers peek on desktop switch

7. **`boringNotch/enums/generic.swift`**
   - Added `.peek` case to `NotchState` enum for partial expansion

8. **`boringNotch/sizing/matters.swift`**
   - Added `peekNotchSize` constant (640x60) for partial expansion

9. **`boringNotch/models/BoringViewModel.swift`**
   - Added `peek()` method to trigger small expansion (60px height)

10. **`boringNotch/ContentView.swift`**
    - Updated to handle `.peek` state alongside `.open` and `.closed`
    - Modified hover logic to prevent full expansion during peek
    - Peek state shows BoringHeader (which displays only desktop name)

## How It Works

### Architecture Flow

```
App Launch
    ↓
DesktopManager.shared initialized
    ↓
Observes NSWorkspace.activeSpaceDidChangeNotification
    ↓
On desktop switch:
  1. CGSGetActiveSpace() called
  2. currentSpaceID updated
  3. currentSpaceName updated from Defaults
  4. DesktopNameView automatically updates with fade transition (via @Published)
```

### Transition Animation

When switching between desktops, the desktop name smoothly fades to the new name with a 0.2 second opacity transition.

### Auto-Peek on Notched Screens

**Problem**: On MacBooks with a physical notch, the desktop name displayed at the top of the notch gets hidden by the hardware notch itself.

**Solution**: The app can automatically "peek" (small expansion) when you switch desktops on notched screens:

1. When you switch desktops, the notch automatically peeks (expands to 60px height instead of fully opening)
2. **On notched screens**: Desktop name appears on the LEFT side (clear of the physical notch)
3. **On non-notched screens**: Desktop name appears in the CENTER (stays in place)
4. After a configurable delay (default: 2 seconds), the notch automatically closes back to normal
5. This only happens on screens with a physical notch (detected via `safeAreaInsets.top > 0`)
6. Can be toggled on/off in settings
7. Auto-hide delay is configurable (0.5 to 5.0 seconds)
8. During peek, hovering won't trigger full expansion - it just auto-closes after the delay

**Technical Details**:
- Added new `.peek` state to `NotchState` enum
- Peek size is 60px height (vs 32-37px closed, 190px fully open)
- BoringHeader dynamically positions desktop name:
  - **Peek + notched screen**: Left-aligned (avoids physical notch)
  - **Peek + non-notched screen**: Center-aligned
  - **Fully open**: Center-aligned with notch shape
- Side buttons (settings, battery) hidden during peek
- Hover interactions disabled during peek to prevent accidental full expansion

### Data Flow

- **Storage**: Desktop names stored as `[String: String]` in UserDefaults via Defaults library
- **Key Format**: Space ID (as String) → Desktop Name
- **Default Names**: If no custom name exists, shows "Desktop N" where N is determined by space order

## Usage Instructions

1. **Feature is Enabled by Default**
   - The desktop name is shown by default in the notch (both open and closed states)
   - You can toggle it off in Settings → Desktops if desired

2. **Name Your Current Desktop**
   - Go to Settings → Desktops
   - Click "Set Name for Current Desktop"
   - Enter a name (e.g., "Work", "Personal", "Development")
   - Click Save

3. **Name Other Desktops**
   - Switch to a different desktop (swipe with 3 fingers or Ctrl+Arrow)
   - Return to Settings → Desktops
   - Click "Set Name for Current Desktop" again
   - Repeat for each desktop

4. **View Desktop Name**
   - The desktop name is always visible in the notch (both when open and closed)
   - When closed: appears as an overlay at the top of the notch
   - When open: appears above the notch shape in the header
   - Switch desktops and watch it update in real-time

## Testing Checklist

- [ ] Build the project successfully in Xcode
- [ ] App launches without crashes
- [ ] DesktopManager initializes correctly
- [ ] Settings → Desktops panel appears in sidebar
- [ ] Can toggle "Show Desktop Name" setting
- [ ] Can see current Space ID in settings
- [ ] Can set name for current desktop
- [ ] Desktop name appears in notch (both when open and closed)
- [ ] Desktop name is visible by default
- [ ] Switching desktops updates the name automatically
- [ ] Desktop name fades smoothly when switching spaces
- [ ] Transition is smooth and performant
- [ ] Can edit existing desktop names
- [ ] Can delete desktop names
- [ ] Multiple desktops can have different names

## Known Considerations

1. **Private API Usage**: Uses `CGSGetActiveSpace`, an undocumented Apple private API
   - Already used pattern in the codebase (CGSSpace.swift)
   - May change in future macOS versions
   - Standard for Space-related functionality in third-party apps

2. **Space ID Persistence**: macOS Space IDs may change after:
   - System restart
   - Mission Control settings changes
   - Desktop reordering
   - Users may need to reconfigure names after such changes

3. **Multi-Display**: Each physical display has its own Spaces
   - The feature tracks the active Space across all displays
   - May need enhancement for display-specific naming

## Future Enhancements

- Auto-detect and suggest names based on active applications
- Import/export desktop name configurations
- Per-display desktop naming
- Integration with Mission Control visual indicators
- Keyboard shortcut to quickly rename current desktop
- Desktop switching controls in the notch

## Troubleshooting

**Desktop name not updating**
- Check that "Show Desktop Name" is enabled in settings
- Verify DesktopManager initialized (check logs)
- Ensure NSWorkspace notification observer is active

**Space ID keeps changing**
- This is normal macOS behavior after restarts
- Simply re-set names for desktops after system changes

**Name not visible in notch**
- Ensure notch is open (hover or tap)
- Check that `showDesktopName` default is true
- Verify DesktopNameView is included in BoringHeader

## Code Integration Points

### To Add Desktop Name to Other Views

```swift
// Import and observe
@ObservedObject var desktopManager = DesktopManager.shared

// Use in view
Text(desktopManager.currentSpaceName)
```

### To Programmatically Set Desktop Name

```swift
DesktopManager.shared.setDesktopName("My Desktop", forSpaceID: spaceID)
```

### To Get All Configured Desktops

```swift
let desktops = DesktopManager.shared.getAllDesktops()
// Returns: [(spaceID: String, name: String)]
```

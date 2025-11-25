# Next Event in Notch Feature

## Overview

This feature displays the next upcoming calendar event for today directly in the notch when it's closed, similar to the music live activity. Users can toggle this feature on/off in the Calendar settings.

## Files Added

1. **`boringNotch/components/Calendar/NextEventView.swift`**
   - SwiftUI component that displays the next upcoming event in the notch
   - Shows event title, time, and calendar color indicator
   - Follows the same design pattern as `MusicLiveActivity`
   - Includes hover animation for visual feedback

## Files Modified

1. **`boringNotch/models/Constants.swift`**
   - Added `showNextEventInNotch` key: `Key<Bool>` (default: `true`)
   - Controls whether to show the next event in the notch when closed

2. **`boringNotch/managers/CalendarManager.swift`**
   - Added `@Published var nextUpcomingEvent: EventModel?` property
   - Added `updateNextUpcomingEvent()` method to compute the next upcoming event
   - Added automatic timer that refreshes every minute to handle events that have started
   - Integrated update calls in all event refresh locations:
     - `updateEvents()`
     - `checkCalendarAuthorization()`
     - `setReminderCompleted()`

3. **`boringNotch/ContentView.swift`**
   - Added conditional display logic for `NextEventView`
   - Shows when notch is closed, music is not playing, and there's an upcoming event today
   - Priority: Battery/HUD notifications → Music → Next Event → Boring Face

4. **`boringNotch/components/Settings/SettingsView.swift`**
   - Added toggle for "Show next event in notch" in Calendar settings
   - Includes help tooltip explaining the feature

## How It Works

### Event Selection Logic

The `updateNextUpcomingEvent()` method:
1. Filters all events to find those happening **today**
2. Filters to only **upcoming** events (start time >= now)
3. Filters out completed reminders (based on `hideCompletedReminders` setting)
4. Sorts by start time and selects the **earliest** one
5. Updates the `@Published nextUpcomingEvent` property

### Display Priority in Notch (when closed)

The notch displays items in this priority order:
1. Battery notifications (when plugged/unplugged)
2. System HUD (inline mode)
3. Music Live Activity (when music is playing)
4. **Next Event** (when no music and event exists) ← **New**
5. Boring Face animation (when enabled and nothing else to show)
6. Empty space

### Auto-Refresh

A timer runs every 60 seconds to:
- Recalculate which event is "next"
- Handle events that have started (and are now in the past)
- Automatically show the new next event

### Visual Design

The NextEventView displays:
- **Left side**: Vertical color bar (calendar color)
- **Center**: Event title (truncated if too long)
- **Right side**: Clock icon + event time
- **Hover effect**: Expands slightly when mouse hovers over it

## Usage

### Enable/Disable

1. Open **Settings → Calendar**
2. Toggle "Show next event in notch"
3. The setting takes effect immediately

### What Shows

- **Only today's events**: Events from other days are not shown
- **Only upcoming**: Past events from today are not shown
- **Only when music isn't playing**: Music takes priority
- **Respects calendar permissions**: Requires Calendar access
- **Respects calendar selection**: Only shows events from enabled calendars

## Example Scenarios

### Scenario 1: Morning with upcoming meetings
- Time: 9:00 AM
- Events today: 10:00 AM Team Meeting, 2:00 PM Client Call
- **Shown**: "Team Meeting • 10:00 AM"

### Scenario 2: After first meeting starts
- Time: 10:05 AM (Team Meeting in progress)
- Events today: 10:00 AM Team Meeting, 2:00 PM Client Call
- **Shown**: "Client Call • 2:00 PM" (automatically updated)

### Scenario 3: Music playing
- Time: 9:00 AM
- Music: Playing
- Events today: 10:00 AM Team Meeting
- **Shown**: Music Live Activity (event hidden, music takes priority)

### Scenario 4: No upcoming events
- Time: 5:00 PM
- All events today have passed
- **Shown**: Boring Face animation (if enabled) or empty

### Scenario 5: Event on different day
- Time: 9:00 AM (Monday)
- Events: 10:00 AM Tuesday Meeting
- **Shown**: Nothing (only shows today's events)

## Settings Location

**Settings → Calendar → "Show next event in notch"**

## Technical Details

### Performance

- Timer updates only every 60 seconds (minimal CPU usage)
- Event filtering is done in-memory (fast)
- Only active when calendar access is granted
- Disabled when setting is toggled off

### State Management

- Uses `@Published` property for reactive UI updates
- Integrates with existing `CalendarManager` singleton
- Respects `Defaults` for persistent toggle state

### Integration Points

Works seamlessly with:
- Calendar permission system
- Calendar selection (only shows events from selected calendars)
- Hide completed reminders setting
- Music Live Activity (respects priority)
- Notch open/close states

## Future Enhancements

Potential improvements:
- Show countdown to event start time
- Tap to open Calendar app to that event
- Show multiple upcoming events (scrollable)
- Include events from tomorrow if no events today
- Customizable time window (e.g., "next 2 hours" instead of "today")
- Visual indicator for events starting soon (< 15 min)
- Integration with meeting links (show Join button)

## Testing Checklist

- [ ] Build the project successfully
- [ ] Toggle shows/hides next event in notch
- [ ] Next event displays when notch is closed
- [ ] Event updates when timer fires
- [ ] Past events don't show
- [ ] Future events from other days don't show
- [ ] Music takes priority over event display
- [ ] Hover effect works correctly
- [ ] Calendar color shows correctly
- [ ] Event title truncates properly if too long
- [ ] Time displays in correct format
- [ ] Works with multiple calendars
- [ ] Respects calendar selection
- [ ] Handles no events gracefully
- [ ] Timer cleans up on app quit

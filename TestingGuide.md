<!--
TestingGuide.md
InterviewMonitor

Comprehensive testing documentation and procedures

FUNCTIONS:
- Provides step-by-step testing procedures for all detection types
- Documents expected console output examples for debugging
- Covers different detection scenarios (screenshots, overlays, processes)
- Includes permission setup instructions for macOS
- Explains debugging tips and console monitoring techniques
- Details testing workflow from build to verification
- Lists critical behaviors and expected responses

Created by WingLik Choi on 7/16/25.
-->

# Testing Overlay Detection

## Build Setup
1. Open `InterviewMonitor.xcodeproj` in Xcode
2. Grant Screen Recording permission when prompted
3. Build and run (⌘+R)

## Quick Test Steps
1. Build and run in Xcode (⌘+R)
2. Enter session ID: "test123"
3. Click "Start Interview" → Window disappears
4. Open QuickTime → New Screen Recording
5. **Expected**: App window pops back up with "Cheating Detected" alert
6. Click "Close Application" → App self-destructs

## Detailed Testing Steps

### 1. Basic Setup
```
1. Enter a session ID (e.g., "test123")
2. Click "Start Interview"
3. Window will hide - monitoring begins
```

### 2. Screen Recording Test
```
1. Open QuickTime Player
2. File → New Screen Recording
3. Click record button
Expected: Firebase alert with type "screen_recording"
```

### 3. Video Conferencing Test
```
1. Join Zoom/Teams meeting
2. Share screen
Expected: Firebase alert with type "screen_recording"
```

### 4. OBS/Streaming Test
```
1. Open OBS Studio
2. Add "Display Capture" source
3. Start streaming/recording
Expected: Firebase alert with type "suspicious_overlay"
```

### 5. InterviewCoder Detection Test
```
1. Download and run InterviewCoder app
2. Use keyboard shortcuts (⌘+B, ⌘+H) to show overlay
Expected: Firebase alert with type "coding_interview_tool"
```

### 6. Coding Assistant Detection Test
```
1. Open any coding assistant (Copilot, ChatGPT coding interface)
2. Position as small floating window
3. Try to hide in screen corners
Expected: Firebase alert with type "coding_interview_tool"
```

### 7. Screenshot Detection Test
```
1. Press ⌘+Shift+3 (full screen screenshot)
2. Press ⌘+Shift+4 (selection screenshot)
3. Press ⌘+Shift+5 (screenshot app)
Expected: Firebase alert with type "screenshot_detected"
```

### 8. Process Blacklist Test
```
1. Open ChatGPT/Claude (if installed)
2. App should detect and self-destruct
Expected: App terminates via cleaner
```

## Monitoring Results

### Local Console Output
All alerts are logged to the Xcode console with detailed information:

### Sample Alert Output
```
=== OVERLAY ALERT ===
Session ID: test123
Type: screen_recording
Details: Screen recording/sharing detected: QuickTime Player
Window Info: {
  "window_id": 123,
  "process_name": "QuickTime Player",
  "window_title": "Screen Recording",
  "window_layer": 5,
  "bounds": {"x": 100, "y": 100, "width": 800, "height": 600}
}
Timestamp: 1642694400.123
====================
```

## Debug Console Output
Check Xcode console for:
```
"Overlay detection started"
"Overlay detected: screenRecording - Screen recording/sharing detected: QuickTime Player"
=== OVERLAY ALERT ===
[Detailed alert information]
```

## Testing Permissions
If detection fails, check:
- System Preferences → Security & Privacy → Screen Recording
- Grant permission to InterviewMonitor
- Restart app after granting permissions

## False Positive Testing
Normal apps that should NOT trigger alerts:
- Finder windows
- Safari/Chrome
- Text editors
- System preferences
- Dock/menu bar

## Critical Overlay Behavior
These trigger immediate app termination:
- `suspicious_overlay` 
- `screen_recording`
- `coding_interview_tool` (InterviewCoder detection)
- `screenshot_detected` (NEW: Screenshot detection)

Non-critical overlays log but don't terminate:
- `layer_anomaly`
- `transparent_overlay`
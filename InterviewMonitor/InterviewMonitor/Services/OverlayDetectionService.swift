/*
 * OverlayDetectionService.swift
 * InterviewMonitor
 *
 * Core detection engine that monitors for cheating attempts in real-time
 * 
 * FUNCTIONS:
 * - Detects screen overlays (InterviewCoder, OBS, coding assistants, etc.)
 * - Monitors for screenshot keyboard shortcuts (⌘+Shift+3/4/5)
 * - Watches Desktop folder for new screenshot files using file system events
 * - Identifies coding interview tools and screen recording applications
 * - Runs continuous window monitoring every 1 second
 * - Uses Core Graphics APIs to scan all visible windows and their properties
 * - Detects suspicious overlay patterns, window layers, and positioning
 * - Provides delegate callbacks for detection events
 * - Handles permission checking for screen recording access
 *
 * Created by WingLik Choi on 7/16/25.
 */

import Foundation
import CoreGraphics
import ApplicationServices
import Cocoa

class OverlayDetectionService {
    private var monitorTimer: Timer?
    private var previousWindowList: [WindowInfo] = []
    private var isMonitoring = false
    private var keyboardMonitor: Any?
    private var screenshotFileWatcher: DispatchSourceFileSystemObject?
    
    weak var delegate: OverlayDetectionDelegate?
    
    struct WindowInfo {
        let windowID: CGWindowID
        let processName: String
        let windowTitle: String
        let windowLayer: Int
        let bounds: CGRect
        let isOnScreen: Bool
        let ownerPID: pid_t
    }
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        // Check for required permissions
        guard hasScreenRecordingPermission() else {
            delegate?.overlayDetectionDidFail(error: .permissionDenied)
            return
        }
        
        isMonitoring = true
        
        // Monitor every 1 second for overlay detection
        monitorTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.checkForOverlays()
        }
        
        // Start screenshot detection
        startScreenshotDetection()
        
        delegate?.overlayDetectionDidStart()
    }
    
    func stopMonitoring() {
        isMonitoring = false
        monitorTimer?.invalidate()
        monitorTimer = nil
        
        // Stop screenshot detection
        stopScreenshotDetection()
        
        delegate?.overlayDetectionDidStop()
    }
    
    private func checkForOverlays() {
        let currentWindows = getAllWindows()
        
        // Check for suspicious overlay patterns
        detectSuspiciousOverlays(windows: currentWindows)
        
        // Check for window layer anomalies
        detectLayerAnomalies(windows: currentWindows)
        
        // Check for transparent overlays
        detectTransparentOverlays(windows: currentWindows)
        
        // Check for screen recording/sharing
        detectScreenRecording(windows: currentWindows)
        
        previousWindowList = currentWindows
    }
    
    private func getAllWindows() -> [WindowInfo] {
        guard let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
            return []
        }
        
        var windows: [WindowInfo] = []
        
        for windowDict in windowList {
            guard let windowID = windowDict[kCGWindowNumber as String] as? CGWindowID,
                  let ownerPID = windowDict[kCGWindowOwnerPID as String] as? pid_t,
                  let boundsDict = windowDict[kCGWindowBounds as String] as? [String: Any],
                  let isOnScreen = windowDict[kCGWindowIsOnscreen as String] as? Bool else {
                continue
            }
            
            let processName = windowDict[kCGWindowOwnerName as String] as? String ?? "Unknown"
            let windowTitle = windowDict[kCGWindowName as String] as? String ?? ""
            let windowLayer = windowDict[kCGWindowLayer as String] as? Int ?? 0
            
            let bounds = CGRect(
                x: boundsDict["X"] as? CGFloat ?? 0,
                y: boundsDict["Y"] as? CGFloat ?? 0,
                width: boundsDict["Width"] as? CGFloat ?? 0,
                height: boundsDict["Height"] as? CGFloat ?? 0
            )
            
            let windowInfo = WindowInfo(
                windowID: windowID,
                processName: processName,
                windowTitle: windowTitle,
                windowLayer: windowLayer,
                bounds: bounds,
                isOnScreen: isOnScreen,
                ownerPID: ownerPID
            )
            
            windows.append(windowInfo)
        }
        
        return windows
    }
    
    private func detectSuspiciousOverlays(windows: [WindowInfo]) {
        let suspiciousPatterns = [
            "overlay", "transparent", "floating", "popup", "modal",
            "screen", "capture", "record", "share", "cast"
        ]
        
        // Enhanced patterns for coding interview cheating tools
        let codingInterviewPatterns = [
            "interviewcoder", "interview coder", "coder", "leetcode", "hackerrank",
            "codility", "codesignal", "pramp", "interviewing", "coding assistant",
            "ai assistant", "copilot", "chatgpt", "claude", "bard", "gemini",
            "solution", "solver", "hint", "helper", "cheat", "auto", "generate"
        ]
        
        for window in windows {
            let windowTitleLower = window.windowTitle.lowercased()
            let processNameLower = window.processName.lowercased()
            let combinedText = "\(windowTitleLower) \(processNameLower)"
            
            // Check standard suspicious patterns
            for pattern in suspiciousPatterns {
                if windowTitleLower.contains(pattern) || processNameLower.contains(pattern) {
                    if window.windowLayer > 0 || isWindowSuspiciouslyPositioned(window) {
                        delegate?.overlayDetected(
                            type: .suspiciousOverlay,
                            details: "Suspicious overlay detected: \(window.processName) - \(window.windowTitle)",
                            window: window
                        )
                    }
                }
            }
            
            // Check coding interview specific patterns
            for pattern in codingInterviewPatterns {
                if combinedText.contains(pattern) {
                    delegate?.overlayDetected(
                        type: .codingInterviewTool,
                        details: "Coding interview tool detected: \(window.processName) - \(window.windowTitle)",
                        window: window
                    )
                }
            }
            
        }
    }
    
    private func detectLayerAnomalies(windows: [WindowInfo]) {
        let highLayerWindows = windows.filter { $0.windowLayer > 20 }
        
        for window in highLayerWindows {
            if !isKnownSystemWindow(window) {
                delegate?.overlayDetected(
                    type: .layerAnomaly,
                    details: "High layer window detected: \(window.processName) at layer \(window.windowLayer)",
                    window: window
                )
            }
        }
    }
    
    private func detectTransparentOverlays(windows: [WindowInfo]) {
        for window in windows {
            // Check for windows that might be transparent overlays
            if window.bounds.width > 500 && window.bounds.height > 300 {
                // Large windows that might be overlays
                if window.windowTitle.isEmpty && window.windowLayer > 0 {
                    delegate?.overlayDetected(
                        type: .transparentOverlay,
                        details: "Potential transparent overlay: \(window.processName)",
                        window: window
                    )
                }
            }
        }
    }
    
    private func detectScreenRecording(windows: [WindowInfo]) {
        let screenRecordingKeywords = [
            "screen recording", "quicktime", "obs", "screencast", "zoom", "teams",
            "meet", "webex", "skype", "discord", "slack", "loom", "camtasia"
        ]
        
        for window in windows {
            let combinedText = "\(window.processName) \(window.windowTitle)".lowercased()
            
            for keyword in screenRecordingKeywords {
                if combinedText.contains(keyword) {
                    delegate?.overlayDetected(
                        type: .screenRecording,
                        details: "Screen recording/sharing detected: \(window.processName)",
                        window: window
                    )
                }
            }
        }
    }
    
    private func isWindowSuspiciouslyPositioned(_ window: WindowInfo) -> Bool {
        let screenBounds = NSScreen.main?.frame ?? CGRect.zero
        
        // Check if window is positioned to cover significant screen area
        let coverageRatio = (window.bounds.width * window.bounds.height) / (screenBounds.width * screenBounds.height)
        
        return coverageRatio > 0.7 && window.windowLayer > 0
    }
    
    
    private func isKnownSystemWindow(_ window: WindowInfo) -> Bool {
        let knownSystemProcesses = [
            "WindowServer", "Dock", "SystemUIServer", "ControlCenter",
            "NotificationCenter", "Spotlight", "Finder"
        ]
        
        return knownSystemProcesses.contains(window.processName)
    }
    
    private func hasScreenRecordingPermission() -> Bool {
        // Check if we can access window list - this indicates screen recording permission
        let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID)
        return windowList != nil
    }
    
    // MARK: - Screenshot Detection
    
    private func startScreenshotDetection() {
        // Monitor keyboard shortcuts for screenshots
        startKeyboardMonitoring()
        
        // Monitor Desktop folder for new screenshot files
        startDesktopFileMonitoring()
        
        // Monitor screenshot-related processes
        // (This is handled in the main overlay detection)
    }
    
    private func stopScreenshotDetection() {
        // Stop keyboard monitoring
        if let monitor = keyboardMonitor {
            NSEvent.removeMonitor(monitor)
            keyboardMonitor = nil
        }
        
        // Stop file monitoring
        screenshotFileWatcher?.cancel()
        screenshotFileWatcher = nil
    }
    
    private func startKeyboardMonitoring() {
        keyboardMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { event in
            self.checkForScreenshotKeyboardShortcuts(event)
        }
    }
    
    private func checkForScreenshotKeyboardShortcuts(_ event: NSEvent) {
        let modifierFlags = event.modifierFlags
        let keyCode = event.keyCode
        
        // Check for screenshot shortcuts
        let hasCommand = modifierFlags.contains(.command)
        let hasShift = modifierFlags.contains(.shift)
        
        if hasCommand && hasShift {
            // ⌘+Shift+3 (Full screen screenshot) - keyCode 19 (3)
            // ⌘+Shift+4 (Selection screenshot) - keyCode 21 (4)
            // ⌘+Shift+5 (Screenshot app) - keyCode 23 (5)
            if keyCode == 19 || keyCode == 21 || keyCode == 23 {
                delegate?.overlayDetected(
                    type: .screenshotDetected,
                    details: "Screenshot keyboard shortcut detected: ⌘+Shift+\(keyCode == 19 ? "3" : keyCode == 21 ? "4" : "5")",
                    window: createDummyWindowInfo(processName: "System Screenshot")
                )
            }
        }
    }
    
    private func startDesktopFileMonitoring() {
        let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        let desktopPath = desktopURL.path
        
        let fileDescriptor = open(desktopPath, O_EVTONLY)
        guard fileDescriptor != -1 else { return }
        
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: .write,
            queue: DispatchQueue.main
        )
        
        source.setEventHandler { [weak self] in
            self?.checkForNewScreenshotFiles()
        }
        
        source.setCancelHandler {
            close(fileDescriptor)
        }
        
        source.resume()
        screenshotFileWatcher = source
    }
    
    private func checkForNewScreenshotFiles() {
        let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: desktopURL, includingPropertiesForKeys: [.creationDateKey], options: [.skipsHiddenFiles])
            
            let recentScreenshots = files.filter { url in
                // Look for screenshot files created in the last 5 seconds
                let filename = url.lastPathComponent
                let isScreenshot = filename.hasPrefix("Screenshot") || filename.hasPrefix("Screen Shot")
                
                if isScreenshot {
                    do {
                        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                        if let creationDate = attributes[.creationDate] as? Date {
                            let timeSinceCreation = Date().timeIntervalSince(creationDate)
                            return timeSinceCreation < 5.0 // Created within last 5 seconds
                        }
                    } catch {
                        return false
                    }
                }
                return false
            }
            
            for screenshot in recentScreenshots {
                delegate?.overlayDetected(
                    type: .screenshotDetected,
                    details: "Screenshot file detected: \(screenshot.lastPathComponent)",
                    window: createDummyWindowInfo(processName: "System Screenshot")
                )
            }
        } catch {
            print("Error checking for screenshot files: \(error)")
        }
    }
    
    private func createDummyWindowInfo(processName: String) -> WindowInfo {
        return WindowInfo(
            windowID: 0,
            processName: processName,
            windowTitle: "Screenshot Detection",
            windowLayer: 0,
            bounds: CGRect.zero,
            isOnScreen: true,
            ownerPID: 0
        )
    }
}

// MARK: - Overlay Detection Delegate
protocol OverlayDetectionDelegate: AnyObject {
    func overlayDetectionDidStart()
    func overlayDetectionDidStop()
    func overlayDetectionDidFail(error: OverlayDetectionError)
    func overlayDetected(type: OverlayType, details: String, window: OverlayDetectionService.WindowInfo)
}

enum OverlayType {
    case suspiciousOverlay
    case layerAnomaly
    case transparentOverlay
    case screenRecording
    case codingInterviewTool
    case screenshotDetected
}

enum OverlayDetectionError: Error {
    case permissionDenied
    case systemError
    case unknown
}
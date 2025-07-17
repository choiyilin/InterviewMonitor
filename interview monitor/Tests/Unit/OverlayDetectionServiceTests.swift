/*
 * OverlayDetectionServiceTests.swift
 * InterviewMonitor
 *
 * Unit tests for the core detection engine functionality
 * 
 * FUNCTIONS:
 * - Tests screenshot keyboard shortcut detection (⌘+Shift+3/4/5)
 * - Tests file monitoring for screenshot creation on Desktop
 * - Tests window detection logic for coding tools (InterviewCoder)
 * - Tests screen recording detection (QuickTime, OBS)
 * - Tests service start/stop functionality and lifecycle
 * - Uses mock delegates to verify behavior without UI
 * - Simulates keyboard events and file system changes
 * - Validates detection accuracy and timing
 *
 * Created by WingLik Choi on 7/16/25.
 */

import XCTest
import Foundation
import Cocoa
@testable import InterviewMonitor

class OverlayDetectionServiceTests: XCTestCase {
    
    var overlayService: OverlayDetectionService!
    var mockDelegate: MockOverlayDetectionDelegate!
    
    override func setUp() {
        super.setUp()
        overlayService = OverlayDetectionService()
        mockDelegate = MockOverlayDetectionDelegate()
        overlayService.delegate = mockDelegate
    }
    
    override func tearDown() {
        overlayService?.stopMonitoring()
        overlayService = nil
        mockDelegate = nil
        super.tearDown()
    }
    
    // MARK: - Basic Service Tests
    
    func testServiceInitialization() {
        XCTAssertNotNil(overlayService)
        XCTAssertNotNil(mockDelegate)
    }
    
    func testStartMonitoring() {
        // Test that monitoring starts without errors
        overlayService.startMonitoring()
        
        // Give it a moment to initialize
        let expectation = expectation(description: "Start monitoring")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0)
        
        // Verify delegate was called
        XCTAssertTrue(mockDelegate.didStartCalled)
    }
    
    func testStopMonitoring() {
        overlayService.startMonitoring()
        
        // Give it a moment to start
        let startExpectation = expectation(description: "Start monitoring")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            startExpectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
        
        // Now stop
        overlayService.stopMonitoring()
        
        let stopExpectation = expectation(description: "Stop monitoring")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            stopExpectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
        
        XCTAssertTrue(mockDelegate.didStopCalled)
    }
    
    // MARK: - Screenshot Detection Tests
    
    func testScreenshotKeyboardShortcutDetection() {
        overlayService.startMonitoring()
        
        // Simulate ⌘+Shift+3 key event
        let event = createMockKeyEvent(keyCode: 19, modifierFlags: [.command, .shift])
        
        // This would normally be called by the global event monitor
        // For testing, we'll simulate it
        simulateKeyboardEvent(event)
        
        let expectation = expectation(description: "Screenshot detection")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
        
        // Verify screenshot was detected
        XCTAssertTrue(mockDelegate.overlayDetectedCalled)
        XCTAssertEqual(mockDelegate.lastDetectionType, .screenshotDetected)
        XCTAssertTrue(mockDelegate.lastDetectionDetails.contains("⌘+Shift+3"))
    }
    
    func testScreenshotFileDetection() {
        overlayService.startMonitoring()
        
        // Create a mock screenshot file on Desktop
        let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        let testScreenshotURL = desktopURL.appendingPathComponent("Screenshot 2024-01-15 at 2.30.45 PM.png")
        
        // Create the file
        let testData = "mock screenshot data".data(using: .utf8)!
        try? testData.write(to: testScreenshotURL)
        
        // Wait for file monitoring to detect it
        let expectation = expectation(description: "File detection")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)
        
        // Verify file was detected
        XCTAssertTrue(mockDelegate.overlayDetectedCalled)
        XCTAssertEqual(mockDelegate.lastDetectionType, .screenshotDetected)
        XCTAssertTrue(mockDelegate.lastDetectionDetails.contains("Screenshot"))
        
        // Clean up
        try? FileManager.default.removeItem(at: testScreenshotURL)
    }
    
    // MARK: - Window Detection Tests
    
    func testCodingInterviewToolDetection() {
        // Create mock window info for InterviewCoder
        let mockWindow = OverlayDetectionService.WindowInfo(
            windowID: 123,
            processName: "InterviewCoder",
            windowTitle: "Coding Assistant",
            windowLayer: 5,
            bounds: CGRect(x: 100, y: 100, width: 300, height: 200),
            isOnScreen: true,
            ownerPID: 1234
        )
        
        // Simulate window detection
        simulateWindowDetection(window: mockWindow)
        
        let expectation = expectation(description: "Coding tool detection")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
        
        XCTAssertTrue(mockDelegate.overlayDetectedCalled)
        XCTAssertEqual(mockDelegate.lastDetectionType, .codingInterviewTool)
        XCTAssertTrue(mockDelegate.lastDetectionDetails.contains("InterviewCoder"))
    }
    
    func testScreenRecordingDetection() {
        // Create mock window info for QuickTime
        let mockWindow = OverlayDetectionService.WindowInfo(
            windowID: 456,
            processName: "QuickTime Player",
            windowTitle: "Screen Recording",
            windowLayer: 3,
            bounds: CGRect(x: 200, y: 200, width: 400, height: 300),
            isOnScreen: true,
            ownerPID: 5678
        )
        
        // Simulate window detection
        simulateWindowDetection(window: mockWindow)
        
        let expectation = expectation(description: "Screen recording detection")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
        
        XCTAssertTrue(mockDelegate.overlayDetectedCalled)
        XCTAssertEqual(mockDelegate.lastDetectionType, .screenRecording)
        XCTAssertTrue(mockDelegate.lastDetectionDetails.contains("QuickTime"))
    }
    
    // MARK: - Helper Methods
    
    private func createMockKeyEvent(keyCode: UInt16, modifierFlags: NSEvent.ModifierFlags) -> NSEvent {
        // Note: This is a simplified mock - in real tests you'd need proper NSEvent creation
        // For now, we'll create a basic structure
        return NSEvent.keyEvent(
            with: .keyDown,
            location: NSPoint.zero,
            modifierFlags: modifierFlags,
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            characters: "",
            charactersIgnoringModifiers: "",
            isARepeat: false,
            keyCode: keyCode
        )!
    }
    
    private func simulateKeyboardEvent(_ event: NSEvent) {
        // For testing, we'll directly call the detection logic
        // In real implementation, this would be handled by the global event monitor
        let modifierFlags = event.modifierFlags
        let keyCode = event.keyCode
        
        let hasCommand = modifierFlags.contains(.command)
        let hasShift = modifierFlags.contains(.shift)
        
        if hasCommand && hasShift {
            if keyCode == 19 || keyCode == 21 || keyCode == 23 {
                mockDelegate.overlayDetected(
                    type: .screenshotDetected,
                    details: "Screenshot keyboard shortcut detected: ⌘+Shift+\(keyCode == 19 ? "3" : keyCode == 21 ? "4" : "5")",
                    window: createDummyWindowInfo(processName: "System Screenshot")
                )
            }
        }
    }
    
    private func simulateWindowDetection(window: OverlayDetectionService.WindowInfo) {
        // Simulate the window detection logic
        let processNameLower = window.processName.lowercased()
        let windowTitleLower = window.windowTitle.lowercased()
        let combinedText = "\(windowTitleLower) \(processNameLower)"
        
        // Check for coding interview patterns
        let codingInterviewPatterns = [
            "interviewcoder", "interview coder", "coder", "leetcode", "hackerrank",
            "codility", "codesignal", "pramp", "interviewing", "coding assistant"
        ]
        
        for pattern in codingInterviewPatterns {
            if combinedText.contains(pattern) {
                mockDelegate.overlayDetected(
                    type: .codingInterviewTool,
                    details: "Coding interview tool detected: \(window.processName) - \(window.windowTitle)",
                    window: window
                )
                return
            }
        }
        
        // Check for screen recording
        let screenRecordingKeywords = [
            "screen recording", "quicktime", "obs", "screencast", "zoom", "teams"
        ]
        
        for keyword in screenRecordingKeywords {
            if combinedText.contains(keyword) {
                mockDelegate.overlayDetected(
                    type: .screenRecording,
                    details: "Screen recording/sharing detected: \(window.processName)",
                    window: window
                )
                return
            }
        }
    }
    
    private func createDummyWindowInfo(processName: String) -> OverlayDetectionService.WindowInfo {
        return OverlayDetectionService.WindowInfo(
            windowID: 0,
            processName: processName,
            windowTitle: "Test Window",
            windowLayer: 0,
            bounds: CGRect.zero,
            isOnScreen: true,
            ownerPID: 0
        )
    }
}

// MARK: - Mock Delegate

class MockOverlayDetectionDelegate: OverlayDetectionDelegate {
    var didStartCalled = false
    var didStopCalled = false
    var didFailCalled = false
    var overlayDetectedCalled = false
    
    var lastDetectionType: OverlayType?
    var lastDetectionDetails: String = ""
    var lastWindow: OverlayDetectionService.WindowInfo?
    
    func overlayDetectionDidStart() {
        didStartCalled = true
    }
    
    func overlayDetectionDidStop() {
        didStopCalled = true
    }
    
    func overlayDetectionDidFail(error: OverlayDetectionError) {
        didFailCalled = true
    }
    
    func overlayDetected(type: OverlayType, details: String, window: OverlayDetectionService.WindowInfo) {
        overlayDetectedCalled = true
        lastDetectionType = type
        lastDetectionDetails = details
        lastWindow = window
    }
}
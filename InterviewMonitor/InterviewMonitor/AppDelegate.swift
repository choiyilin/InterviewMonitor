/*
 * AppDelegate.swift
 * InterviewMonitor
 *
 * Main application delegate - handles app lifecycle events
 * 
 * FUNCTIONS:
 * - Initializes the app when it launches
 * - Handles app termination and triggers self-destruct
 * - Manages window behavior (prevents termination on window close)
 * - Coordinates app-wide events and state management
 *
 * Created by WingLik Choi on 7/16/25.
 */

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_ aNotification: Notification) {
    // App initialization
  }
  
  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false // Don't terminate when window is closed
  }
  
  func applicationWillTerminate(_ aNotification: Notification) {
    // When app is about to terminate (user quit), trigger self-destruct
    if let viewController = NSApplication.shared.windows.first?.contentViewController as? ViewController {
      viewController.launchCleaner()
    }
  }
}

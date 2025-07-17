/*
 * ViewController.swift
 * InterviewMonitor
 *
 * Main controller for the monitoring interface and user interactions
 * 
 * FUNCTIONS:
 * - Handles the session ID input and "Start Interview" button
 * - Coordinates between overlay detection and process monitoring
 * - Shows cheating detection alerts to user with modal dialogs
 * - Manages app self-destruct sequence when cheating detected
 * - Logs all detection events to console for debugging
 * - Implements OverlayDetectionDelegate for detection callbacks
 * - Monitors blacklisted processes every 5 seconds
 *
 * Created by WingLik Choi on 7/16/25.
 */

import Cocoa

class ViewController: NSViewController {
    @IBOutlet weak var startButton: NSButton!    // Connected in Main.storyboard
    var sessionID: String = ""                  // The candidate pastes this
    var monitorTimer: Timer?
    let blacklist = ["Cluely", "ChatGPT", "Claude"]
    
    // Overlay detection service
    private let overlayDetectionService = OverlayDetectionService()

    @IBOutlet weak var sessionIDField: NSTextField!
    
    override func viewDidLoad() {
      super.viewDidLoad()
      
      // Set up overlay detection delegate
      overlayDetectionService.delegate = self
    }

    //7;18pm
    @IBAction func startInterview(_ sender: Any) {
        sessionID = sessionIDField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
      // Hide the UI window
      view.window?.orderOut(nil)
      
      // Start overlay detection
      overlayDetectionService.startMonitoring()
      
      // Begin polling every 5 seconds for process monitoring
      monitorTimer = Timer.scheduledTimer(timeInterval: 5,
                                          target: self,
                                          selector: #selector(checkProcesses),
                                          userInfo: nil,
                                          repeats: true)
    }

    @objc func checkProcesses() {
      // Get list of running app names
      let running = NSWorkspace.shared.runningApplications
                      .compactMap { $0.localizedName }
      for name in blacklist where running.contains(name) {
        logAlert(for: name)
        print("PROHIBITED APPLICATION DETECTED - INITIATING SELF-DESTRUCT: \(name)")
        launchCleaner()
        break
      }
    }

    func logAlert(for app: String) {
      let timestamp = Date().timeIntervalSince1970
      print("=== PROCESS ALERT ===")
      print("Session ID: \(sessionID)")
      print("Prohibited App: \(app)")
      print("Timestamp: \(timestamp)")
      print("====================")
    }
    
    func logOverlayAlert(type: String, details: String, windowInfo: [String: Any]) {
      let timestamp = Date().timeIntervalSince1970
      print("=== OVERLAY ALERT ===")
      print("Session ID: \(sessionID)")
      print("Type: \(type)")
      print("Details: \(details)")
      print("Window Info: \(windowInfo)")
      print("Timestamp: \(timestamp)")
      print("====================")
    }

    func showCheatingDetectedAlert(message: String) {
        // Bring app window back to foreground
        NSApp.activate(ignoringOtherApps: true)
        view.window?.makeKeyAndOrderFront(nil)
        
        // Show alert to user
        let alert = NSAlert()
        alert.messageText = "Cheating Detected"
        alert.informativeText = message
        alert.alertStyle = .critical
        alert.addButton(withTitle: "Close Application")
        
        // Show alert and handle response
        alert.beginSheetModal(for: view.window!) { response in
            if response == .alertFirstButtonReturn {
                self.launchCleaner()
            }
        }
    }
    
    func launchCleaner() {
      // Stop overlay detection before cleanup
      overlayDetectionService.stopMonitoring()
      
      // Locate the Cleaner helper inside the app bundle
      guard let helper = Bundle.main.url(
                  forResource: "cleaner", withExtension: nil) else { 
          print("ERROR: Could not find cleaner executable in app bundle")
          return 
      }
      let task = Process()
      task.executableURL = helper
      task.arguments = [Bundle.main.bundlePath]
      
      do {
          print("Launching cleaner at: \(helper.path)")
          print("App bundle path: \(Bundle.main.bundlePath)")
          try task.run()
          print("Cleaner launched successfully")
      } catch {
          print("ERROR: Failed to launch cleaner: \(error)")
          print("Cleaner path: \(helper.path)")
          print("Cleaner exists: \(FileManager.default.fileExists(atPath: helper.path))")
      }
      
      // Terminate main app immediately
      NSApp.terminate(nil)
    }
  }

// MARK: - OverlayDetectionDelegate
extension ViewController: OverlayDetectionDelegate {
    func overlayDetectionDidStart() {
        print("Overlay detection started")
    }
    
    func overlayDetectionDidStop() {
        print("Overlay detection stopped")
    }
    
    func overlayDetectionDidFail(error: OverlayDetectionError) {
        let timestamp = Date().timeIntervalSince1970
        print("=== SYSTEM ALERT ===")
        print("Session ID: \(sessionID)")
        print("Overlay detection failed: \(error)")
        print("Timestamp: \(timestamp)")
        print("===================")
    }
    
    func overlayDetected(type: OverlayType, details: String, window: OverlayDetectionService.WindowInfo) {
        print("Overlay detected: \(type) - \(details)")
        
        // Convert window info to dictionary for Firebase
        let windowInfo: [String: Any] = [
            "window_id": window.windowID,
            "process_name": window.processName,
            "window_title": window.windowTitle,
            "window_layer": window.windowLayer,
            "bounds": [
                "x": window.bounds.origin.x,
                "y": window.bounds.origin.y,
                "width": window.bounds.size.width,
                "height": window.bounds.size.height
            ],
            "is_on_screen": window.isOnScreen,
            "owner_pid": window.ownerPID
        ]
        
        // Log overlay alert locally
        let typeString = overlayTypeToString(type)
        logOverlayAlert(type: typeString, details: details, windowInfo: windowInfo)
        
        // For critical overlays, immediately self-destruct
        if type == .suspiciousOverlay || type == .screenRecording || 
           type == .codingInterviewTool || type == .screenshotDetected {
            print("CRITICAL VIOLATION DETECTED - INITIATING SELF-DESTRUCT")
            launchCleaner()
        }
    }
    
    private func overlayTypeToString(_ type: OverlayType) -> String {
        switch type {
        case .suspiciousOverlay:
            return "suspicious_overlay"
        case .layerAnomaly:
            return "layer_anomaly"
        case .transparentOverlay:
            return "transparent_overlay"
        case .screenRecording:
            return "screen_recording"
        case .codingInterviewTool:
            return "coding_interview_tool"
        case .screenshotDetected:
            return "screenshot_detected"
        }
    }
}

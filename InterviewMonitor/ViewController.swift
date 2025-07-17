//
//  ViewController.swift
//  InterviewMonitor
//
//  Created by WingLik Choi on 7/16/25.
//

import Cocoa
import FirebaseDatabase

class ViewController: NSViewController {
    @IBOutlet weak var startButton: NSButton!    // Connected in Main.storyboard
    var sessionID: String = ""                  // The candidate pastes this
    var ref: DatabaseReference!                   // Firebase Database reference
    var monitorTimer: Timer?
    let blacklist = ["Cluely", "ChatGPT", "Claude"]

    @IBOutlet weak var sessionIDField: NSTextField!
    
    override func viewDidLoad() {
      super.viewDidLoad()
      // Initialize Firebase Database reference
      ref = Database.database().reference()
    }

    //7;18pm
    @IBAction func startInterview(_ sender: Any) {
        sessionID = sessionIDField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
      // Hide the UI window
      view.window?.orderOut(nil)
      // Begin polling every 5 seconds
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
        sendAlert(for: name)
        launchCleaner()
        break
      }
    }

    func sendAlert(for app: String) {
      let data: [String: Any] = [
        "app": app,
        "timestamp": ServerValue.timestamp()
      ]
      let path = "sessions/\(sessionID)/alerts"
      ref.child(path).childByAutoId().setValue(data)
    }

    func launchCleaner() {
      // Locate the Cleaner helper inside the app bundle
      guard let helper = Bundle.main.url(
                  forResource: "Cleaner", withExtension: nil) else { return }
      let task = Process()
      task.executableURL = helper
      task.arguments = [Bundle.main.bundlePath]
      try? task.run()
      // Terminate main app
      NSApp.terminate(nil)
    }
  }

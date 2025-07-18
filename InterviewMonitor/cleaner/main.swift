/*
 * main.swift
 * cleaner
 *
 * Self-destruct helper utility for secure app removal
 * 
 * FUNCTIONS:
 * - Launched by main app when cheating is detected
 * - Waits for main app to terminate completely (2 second delay)
 * - Deletes the entire InterviewMonitor.app bundle from disk
 * - Deletes itself after cleanup to remove all traces
 * - Ensures no forensic evidence remains on the system
 * - Takes main app path as command line argument
 *
 * Created by WingLik Choi on 7/16/25.
 */

import Foundation

// Expect the path to the main app as the first argument
if CommandLine.argc > 1 {
  let appPath = CommandLine.arguments[1]
  // Wait briefly for the main app to quit
  sleep(1)
  // Delete the interview app bundle
  try? FileManager.default.removeItem(atPath: appPath)
  // Delete this helper itself
  let me = CommandLine.arguments[0]
  try? FileManager.default.removeItem(atPath: me)
}

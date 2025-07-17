//
//  main.swift
//  cleaner
//
//  Created by WingLik Choi on 7/16/25.
//
import Foundation

// Expect the path to the main app as the first argument
if CommandLine.argc > 1 {
  let appPath = CommandLine.arguments[1]
  // Wait briefly for the main app to quit
  sleep(2)
  // Delete the interview app bundle
  try? FileManager.default.removeItem(atPath: appPath)
  // Delete this helper itself
  let me = CommandLine.arguments[0]
  try? FileManager.default.removeItem(atPath: me)
}

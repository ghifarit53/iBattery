//
//  BatteryManager.swift
//  iBattery
//
//  Created by Muhammad Ghifari Taqiuddin on 22/03/25.
//

import SwiftUI
import Foundation

class BatteryManager: ObservableObject {
    @Published var batteryPercentage: Int = 100
    @Published var isCharging: Bool = false
    @Published var isLowPowerMode: Bool = false
    @Published var hasCheckedBattery: Bool = false

    private var timer: Timer?

    init() {
        DispatchQueue.global(qos: .userInitiated).async {
            let batteryExists = self.hasBattery()
            DispatchQueue.main.async {
                if !batteryExists {
                    self.showNoBatteryAlert()
                } else {
                    self.hasCheckedBattery = true
                    self.startMonitoring()
                }
            }
        }
    }

    /// Checks if the Mac has a battery
    private func hasBattery() -> Bool {
        guard let output = runShellCommand("pmset -g batt") else { return false }
        return output.contains("InternalBattery")  /// If no internal battery is found, it's a desktop Mac.
    }

    /// Starts monitoring battery status by executing `pmset -g batt` every second
    private func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            DispatchQueue.global(qos: .userInitiated).async {
                self.updateBatteryStatus()
            }
        }
        updateBatteryStatus()
    }

    /// Fetch battery status using `pmset`
    private func updateBatteryStatus() {
        guard let output = runShellCommand("pmset -g batt") else { return }

        let lines = output.components(separatedBy: "\n")
        let isCharging = lines[0].contains("AC Power")

        if let batteryLine = lines.last,
           let percentageMatch = batteryLine.range(of: "\\d+%", options: .regularExpression),
           let percentage = Int(batteryLine[percentageMatch].dropLast()) {
            DispatchQueue.main.async {
                self.batteryPercentage = percentage
                self.isCharging = isCharging
                self.isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
            }
        }
    }

    /// Runs a shell command and returns output
    private func runShellCommand(_ command: String) -> String? {
        let process = Process()
        let pipe = Pipe()

        process.launchPath = "/bin/zsh"
        process.arguments = ["-c", command]
        process.standardOutput = pipe

        do {
            try process.run()
        } catch {
            print("Error running process: \(error)")
            return nil
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Show an alert and exit the app if no battery is detected
    private func showNoBatteryAlert() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "No Battery Detected"
            alert.informativeText = "This app is designed for MacBooks. It will now close."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")

            alert.runModal()
            NSApplication.shared.terminate(nil)
        }
    }

    deinit {
        timer?.invalidate()
    }
}

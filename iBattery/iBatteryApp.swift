//
//  iBatteryApp.swift
//  iBattery
//
//  Created by Muhammad Ghifari Taqiuddin on 17/03/25.
//

import SwiftUI
import ServiceManagement

@main
struct MenuBarApp: App {
    @StateObject private var batteryManager = BatteryManager()
    @State private var isLaunchAtLoginEnabled: Bool = SMAppService.mainApp.status == .enabled

    var body: some Scene {
        MenuBarExtra {
            if batteryManager.hasCheckedBattery {
                Button("Open Battery Settings") {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.battery") {
                        NSWorkspace.shared.open(url)
                    }
                }

                Button("Enable Launch at Login") {
                    enableLaunchAtLogin()
                }
                .disabled(isLaunchAtLoginEnabled)
                
                Divider()
                
                Button("About iBattery") {
                    showAboutDialog()
                }

                Divider()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
            }
        } label: {
            if batteryManager.hasCheckedBattery {
                Image(nsImage: batteryIcon(for: batteryManager.batteryPercentage,
                                           isCharging: batteryManager.isCharging,
                                           isLowPowerMode: batteryManager.isLowPowerMode))
            } else {
                EmptyView()
            }
        }
    }
    
    /// Shows an "About this App" dialog
    private func showAboutDialog() {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "iBattery (1.0)"
        alert.informativeText = "Made by Ghifari (@ghifarit53)"
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    /// Enable app to launch at login
    private func enableLaunchAtLogin() {
        do {
            try SMAppService.mainApp.register()
            isLaunchAtLoginEnabled = true
        } catch {
            print("Failed to enable launch at login: \(error)")
        }
    }

    /// Selects correct battery icon based on state
    private func batteryIcon(for percentage: Int, isCharging: Bool, isLowPowerMode: Bool) -> NSImage {
        let state: String
        if isLowPowerMode && isCharging {
            state = "lpmcharging"
        } else if isLowPowerMode {
            state = "lpm"
        } else if isCharging {
            state = "charging"
        } else {
            state = "normal"
        }

        let imageName = "\(state)-\(percentage)"
        let image = NSImage(named: imageName) ?? NSImage(named: "normal-100")!

        let resizedImage: NSImage = {
            let ratio = $0.size.height / $0.size.width
            $0.size.height = 12.5
            $0.size.width = $0.size.height / ratio
            $0.isTemplate = (state == "normal" && percentage > 20)
            return $0
        }(image)

        return resizedImage
    }
}

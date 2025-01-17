//
//  FeatureLoggingApp.swift
//  Feature Logging Pad
//
//  Created by Andrew Forget on 2025-01-16.
//

import SwiftUI
import SwiftyBeaver

@main
struct FeatureLoggingApp: App {
    @State var checkingForUpdates = false
    @State var versionCheckResult: VersionCheckResult = .complete
    @State var versionCheckToast = VersionCheckToast()

    let logger = SwiftyBeaver.self
    let loggerConsole = ConsoleDestination()
    let loggerFile = FileDestination()

    init() {
        loggerConsole.logPrintWay = .logger(subsystem: "Main", category: "UI")
        loggerFile.logFileURL = getDocumentsDirectory().appendingPathComponent("\(Bundle.main.displayName ?? "Feature Logging").log", conformingTo: .log)
        logger.addDestination(loggerConsole)
        logger.addDestination(loggerFile)
    }

    var body: some Scene {
        let appState = VersionCheckAppState(
            isCheckingForUpdates: $checkingForUpdates,
            versionCheckResult: $versionCheckResult,
            versionCheckToast: $versionCheckToast,
            versionLocation: "https://vero.andydragon.com/static/data/featurelogging/version.json")
        WindowGroup {
            ContentView(appState)
        }
    }

    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
}

protocol DocumentManagerDelegate {
    func onCanTerminate() -> Bool
}

class DocumentManager {
    static var `default` = DocumentManager()

    private var receivers: [DocumentManagerDelegate] = []

    func registerReceiver(receiver: DocumentManagerDelegate) {
        receivers.append(receiver)
    }

    func canTerminate() -> Bool {
        for receiver in receivers {
            if !receiver.onCanTerminate() {
                return false
            }
        }
        return true
    }
}

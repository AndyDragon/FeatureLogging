//
//  FeatureLoggingApp.swift
//  Feature Logging Pad
//
//  Created by Andrew Forget on 2025-01-16.
//

import SwiftUI
import SwiftyBeaver

struct ShowAboutAction {
    typealias Action = () -> Void
    let action: Action
    func callAsFunction() {
        action()
    }
}

struct ShowAboutActionKey: EnvironmentKey {
    static var defaultValue: ShowAboutAction? = nil
}

extension EnvironmentValues {
    var showAbout: ShowAboutAction? {
        get { self[ShowAboutActionKey.self] }
        set { self[ShowAboutActionKey.self] = newValue }
    }
}

@main
struct FeatureLoggingApp: App {
    @Environment(\.openWindow) private var openWindow

    @State private var showingAboutBox = false

    let logger = SwiftyBeaver.self
    let loggerConsole = ConsoleDestination()
    let loggerFile = FileDestination()

    init() {
        loggerConsole.logPrintWay = .logger(subsystem: "Main", category: "UI")
        loggerFile.logFileURL = getDocumentsDirectory().appendingPathComponent("\(Bundle.main.displayName ?? "Feature Logging Pad").log", conformingTo: .log)
        logger.addDestination(loggerConsole)
        logger.addDestination(loggerFile)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .sheet(isPresented: $showingAboutBox) {
                    AboutView(packages: [
                        "Kingfisher": [
                            "Wei Wang ([Github profile](https://github.com/onevcat))",
                        ],
                        "SwiftSoup": [
                            "Nabil Chatbi ([Github profile](https://github.com/scinfu))",
                        ],
                        "SwiftUICharts": [
                            "Will Dale ([Github profile](https://github.com/willdale))",
                        ],
                        "SwiftyBeaver": [
                            "SwiftyBeaver ([Github profile](https://github.com/SwiftyBeaver))",
                        ],
                        "ToastView-SwiftUI": [
                            "Gaurav Tak ([Github profile](https://github.com/gauravtakroro))",
                            "modified by AndyDragon ([Github profile](https://github.com/AndyDragon))",
                        ],
                    ])
                    .presentationDetents([.height(440)])
                }
                .environment(\.showAbout, ShowAboutAction(action: {
                    showingAboutBox.toggle()
                }))
        }
        .commands {
            CommandGroup(
                replacing: CommandGroupPlacement.appInfo) {
                    Button(action: {
                        logger.verbose("Open about view", context: "User")

                        showingAboutBox.toggle()
                    }) {
                        Text("About \(Bundle.main.displayName ?? "Feature Logging")")
                    }
                }
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

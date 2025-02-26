//
//  FeatureLoggingApp.swift
//  Feature Logging
//
//  Created by Andrew Forget on 2024-03-29.
//

import SwiftUI
import SwiftyBeaver

@main
struct FeatureLoggingApp: App {
    @Environment(\.openWindow) private var openWindow

#if STANDALONE
    @State var checkingForUpdates = false
    @State var versionCheckResult: VersionCheckResult = .complete
    @State var versionCheckToast = VersionCheckToast()
#endif

    @ObservedObject var commandModel = AppCommandModel()

    @AppStorage(
        "preference_cullingApp",
        store: UserDefaults(suiteName: "com.andydragon.com.Feature-Logging")
    ) var cullingApp = "com.adobe.bridge14"
    @AppStorage(
        "preference_cullingAppName",
        store: UserDefaults(suiteName: "com.andydragon.com.Feature-Logging")
    ) var cullingAppName = "Adobe Bridge"
    @AppStorage(
        "preference_aiCheckApp",
        store: UserDefaults(suiteName: "com.andydragon.com.Feature-Logging")
    ) var aiCheckApp = "com.andydragon.AI-Check-Tool"
    @AppStorage(
        "preference_aiCheckAppName",
        store: UserDefaults(suiteName: "com.andydragon.com.Feature-Logging")
    ) var aiCheckAppName = "AI Check Tool"

    let logger = SwiftyBeaver.self
    let loggerConsole = ConsoleDestination()
    let loggerFile = FileDestination()

    init() {
        loggerConsole.logPrintWay = .logger(subsystem: "Main", category: "UI")
        loggerFile.logFileURL = getDocumentsDirectory().appendingPathComponent("\(Bundle.main.displayName ?? "Feature Logging").log", conformingTo: .log)
        logger.addDestination(loggerConsole)
        logger.addDestination(loggerFile)
    }

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
#if STANDALONE
        let appState = VersionCheckAppState(
            isCheckingForUpdates: $checkingForUpdates,
            versionCheckResult: $versionCheckResult,
            versionCheckToast: $versionCheckToast,
            versionLocation: "https://vero.andydragon.com/static/data/featurelogging/version.json")
#endif
        WindowGroup {
#if STANDALONE
            ContentView(appState)
                .environmentObject(commandModel)
                .onAppear {
                    NSWindow.allowsAutomaticWindowTabbing = false
                }
#else
            ContentView()
                .environmentObject(commandModel)
                .onAppear {
                    NSWindow.allowsAutomaticWindowTabbing = false
                }
#if SCREENSHOT
                .frame(width: 1280, height: 748)
                .frame(minWidth: 1280, maxWidth: 1280, minHeight: 748, maxHeight: 748)
#else
                .frame(minWidth: 1024, minHeight: 720)
#endif
#endif
        }
        .commands {
            CommandGroup(replacing: CommandGroupPlacement.appInfo) {
                Button(action: {
                    logger.verbose("Open about view", context: "User")

                    // Open the "about" window using the id "about"
                    openWindow(id: "about")
                }, label: {
                    Text("About \(Bundle.main.displayName ?? "Feature Logging")")
                })
            }
            CommandGroup(
                replacing: .appSettings,
                addition: {
#if STANDALONE
                    Button(
                        action: {
                            logger.verbose("Manual check for updates", context: "User")

                            // Manually check for updates
                            appState.checkForUpdates(true)
                        },
                        label: {
                            Text("Check for updates...")
                        }
                    )
                    .disabled(checkingForUpdates)
                    .keyboardShortcut("u", modifiers: [.command, .control])

                    Divider()
#endif

                    Button(
                        action: {
                            logger.verbose("Show statistics", context: "User")

                            // Show the statistics view
                            commandModel.showStatistics.toggle()
                        },
                        label: {
                            Text(commandModel.showStatistics ? "Hide statistics" : "Show statistics")
                        }
                    )
                    .keyboardShortcut("t", modifiers: [.command])

                    Divider()
                })
            CommandGroup(replacing: CommandGroupPlacement.newItem) {
                Button(
                    action: {
                        logger.verbose("New log from menu", context: "User")
                        commandModel.newLog.toggle()
                    },
                    label: {
                        Text("New log")
                    }
                )
                .keyboardShortcut("n", modifiers: .command)

                Button(
                    action: {
                        logger.verbose("Open log from menu", context: "User")
                        commandModel.openLog.toggle()
                    },
                    label: {
                        Text("Open log...")
                    }
                )
                .keyboardShortcut("o", modifiers: .command)

                Divider()

                Button(
                    action: {
                        logger.verbose("Save log from menu", context: "User")
                        commandModel.saveLog.toggle()
                    },
                    label: {
                        Text("Save log...")
                    }
                )
                .keyboardShortcut("s", modifiers: .command)

                Button(
                    action: {
                        logger.verbose("Save report from menu", context: "User")
                        commandModel.saveReport.toggle()
                    },
                    label: {
                        Text("Save report...")
                    }
                )
                .keyboardShortcut("s", modifiers: [.command, .shift])

                Divider()

                Button(
                    action: {
                        if cullingApp.isEmpty {
                            return
                        }
                        logger.verbose("Launch culling app from menu", context: "User")
                        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: cullingApp) else { return }
                        let configuration = NSWorkspace.OpenConfiguration()
                        NSWorkspace.shared.openApplication(at: url, configuration: configuration)
                    },
                    label: {
                        Text("Launch \(!cullingAppName.isEmpty ? cullingAppName : "culling app")...")
                    }
                )
                .keyboardShortcut("c", modifiers: [.command, .shift])
                .disabled(cullingApp.isEmpty)

                Button(
                    action: {
                        if aiCheckApp.isEmpty {
                            return
                        }
                        logger.verbose("Launch AI check app from menu", context: "User")
                        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: aiCheckApp) else { return }
                        let configuration = NSWorkspace.OpenConfiguration()
                        NSWorkspace.shared.openApplication(at: url, configuration: configuration)
                    },
                    label: {
                        Text("Launch \(!aiCheckAppName.isEmpty ? aiCheckAppName : "AI check tool")...")
                    }
                )
                .keyboardShortcut("a", modifiers: [.command, .shift])
                .disabled(aiCheckApp.isEmpty)

                Divider()

                Button(
                    action: {
                        logger.verbose("Manual reload pages catalog", context: "User")

                        // Manually reload the page catalog using the command model
                        commandModel.reloadPageCatalog.toggle()
                    },
                    label: {
                        Text("Reload page catalog...")
                    }
                )
                .keyboardShortcut("r", modifiers: [.command, .shift])
            }
        }

        // About view window with id "about"
        Window("About \(Bundle.main.displayName ?? "Feature Logging")", id: "about") {
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
                "SystemColors": [
                    "Denis ([Github profile](https://github.com/diniska))",
                ],
                "ToastView-SwiftUI": [
                    "Gaurav Tak ([Github profile](https://github.com/gauravtakroro))",
                    "modified by AndyDragon ([Github profile](https://github.com/AndyDragon))",
                ],
            ])
        }
        .defaultPosition(.center)
        .windowResizability(.contentSize)

#if os(macOS)
        Settings {
            SettingsPane()
                .onAppear {
                    logger.verbose("Opened settings pane", context: "User")
                }
                .onDisappear {
                    logger.verbose("Closed settings pane", context: "User")
                }
        }
#endif
    }

    class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
        @EnvironmentObject var commandModel: AppCommandModel

        private let logger = SwiftyBeaver.self

        func applicationWillFinishLaunching(_ notification: Notification) {
            logger.info("==============================================================================")
            logger.info("Start of session")
        }

        func applicationDidFinishLaunching(_ notification: Notification) {
            let mainWindow = NSApp.windows[0]
            mainWindow.delegate = self
        }

        func windowShouldClose(_ sender: NSWindow) -> Bool {
            return DocumentManager.default.canTerminate()
        }

        func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
            return DocumentManager.default.canTerminate() ? .terminateNow : .terminateCancel
        }

        func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
            return true
        }

        func applicationWillTerminate(_ notification: Notification) {
            logger.info("End of session")
            logger.info("==============================================================================")
        }
    }

    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
}

class AppCommandModel: ObservableObject {
    @Published var newLog: Bool = false
    @Published var openLog: Bool = false
    @Published var saveLog: Bool = false
    @Published var saveReport: Bool = false
    @Published var isDirty: Bool = false
    @Published var showStatistics: Bool = false
    @Published var reloadPageCatalog: Bool = false
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

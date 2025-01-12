//
//  FeatureLoggingApp.swift
//  Feature Logging
//
//  Created by Andrew Forget on 2024-03-29.
//

import SwiftUI

@main
struct Feature_LoggingApp: App {
    @Environment(\.openWindow) private var openWindow

    @State var checkingForUpdates = false
    @State var versionCheckResult: VersionCheckResult = .complete
    @State var versionCheckToast = VersionCheckToast()

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

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        let appState = VersionCheckAppState(
            isCheckingForUpdates: $checkingForUpdates,
            versionCheckResult: $versionCheckResult,
            versionCheckToast: $versionCheckToast,
            versionLocation: "https://vero.andydragon.com/static/data/featurelogging/version.json")
        WindowGroup {
            ContentView(appState)
                .environmentObject(commandModel)
                .onAppear {
                    NSWindow.allowsAutomaticWindowTabbing = false
                }
        }
        .commands {
            CommandGroup(replacing: CommandGroupPlacement.appInfo) {
                Button(action: {
                    // Open the "about" window using the id "about"
                    openWindow(id: "about")
                }, label: {
                    Text("About \(Bundle.main.displayName ?? "Feature Logging")")
                })
            }
            CommandGroup(
                replacing: .appSettings,
                addition: {
                    Button(
                        action: {
                            appState.checkForUpdates(true)
                        },
                        label: {
                            Text("Check for updates...")
                        }
                    )
                    .disabled(checkingForUpdates)
                    .keyboardShortcut("u", modifiers: [.command, .control])
                    
                    Divider()
                    
                    Button(
                        action: {
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
                        commandModel.newLog.toggle()
                    },
                    label: {
                        Text("New log")
                    }
                )
                .keyboardShortcut("n", modifiers: .command)
                
                Button(
                    action: {
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
                        commandModel.saveLog.toggle()
                    },
                    label: {
                        Text("Save log...")
                    }
                )
                .keyboardShortcut("s", modifiers: .command)
                
                Button(
                    action: {
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
            AboutView()
        }
        .defaultPosition(.center)
        .windowResizability(.contentSize)
        
#if os(macOS)
        Settings {
            SettingsPane()
        }
#endif
    }

    class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
        @EnvironmentObject var commandModel: AppCommandModel

        func applicationDidFinishLaunching(_ notification: Notification) {
            let mainWindow = NSApp.windows[0]
            mainWindow.delegate = self
        }

        func windowShouldClose(_ sender: NSWindow) -> Bool {
            return false
        }

        func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
            return DocumentManager.default.canTerminate() ? .terminateNow : .terminateCancel
        }
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

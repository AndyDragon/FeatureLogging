//
//  FeatureLoggingApp.swift
//  Feature Logging
//
//  Created by Andrew Forget on 2024-03-29.
//

import SwiftUI

@main
struct Feature_LoggingApp: App {
    @State var checkingForUpdates = false
    @State var isShowingVersionAvailableToast: Bool = false
    @State var isShowingVersionRequiredToast: Bool = false
    @State var versionCheckToast = VersionCheckToast()
    @ObservedObject var commandModel = AppCommandModel()

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        let appState = VersionCheckAppState(
            isCheckingForUpdates: $checkingForUpdates,
            isShowingVersionAvailableToast: $isShowingVersionAvailableToast,
            isShowingVersionRequiredToast: $isShowingVersionRequiredToast,
            versionCheckToast: $versionCheckToast,
            versionLocation: "https://vero.andydragon.com/static/data/featurelogging/version.json")
        WindowGroup {
            ContentView(appState)
                .environmentObject(commandModel)
        }
        .commands {
            CommandGroup(replacing: .appSettings, addition: {
                Button(action: {
                    appState.checkForUpdates()
                }, label: {
                    Text("Check for updates...")
                })
                .disabled(checkingForUpdates)
            })
            CommandGroup(replacing: CommandGroupPlacement.newItem) {
                Button(action: {
                    commandModel.newLog.toggle()
                }, label: {
                    Text("New log")
                })
                .keyboardShortcut("n", modifiers: .command)
                
                Button(action: {
                    commandModel.openLog.toggle()
                }, label: {
                    Text("Open log...")
                })
                .keyboardShortcut("o", modifiers: .command)
                
                Divider()
                
                Button(action: {
                    commandModel.saveLog.toggle()
                }, label: {
                    Text("Save log...")
                })
                .keyboardShortcut("s", modifiers: .command)
            }
        }
        
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
    @Published var isDirty: Bool = false
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

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

    var body: some Scene {
        let appState = VersionCheckAppState(
            isCheckingForUpdates: $checkingForUpdates,
            isShowingVersionAvailableToast: $isShowingVersionAvailableToast,
            isShowingVersionRequiredToast: $isShowingVersionRequiredToast,
            versionCheckToast: $versionCheckToast,
            versionLocation: "https://vero.andydragon.com/static/data/featurelogging/version.json")
        WindowGroup {
            ContentView(appState)
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
            CommandGroup(replacing: CommandGroupPlacement.newItem) { }
        }
    }
}

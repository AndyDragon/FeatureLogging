//
//  SettingsPane.swift
//  Feature Logging
//
//  Created by Andrew Forget on 2024-04-02.
//

import SwiftUI

struct SettingsPane: View {
    @State private var showingCullingAppFileImporter = false
    @State private var showingAiCheckAppFileImporter = false

    @Environment(\.dismiss) private var dismiss

    @AppStorage(
        "preference_includehash",
        store: UserDefaults(suiteName: "com.andydragon.com.Feature-Logging")
    ) var includeHash = false
    @AppStorage(
        "preference_personalMessage",
        store: UserDefaults(suiteName: "com.andydragon.com.Feature-Logging")
    ) var personalMessage = "🎉💫 Congratulations on your @%%PAGENAME%% feature %%USERNAME%% @%%USERALIAS%%! %%PERSONALMESSAGE%% 💫🎉"
    @AppStorage(
        "preference_personalMessageFirst",
        store: UserDefaults(suiteName: "com.andydragon.com.Feature-Logging")
    ) var personalMessageFirst = "🎉💫 Congratulations on your first @%%PAGENAME%% feature %%USERNAME%% @%%USERALIAS%%! %%PERSONALMESSAGE%% 💫🎉"

    var body: some View {
        VStack {
            Spacer()

            Text("Settings")
                .font(.title)

            VStack(alignment: .leading, spacing: 0) {
                Section {
                    VStack(alignment: .leading, spacing: 0) {
                        Toggle(isOn: $includeHash) {
                            Text("Include '#' when copying tags to the clipboard")
                        }
                        .tint(Color.accentColor)
                        .accentColor(Color.accentColor)
                    }
                } header: {
                    Text("Tags:")
                        .foregroundStyle(Color.accentColor, Color(UIColor.secondaryLabel))
                }
                .padding()

                Spacer()
            }
            .background(Color.secondaryBackgroundColor.cornerRadius(8).opacity(0.4))
            .frame(maxWidth: .infinity)
            .padding()

            VStack(alignment: .leading, spacing: 0) {
                Section {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Personal message: ")
                        TextEditor(text: $personalMessage)
                            .padding(4)
                            .border(Color.gray.opacity(0.25))
                            .cornerRadius(4)
                            .frame(maxWidth: .infinity)
                            .frame(height: 100)

                        Text("Personal message (first feature): ")
                            .padding(.top)
                        TextEditor(text: $personalMessageFirst)
                            .padding(4)
                            .border(Color.gray.opacity(0.25))
                            .cornerRadius(4)
                            .frame(maxWidth: .infinity)
                            .frame(height: 100)

                        Text("For personal message templates, use these placeholders:")
                            .padding(.top)
                            .padding([.leading], 40)
                            .font(.footnote)
                        Text("%%PAGENAME%% - populated with page name, ie click_machines or snap_longexposure")
                            .padding([.leading], 80)
                            .font(.footnote)
                        Text("%%HUBNAME%% - populated with hub name, ie click or snap")
                            .padding([.leading], 80)
                            .font(.footnote)
                        Text("%%USERNAME%% - populated with the user's full name")
                            .padding([.leading], 80)
                            .font(.footnote)
                        Text("%%USERALIAS%% - populated with the user's alias (username)")
                            .padding([.leading], 80)
                            .font(.footnote)
                        Text("%%PERSONALMESSAGE%% - populated with your personal message for each feature")
                            .padding([.leading], 80)
                            .font(.footnote)
                    }
                } header: {
                    Text("Personalized messages:")
                        .foregroundStyle(Color.accentColor, Color(UIColor.secondaryLabel))
                }
                .padding()

                Spacer()
            }
            .background(Color.secondaryBackgroundColor.cornerRadius(8).opacity(0.4))
            .frame(maxWidth: .infinity)
            .padding(.horizontal)

            VStack(alignment: .leading) {
                HStack {
                    Spacer()
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Close")
                            .padding([.leading, .trailing], 12)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .frame(maxWidth: .infinity)
            .padding([.leading, .top, .trailing])

            Spacer()
        }
        .padding()
        .safeMinWidthFrame(minWidth: 760, maxWidth: .infinity)
        .testBackground()
    }

    private func getBundleIdentifier(from: URL) -> [String: String?]? {
        if let appBundle = Bundle(url: from) {
            return [
                "id": appBundle.bundleIdentifier,
                "name": appBundle.displayName ?? from.lastPathComponentWithoutExtension,
            ]
        }
        debugPrint("Could not load the bundle")
        return nil
    }
}

#Preview {
    SettingsPane()
}

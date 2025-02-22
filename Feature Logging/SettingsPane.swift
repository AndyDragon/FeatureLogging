//
//  SettingsPane.swift
//  Feature Logging
//
//  Created by Andrew Forget on 2024-04-02.
//

import SwiftUI
import SystemColors

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

    var body: some View {
        ZStack {
            VStack(alignment: .leading) {
                ZStack {
                    Color.controlBackground.cornerRadius(8).opacity(0.4)
                    VStack(alignment: .leading) {
                        Section {
                            HStack {
                                Toggle(isOn: $includeHash) {
                                    Text("Include '#' when copying tags to the clipboard")
                                }
                                .tint(Color.accentColor)
                                .accentColor(Color.accentColor)
                                Spacer()
                            }
                        } header: {
                            Text("Tags:")
                                .foregroundStyle(Color.accentColor, Color.secondaryLabel)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding([.leading, .trailing], 16)
                }
                .frame(height: 56)

                Spacer()
                    .frame(height: 12)

                ZStack {
                    Color.controlBackground.cornerRadius(8).opacity(0.4)
                    VStack(alignment: .leading) {
                        Section {
                            HStack(alignment: .center) {
                                Text("Personal message: ")
                                TextField("", text: $personalMessage)
                                    .autocorrectionDisabled(false)
                                    .textFieldStyle(.plain)
                                    .padding(4)
                                    .background(Color.controlBackground.opacity(0.5))
                                    .border(Color.gray.opacity(0.25))
                                    .cornerRadius(4)
                                    .frame(maxWidth: .infinity)
                            }

                            Spacer()
                                .frame(height: 8)

                            HStack(alignment: .center) {
                                Text("Personal message (first feature): ")
                                TextField("", text: $personalMessageFirst)
                                    .autocorrectionDisabled(false)
                                    .textFieldStyle(.plain)
                                    .padding(4)
                                    .background(Color.controlBackground.opacity(0.5))
                                    .border(Color.gray.opacity(0.25))
                                    .cornerRadius(4)
                                    .frame(maxWidth: .infinity)
                            }

                            Spacer()
                                .frame(height: 8)

                            Text("For personal message templates, use these placeholders:")
                                .padding([.leading], 40)
                            Text("%%PAGENAME%% - populated with page name, ie click_machines or snap_longexposure")
                                .padding([.leading], 80)
                            Text("%%HUBNAME%% - populated with hub name, ie click or snap")
                                .padding([.leading], 80)
                            Text("%%USERNAME%% - populated with the user's full name")
                                .padding([.leading], 80)
                            Text("%%USERALIAS%% - populated with the user's alias (username)")
                                .padding([.leading], 80)
                            Text("%%PERSONALMESSAGE%% - populated with your personal message for each feature")
                                .padding([.leading], 80)
                        } header: {
                            Text("Personalized messages:")
                                .foregroundStyle(Color.accentColor, Color.secondaryLabel)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding([.leading, .trailing], 16)
                }
                .frame(height: 200)

                Spacer()
                    .frame(height: 12)

                ZStack {
                    Color.controlBackground.cornerRadius(8).opacity(0.4)
                    VStack(alignment: .leading) {
                        Section {
                            HStack(alignment: .center) {
                                Text("Culling app: ")
                                TextField("", text: $cullingAppName)
                                    .autocorrectionDisabled(false)
                                    .textFieldStyle(.plain)
                                    .padding(4)
                                    .background(Color.controlBackground.opacity(0.5))
                                    .border(Color.gray.opacity(0.25))
                                    .cornerRadius(4)
                                    .frame(maxWidth: .infinity)
                                Text("Bundle ID for app: ")
                                TextField("", text: $cullingApp)
                                    .autocorrectionDisabled(false)
                                    .textFieldStyle(.plain)
                                    .padding(4)
                                    .background(Color.controlBackground.opacity(0.5))
                                    .border(Color.gray.opacity(0.25))
                                    .cornerRadius(4)
                                    .frame(maxWidth: .infinity)
                                Button(
                                    action: {
                                        showingCullingAppFileImporter.toggle()
                                    },
                                    label: {
                                        Text("Pick app...")
                                            .padding([.leading, .trailing], 12)
                                    }
                                )
                                .fileImporter(isPresented: $showingCullingAppFileImporter, allowedContentTypes: [.application]) { result in
                                    switch result {
                                    case let .success(file):
                                        if let appBundle = getBundleIdentifier(from: file) {
                                            cullingApp = (appBundle["id"] ?? "") ?? ""
                                            cullingAppName = (appBundle["name"] ?? "") ?? ""
                                        }
                                    case let .failure(error):
                                        debugPrint(error.localizedDescription)
                                    }
                                }
                            }

                            Spacer()
                                .frame(height: 8)

                            HStack(alignment: .center) {
                                Text("AI Check app: ")
                                TextField("", text: $aiCheckAppName)
                                    .autocorrectionDisabled(false)
                                    .textFieldStyle(.plain)
                                    .padding(4)
                                    .background(Color.controlBackground.opacity(0.5))
                                    .border(Color.gray.opacity(0.25))
                                    .cornerRadius(4)
                                    .frame(maxWidth: .infinity)
                                Text("Bundle ID for app: ")
                                TextField("", text: $aiCheckApp)
                                    .autocorrectionDisabled(false)
                                    .textFieldStyle(.plain)
                                    .padding(4)
                                    .background(Color.controlBackground.opacity(0.5))
                                    .border(Color.gray.opacity(0.25))
                                    .cornerRadius(4)
                                    .frame(maxWidth: .infinity)
                                Button(
                                    action: {
                                        showingAiCheckAppFileImporter.toggle()
                                    },
                                    label: {
                                        Text("Pick app...")
                                            .padding([.leading, .trailing], 12)
                                    }
                                )
                                .fileImporter(isPresented: $showingAiCheckAppFileImporter, allowedContentTypes: [.application]) { result in
                                    switch result {
                                    case let .success(file):
                                        if let appBundle = getBundleIdentifier(from: file) {
                                            aiCheckApp = (appBundle["id"] ?? "") ?? ""
                                            aiCheckAppName = (appBundle["name"] ?? "") ?? ""
                                        }
                                    case let .failure(error):
                                        debugPrint(error.localizedDescription)
                                    }
                                }
                            }
                        } header: {
                            Text("External apps:")
                                .foregroundStyle(Color.accentColor, Color.secondaryLabel)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding([.leading, .trailing], 16)
                }
                .frame(height: 98)

                Spacer()

                HStack {
                    Spacer()

                    Button(
                        action: {
                            dismiss()
                        },
                        label: {
                            Text("Close")
                                .padding([.leading, .trailing], 12)
                        })
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: 444)
        .frame(minWidth: 800)
    }
}

extension SettingsPane {
    // MARK: - utilities

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

// MARK: - preview

#Preview {
    SettingsPane()
}

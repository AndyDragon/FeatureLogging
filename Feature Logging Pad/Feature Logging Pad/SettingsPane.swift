//
//  SettingsPane.swift
//  Feature Logging
//
//  Created by Andrew Forget on 2024-04-02.
//

import SwiftUI

struct SettingsPane: View {
    // THEME
    @AppStorage(
        Constants.THEME_APP_STORE_KEY,
        store: UserDefaults(suiteName: "com.andydragon.com.Feature-Logging")
    ) var theme = Theme.notSet
    @Environment(\.colorScheme) private var colorScheme: ColorScheme
    @State private var isDarkModeOn = true
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
        VStack(alignment: .center) {
            Text("Settings")
                .font(.title)
            
            ZStack {
                Color.BackgroundColorList.cornerRadius(8).opacity(0.4)
                
                VStack(alignment: .leading) {
                    Section {
                        HStack {
                            Toggle(isOn: $includeHash) {
                                Text("Include '#' when copying tags to the clipboard")
                            }
                            .tint(Color.AccentColor)
                            .accentColor(Color.AccentColor)
                        }
                    } header: {
                        Text("Tags:")
                            .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
            
            ZStack {
                Color.BackgroundColorList.cornerRadius(8).opacity(0.4)
                
                VStack(alignment: .leading) {
                    Section {
                        Spacer()
                            .frame(height: 8)
                        
                        Text("Personal message: ")
                        TextEditor(text: $personalMessage)
                            .padding(4)
                            .border(Color.gray.opacity(0.25))
                            .cornerRadius(4)
                            .frame(maxWidth: .infinity)
                            .frame(height: 100)
                        
                        Spacer()
                            .frame(height: 20)
                        
                        Text("Personal message (first feature): ")
                        TextEditor(text: $personalMessageFirst)
                            .padding(4)
                            .border(Color.gray.opacity(0.25))
                            .cornerRadius(4)
                            .frame(maxWidth: .infinity)
                            .frame(height: 100)
                        
                        Spacer()
                            .frame(height: 8)
                        
                        Text("For personal message templates, use these placeholders:")
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
                    } header: {
                        Text("Personalized messages:")
                            .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            .padding(.horizontal)
                        
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
            .padding(.horizontal)
        }
        .padding()
        .frame(minWidth: 800)
        .onChange(of: theme) {
            setTheme(theme)
        }
        .onAppear(perform: {
            setTheme(theme)
        })
        .preferredColorScheme(isDarkModeOn ? .dark : .light)
    }

    private func setTheme(_ newTheme: Theme) {
        if newTheme == .notSet {
            isDarkModeOn = colorScheme == .dark
        } else {
            if let details = ThemeDetails[newTheme] {
                Color.currentTheme = details.colorTheme
                isDarkModeOn = details.darkTheme
                theme = newTheme
            }
        }
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

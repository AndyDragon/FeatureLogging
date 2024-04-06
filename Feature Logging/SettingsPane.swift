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
        ZStack {
            
            Color.BackgroundColor.edgesIgnoringSafeArea(.all)
            
            VStack(alignment: .leading) {
                Toggle(isOn: $includeHash) {
                    Text("Include '#' when copying tags to the clipboard:")
                }
                
                Spacer()
                    .frame(height: 8)
                
                HStack(alignment: .center) {
                    Text("Personal message: ")
                    TextField("", text: $personalMessage)
                        .focusable()
                        .autocorrectionDisabled(false)
                        .textFieldStyle(.plain)
                        .padding(4)
                        .background(Color.BackgroundColorEditor)
                        .border(Color.gray.opacity(0.25))
                        .cornerRadius(4)
                        .frame(maxWidth: .infinity)
                }
                
                Spacer()
                    .frame(height: 8)

                HStack(alignment: .center) {
                    Text("Personal message (first feature): ")
                    TextField("", text: $personalMessageFirst)
                        .focusable()
                        .autocorrectionDisabled(false)
                        .textFieldStyle(.plain)
                        .padding(4)
                        .background(Color.BackgroundColorEditor)
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

                Spacer()
                
                HStack {
                    Spacer()
                    
                    Button(action: {
                        dismiss()
                    }, label: {
                        HStack {
                            Text("Close")
                        }
                    })
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 800, minHeight: 260)
        .onChange(of: theme) {
            setTheme(theme)
        }
        .onAppear(perform: {
            setTheme(theme)
        })
        .preferredColorScheme(isDarkModeOn ? .dark : .light)
    }
    
    private func setTheme(_ newTheme: Theme) {
        if (newTheme == .notSet) {
            isDarkModeOn = colorScheme == .dark
        } else {
            if let details = ThemeDetails[newTheme] {
                Color.currentTheme = details.colorTheme
                isDarkModeOn = details.darkTheme
                theme = newTheme
            }
        }
    }
}

#Preview {
    SettingsPane()
}

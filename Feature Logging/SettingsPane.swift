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
    
    var body: some View {

        Color.BackgroundColor.edgesIgnoringSafeArea(.all)

        ZStack {
            Color.BackgroundColor.edgesIgnoringSafeArea(.all)
            VStack {
                Toggle(isOn: $includeHash) {
                    Text("Include '#' when copying tags to the clipboard:")
                }
                
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
            .frame(width: 400, height: 240)
            .padding()
        }
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

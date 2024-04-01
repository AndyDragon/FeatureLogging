//
//  Themes.swift
//  Feature Logging
//
//  Created by Andrew Forget on 2024-03-29.
//

import SwiftUI
import SystemColors

enum Theme: String, CaseIterable, Identifiable {
    case notSet,
         systemDark = "System dark",
         darkSubtleGray = "Dark subtle gray",
         darkBlue = "Dark blue",
         darkGreen = "Dark green",
         darkRed = "Dark red",
         darkViolet = "Dark violet",
         systemLight = "System light",
         lightSubtleGray = "Light subtle gray",
         lightBlue = "Light blue",
         lightGreen = "Light green",
         lightRed = "Light red",
         lightViolet = "Light violet"
    var id: Self { self }
}

var ThemeDetails: [Theme: (colorTheme: String, darkTheme: Bool)] = [
    Theme.systemDark: (colorTheme: "", darkTheme: true),
    Theme.darkSubtleGray: (colorTheme: "SubtleGray", darkTheme: true),
    Theme.darkBlue: (colorTheme: "Blue", darkTheme: true),
    Theme.darkGreen: (colorTheme: "Green", darkTheme: true),
    Theme.darkRed: (colorTheme: "Red", darkTheme: true),
    Theme.darkViolet: (colorTheme: "Violet", darkTheme: true),
    Theme.systemLight: (colorTheme: "", darkTheme: false),
    Theme.lightSubtleGray: (colorTheme: "SubtleGray", darkTheme: false),
    Theme.lightBlue: (colorTheme: "Blue", darkTheme: false),
    Theme.lightGreen: (colorTheme: "Green", darkTheme: false),
    Theme.lightRed: (colorTheme: "Red", darkTheme: false),
    Theme.lightViolet: (colorTheme: "Violet", darkTheme: false)
]

extension Color {
    static var isDarkModeOn = false
    static var currentTheme = ""
    
    static var theme: Color  {
        return Color("theme")
    }
    static var BackgroundColor: Color  {
        if currentTheme.isEmpty {
            return isDarkModeOn ? .underPageBackground : .windowBackground
        }
        return Color("\(currentTheme)/BackgroundColor")
    }
    static var BackgroundColorEditor: Color  {
        if currentTheme.isEmpty {
            return .controlBackground.opacity(0.5)
        }
        return Color("\(currentTheme)/BackgroundColorEditor")
    }
    static var BackgroundColorList: Color  {
        if currentTheme.isEmpty {
            return .controlBackground
        }
        return Color("\(currentTheme)/BackgroundColorList")
    }
    static var BackgroundColorListHover: Color  {
        if currentTheme.isEmpty {
            return Color(nsColor: .selectedContentBackgroundColor)
        }
        return Color("\(currentTheme)/BackgroundColorListHover")
    }
    static var BackgroundColorListSelected: Color  {
        if currentTheme.isEmpty {
            return Color(nsColor: .selectedContentBackgroundColor)
        }
        return Color("\(currentTheme)/BackgroundColorListSelected")
    }
    static var BackgroundColorNavigationBar: Color  {
        if currentTheme.isEmpty {
            return .windowBackground
        }
        return Color("\(currentTheme)/BackgroundColorNavigationBar")
    }
    static var ColorPrimary: Color  {
        if currentTheme.isEmpty {
            return .highlight
        }
        return Color("\(currentTheme)/ColorPrimary")
    }
    static var AccentColor: Color  {
        if currentTheme.isEmpty {
            return .accentColor
        }
        return Color("\(currentTheme)/AccentColor")
    }
    static var TextColorPrimary: Color  {
        if currentTheme.isEmpty {
            return .label
        }
        return Color("\(currentTheme)/TextColorPrimary")
    }
    static var TextColorRequired: Color  {
        if currentTheme.isEmpty {
            return .red
        }
        return Color("\(currentTheme)/TextColorRequired")
    }
    static var TextColorSecondary: Color  {
        if currentTheme.isEmpty {
            return .secondaryLabel
        }
        return Color("\(currentTheme)/TextColorSecondary")
    }
}

class Constants {
    public static let THEME = "THEME"
    public static let THEME_APP_STORE_KEY = "preference_theme"
}

class UserDefaultsUtils {
    static var shared = UserDefaultsUtils()
    
    func setTheme(theme: Theme) {
        UserDefaults.standard.set(theme.rawValue, forKey: Constants.THEME)
    }
    
    func getTheme() -> Theme {
        return Theme(rawValue: UserDefaults.standard.string(forKey: Constants.THEME) ?? Theme.systemDark.rawValue) ?? Theme.systemDark
    }
}

//
//  Themes.swift
//  Feature Logging
//
//  Created by Andrew Forget on 2024-03-29.
//

import SwiftUI
import SystemColors

enum Theme: String, CaseIterable, Identifiable {
    case notSet
    case
        systemDark = "System dark"
    case
        darkSubtleGray = "Dark subtle gray"
    case
        darkBlue = "Dark blue"
    case
        darkGreen = "Dark green"
    case
        darkRed = "Dark red"
    case
        darkViolet = "Dark violet"
    case
        systemLight = "System light"
    case
        lightSubtleGray = "Light subtle gray"
    case
        lightBlue = "Light blue"
    case
        lightGreen = "Light green"
    case
        lightRed = "Light red"
    case
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
    Theme.lightViolet: (colorTheme: "Violet", darkTheme: false),
]

extension Color {
    static var isDarkModeOn = false
    static var currentTheme = ""

    static var theme: Color {
        return Color("theme")
    }
    static var BackgroundColor: Color {
        if currentTheme.isEmpty {
#if os(macOS)
            return isDarkModeOn ? .underPageBackground : .windowBackground
#else
            return .backgroundColor
#endif
        }
        return Color("\(currentTheme)/BackgroundColor")
    }
    static var BackgroundColorEditor: Color {
        if currentTheme.isEmpty {
#if os(macOS)
            return .controlBackground.opacity(0.5)
#else
            return .backgroundColor.opacity(0.5)
#endif
        }
        return Color("\(currentTheme)/BackgroundColorEditor")
    }
    static var BackgroundColorList: Color {
        if currentTheme.isEmpty {
#if os(macOS)
            return .controlBackground
#else
            return .secondaryBackgroundColor
#endif
        }
        return Color("\(currentTheme)/BackgroundColorList")
    }
    static var BackgroundColorListHover: Color {
        if currentTheme.isEmpty {
#if os(macOS)
            return Color(nsColor: .selectedContentBackgroundColor)
#else
            return .secondaryBackgroundColor.opacity(0.3)
#endif
        }
        return Color("\(currentTheme)/BackgroundColorListHover")
    }
    static var BackgroundColorListSelected: Color {
        if currentTheme.isEmpty {
#if os(macOS)
            return Color(nsColor: .selectedContentBackgroundColor)
#else
            return .secondaryBackgroundColor
#endif
        }
        return Color("\(currentTheme)/BackgroundColorListSelected")
    }
    static var BackgroundColorNavigationBar: Color {
        if currentTheme.isEmpty {
#if os(macOS)
            return .windowBackground
#else
            return .secondaryBackgroundColor
#endif
        }
        return Color("\(currentTheme)/BackgroundColorNavigationBar")
    }
    static var ColorPrimary: Color {
        if currentTheme.isEmpty {
#if os(macOS)
            return .highlight
#else
            return .accentColor
#endif
        }
        return Color("\(currentTheme)/ColorPrimary")
    }
    static var AccentColor: Color {
        if currentTheme.isEmpty {
            return .accentColor
        }
        return Color("\(currentTheme)/AccentColor")
    }
    static var TextColorPrimary: Color {
        if currentTheme.isEmpty {
            return .label
        }
        return Color("\(currentTheme)/TextColorPrimary")
    }
    static var TextColorRequired: Color {
        if currentTheme.isEmpty {
            return .red
        }
        return Color("\(currentTheme)/TextColorRequired")
    }
    static var TextColorSecondary: Color {
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

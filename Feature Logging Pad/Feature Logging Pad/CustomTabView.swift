//
//  CustomTabView.swift
//  Feature Logging
//
//  Created by Andrew Forget on 2024-12-03.
//

import SwiftUI

public extension Color {
#if os(macOS)
    static let backgroundColor = Color(NSColor.windowBackgroundColor)
    static let secondaryBackgroundColor = Color(NSColor.controlBackgroundColor)
#else
    static let backgroundColor = Color(UIColor.systemBackground)
    static let secondaryBackgroundColor = Color(UIColor.secondarySystemBackground)
#endif
}

public struct CustomTabView: View {
    
    public enum TabBarPosition { // Where the tab bar will be located within the view
        case top
        case bottom
    }
    
    private let tabBarPosition: TabBarPosition
    private let tabText: [String]
    private let tabIconNames: [String]
    private let tabIconColors: [(Color, Color)]
    private let tabViews: [AnyView]
    
    @State private var selection = 0
    
    public init(
        tabBarPosition: TabBarPosition,
        content: [(
            tabText: String,
            tabIconName: String,
            tabIconColors: (Color, Color),
            view: AnyView)]
    ) {
        self.tabBarPosition = tabBarPosition
        self.tabText = content.map { $0.tabText }
        self.tabIconNames = content.map { $0.tabIconName }
        self.tabIconColors = content.map { $0.tabIconColors }
        self.tabViews = content.map { $0.view }
    }
    
    public var tabBar: some View {
        VStack {
            Spacer()
                .frame(height: 5.0)
            HStack {
                ForEach(Array(tabText.enumerated()), id: \.offset) { index, item in
                    HStack(alignment: .center) {
                        Image(systemName: tabIconNames[index])
                            .font(.system(size: 24))
                            .foregroundStyle(selection == index ? tabIconColors[index].0 : .primary, selection == index ? tabIconColors[index].1 : .secondary)
                        Text(tabText[index])
                    }
                    .padding([.top, .bottom], 4)
                    .padding([.leading, .trailing], 10)
                    .foregroundColor(selection == index ? Color.accentColor : Color.primary)
                    .onTapGesture {
                        selection = index
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(selection == index ? Color.backgroundColor.opacity(0.5) : Color.red.opacity(0.0))
                    )
                    .onTapGesture {
                        selection = index
                    }
                    
                }
                Spacer()
            }
            .frame(alignment: .leading)
            .padding(2)
        }
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            if (tabBarPosition == .top) {
                tabBar
            }
            
            tabViews[selection]
                .padding(0)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            
            if (tabBarPosition == .bottom) {
                tabBar
            }
        }
        .padding(0)
    }
}

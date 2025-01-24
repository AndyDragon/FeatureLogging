//
//  AboutView.swift
//  Feature Logging
//
//  Created by Andrew Forget on 2025-01-11.
//

import SwiftUI
import SwiftyBeaver

struct AboutView: View {
    // THEME
    @Environment(\.colorScheme) private var colorScheme: ColorScheme
    @State private var isDarkModeOn = true

    @Environment(\.dismissWindow) var dismissWindow

    @State private var showCredits = false
    @State private var loggedDisclosure = false

    let packages: [String: [String]]

    private let year = Calendar(identifier: .gregorian).dateComponents([.year], from: Date()).year ?? 2024
    private let logger = SwiftyBeaver.self

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160, height: 160)
                    .padding(.leading, 30)
                VStack(alignment: .center) {
                    Text(Bundle.main.displayName ?? "App")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Version \(Bundle.main.releaseVersionNumberPretty)")
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("AndyDragon Software")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(Color(red: 0.1, green: 0.5, blue: 0.6))
                    Text("Copyright © 2024\((year > 2024) ? "-\(year)" : "")")
                        .font(.title3)
                        .foregroundStyle(Color(red: 0.1, green: 0.5, blue: 0.6))
                    Text("All rights reserved.")
                        .font(.title3)
                        .foregroundStyle(Color(red: 0.1, green: 0.5, blue: 0.6))
                }
                .frame(maxWidth: .infinity)
            }
            .padding(20)
            .padding(.vertical, showCredits ? 15 : 74)
            .frame(maxWidth: .infinity)
            .background(isDarkModeOn ? .white.opacity(0.08) : .black.opacity(0.08))
            .background(isDarkModeOn ? .black : .white)
            .foregroundStyle(isDarkModeOn ? .white : .black)

            VStack {
                HStack(alignment: .center) {
                    Spacer()
                    Text(showCredits ? "This app uses the following packages / code:" : "")
                        .font(.footnote)
                        .fontWeight(.bold)
                        .foregroundStyle(isDarkModeOn ? Color(red: 0.5, green: 0.1, blue: 0.6) : Color(red: 0.8, green: 0.4, blue: 0.9))
                        .animation(.easeIn(duration: showCredits ? 1.6 : 0).delay(showCredits ? 0.1 : 0), value: showCredits)
                        .padding(.top, 4)
                    Spacer()
                    Button {
                        withAnimation {
                            showCredits.toggle()
                        }
                        if !loggedDisclosure && showCredits {
                            loggedDisclosure.toggle()
                            logger.verbose("Disclosed the credit in about view", context: "User")
                        }
                    } label: {
                        Triangle()
                            .fill(isDarkModeOn ? (showCredits ? .black : .white) : (showCredits ? .white : .black))
                            .frame(width: 12, height: 12)
                            .rotationEffect(.degrees(showCredits ? -180.0 : -90.0), anchor: .center)
                    }
                    .buttonStyle(.borderless)
                    .padding(.top, 8)
                    .help(showCredits ? "Hide the credits" : "Show the credits")
                }
                .padding(.horizontal)
                .padding(.bottom, 10)
                Grid(alignment: .leadingFirstTextBaseline) {
                    ForEach(packages.sorted(by: { $0.key.lowercased() < $1.key.lowercased() }), id: \.key) { key, value in
                        GridRow {
                            Text(key)
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(isDarkModeOn ? .black : .white)
                                .gridColumnAlignment(.trailing)
                            VStack(alignment: .leading) {
                                ForEach(value, id: \.self) { author in
                                    Text(.init(author))
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundStyle(isDarkModeOn ? .black : .white)
                                }
                            }
                            .gridColumnAlignment(.leading)
                        }
                    }
                }
                .opacity(showCredits ? 1 : 0)
                .animation(.easeIn(duration: showCredits ? 1 : 0).delay(showCredits ? 0.4 : 0), value: showCredits)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: showCredits ? 240 : 20)
            .background(isDarkModeOn ? .white.opacity(showCredits ? 0.9 : 0.08) : .black.opacity(showCredits ? 0.9 : 0.08))
            .background(isDarkModeOn ? .black : .white)

            HStack {
                Spacer()
                Button {
                    dismissWindow(id: "about")
                } label: {
                    Text("Close")
                        .foregroundStyle(isDarkModeOn ? .black : .black)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 16)
                }
                .background(.gray)
                .cornerRadius(4)
                .padding([.bottom, .trailing], 20)
            }
            .frame(maxWidth: .infinity)
            .padding(.top)
        }
        .frame(width: 600, height: 400)
        .frame(minWidth: 600, maxWidth: 600, minHeight: 420, maxHeight: 420)
        .background(isDarkModeOn ? .white.opacity(0.9) : .black.opacity(0.9))
        .background(isDarkModeOn ? .black : .white)
        .onAppear {
            updateTheme()
        }
        .onChange(of: colorScheme) {
            updateTheme()
        }
        .testBackground()
    }
}

extension AboutView {
    // MARK: - utilities

    private func updateTheme() {
        isDarkModeOn = colorScheme == .dark
    }
}

// MARK: - preview

#Preview {
    AboutView(packages: ["Application": ["AndyDragon ([Github profile](https://github.com/AndyDragon))"]])
}

// MARK: - utility types

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))

        return path
    }
}

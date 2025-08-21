//
//  RangeSlider.swift
//  Feature Logging
//
//  Created by Andrew Forget on 2025-08-21.
//

import SwiftUI

struct RangeSlider: View {
    @Binding var lowerValue: Double
    @Binding var upperValue: Double
    @State private var lowerLast: Double = 0.0
    @State private var upperLast: Double = 1.0
    @State private var updating: Bool = false
    @State var onClampValue: (Double) -> Double = { value in value }

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.gray.opacity(0.2))
            .frame(height: 4)
            .overlay {
                GeometryReader { geometry in
                    ZStack {
                        RangeSliderFilledTrack()
                            .frame(width: geometry.size.width * (upperValue - lowerValue))
                            .position(CGPoint(x: (upperValue + lowerValue) / 2 * (geometry.size.width - 2 * RangeSliderHandle.size) + RangeSliderHandle.size, y: 2.0))
                        RangeSliderHandle()
                            .position(CGPoint(x: RangeSliderHandle.size / 2 + lowerValue * (geometry.size.width - 2 * RangeSliderHandle.size), y: 2.0))
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        updating = true
                                        let x = RangeSliderHandle.size
                                        lowerValue = onClampValue(min(max(lowerLast + value.translation.width / (geometry.size.width - 2 * x), 0), upperLast))
                                    }
                                    .onEnded { value in
                                        let x = RangeSliderHandle.size
                                        lowerValue = onClampValue(min(max(lowerLast + value.translation.width / (geometry.size.width - 2 * x), 0), upperLast))
                                        lowerLast = lowerValue
                                        updating = false
                                    }
                            )
                            .onChange(of: lowerValue) { _, newValue in
                                if !updating {
                                    lowerLast = newValue
                                }
                            }

                        RangeSliderHandle()
                            .position(CGPoint(x: 3.0 * RangeSliderHandle.size / 2.0 +  upperValue * (geometry.size.width - 2 * RangeSliderHandle.size), y: 2.0))
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        updating = true
                                        let x = RangeSliderHandle.size
                                        upperValue = onClampValue(min(max(upperLast + value.translation.width / (geometry.size.width - 2 * x), lowerLast), 1))
                                    }
                                    .onEnded { value in
                                        let x = RangeSliderHandle.size
                                        upperValue = onClampValue(min(max(upperLast + value.translation.width / (geometry.size.width - 2 * x), lowerLast), 1))
                                        upperLast = upperValue
                                        updating = false
                                    }
                            )
                            .onChange(of: upperValue) { _, newValue in
                                if !updating {
                                    upperLast = newValue
                                }
                            }
                    }
                }
            }
            .onAppear {
                lowerLast = lowerValue
                upperLast = upperValue
            }
    }
}

struct RangeSliderFilledTrack: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(LinearGradient(gradient: Gradient(colors: [Color(red: 9/255, green: 124/255, blue: 245/255), Color(red: 9/255, green: 126/255, blue: 248/255)]), startPoint: .top, endPoint: .bottom))
            .frame(height: 4)
    }
}

struct RangeSliderHandle: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var isPressed = false
    private let lightDefault = Color.white
    private let lightPressed = Color(red: 240/255, green: 240/255, blue: 240/255)
    private let darkDefault = Color.gray
    private let darkPressed = Color(red: 174/255, green: 174/255, blue: 174/255)
    static let size: CGFloat = 20
    
    var body: some View {
        Circle()
            .fill(colorScheme == .dark ? (isPressed ? darkPressed : darkDefault) : (isPressed ? lightPressed : lightDefault))
            .frame(width: Self.size, height: Self.size)
            .shadow(radius: 1, y: 0.5)
        
    }
}

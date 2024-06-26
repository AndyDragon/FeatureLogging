//
//  ValidationLabel.swift
//  Feature Logging
//
//  Created by Andrew Forget on 2024-04-05.
//

import SwiftUI

struct ValidationLabel: View {
    let label: String
    let labelWidth: CGFloat?
    let validation: Bool
    
    init(_ label: String, labelWidth: Double, validation: Bool) {
        self.label = label
        self.labelWidth = labelWidth
        self.validation = validation
    }
    
    init(_ label: String, validation: Bool) {
        self.label = label
        self.labelWidth = nil
        self.validation = validation
    }

    var body: some View {
        if let width = labelWidth {
            HStack(alignment: .center) {
                if !validation {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.AccentColor, Color.TextColorRequired)
                        .imageScale(.small)
                }
                Text(label)
                    .padding([.trailing], 8)
                    .foregroundStyle(!validation ? Color.TextColorRequired : Color.TextColorPrimary, Color.TextColorSecondary)
            }
            .frame(width: width, alignment: .trailing)
        } else {
            HStack(alignment: .center) {
                if !validation {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.AccentColor, Color.TextColorRequired)
                        .imageScale(.small)
                }
                Text(label)
                    .padding([.trailing], 8)
                    .foregroundStyle(!validation ? Color.TextColorRequired : Color.TextColorPrimary, Color.TextColorSecondary)
            }
        }
    }
}

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
    let validColor: Color?
    
    init(_ label: String, labelWidth: Double, validation: Bool) {
        self.label = label
        self.labelWidth = labelWidth
        self.validation = validation
        self.validColor = nil
    }
    
    init(_ label: String, labelWidth: Double, validation: Bool, validColor: Color) {
        self.label = label
        self.labelWidth = labelWidth
        self.validation = validation
        self.validColor = validColor
    }
    
    init(_ label: String, validation: Bool) {
        self.label = label
        self.labelWidth = nil
        self.validation = validation
        self.validColor = nil
    }
    
    init(_ label: String, validation: Bool, validColor: Color) {
        self.label = label
        self.labelWidth = nil
        self.validation = validation
        self.validColor = validColor
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
                    .foregroundStyle(!validation ? Color.TextColorRequired : (validColor ?? Color.TextColorPrimary), Color.TextColorSecondary)
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
                    .foregroundStyle(!validation ? Color.TextColorRequired : (validColor ?? Color.TextColorPrimary), Color.TextColorSecondary)
            }
        }
    }
}

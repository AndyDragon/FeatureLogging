//
//  ValidationLabel.swift
//  Feature Logging
//
//  Created by Andrew Forget on 2024-04-05.
//

import SwiftUI

struct ValidationLabel: View {
    let label: String?
    let labelWidth: CGFloat?
    let validation: Bool
    let validColor: Color?

    init(validation: Bool) {
        self.label = nil
        self.labelWidth = nil
        self.validation = validation
        self.validColor = nil
    }

    init(_ label: String?, validation: Bool) {
        self.label = label
        self.labelWidth = nil
        self.validation = validation
        self.validColor = nil
    }

    init(_ label: String?, labelWidth: Double, validation: Bool) {
        self.label = label
        self.labelWidth = labelWidth
        self.validation = validation
        self.validColor = nil
    }

    init(validation: Bool, validColor: Color) {
        self.label = nil
        self.labelWidth = nil
        self.validation = validation
        self.validColor = validColor
    }

    init(_ label: String?, validation: Bool, validColor: Color) {
        self.label = label
        self.labelWidth = nil
        self.validation = validation
        self.validColor = validColor
    }

    init(_ label: String?, labelWidth: Double, validation: Bool, validColor: Color) {
        self.label = label
        self.labelWidth = labelWidth
        self.validation = validation
        self.validColor = validColor
    }

    var body: some View {
        if let width = labelWidth {
            HStack(alignment: .center) {
                if !validation {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.accentColor, Color.red)
                        .imageScale(.small)
                }
                if let label {
                    Text(label)
                        .padding([.trailing], 8)
                        .foregroundStyle(!validation ? Color.red : (validColor ?? Color.label), Color.secondaryLabel)
                }
            }
            .frame(width: abs(width), alignment: width < 0 ? .leading : .trailing)
        } else {
            HStack(alignment: .center) {
                if !validation {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.accentColor, Color.red)
                        .imageScale(.small)
                }
                if let label {
                    Text(label)
                        .padding([.trailing], 8)
                        .foregroundStyle(!validation ? Color.red : (validColor ?? Color.label), Color.secondaryLabel)
                }
            }
        }
    }
}

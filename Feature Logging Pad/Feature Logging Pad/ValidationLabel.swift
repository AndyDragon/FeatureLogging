//
//  ValidationLabel.swift
//  Feature Logging
//
//  Created by Andrew Forget on 2024-04-05.
//

import SwiftUI

enum ValidationResult {
    case Success
    case Warning
    case Failure
}

extension ValidationResult {
    static func fromBool(_ value: Bool, _ isWarning: Bool = false) -> Self {
        return value ? .Success : isWarning ? .Warning : .Failure
    }
    
    func getColor(_ validColor: Color? = nil) -> Color {
        switch self
        {
        case .Success:
            return validColor ?? Color(UIColor.label)
        case .Warning:
            return Color.orange
        default:
            return Color.red
        }
    }
    
    func getImage() -> AnyView {
        switch self
        {
        case .Success:
            return AnyView(Color.black)
            
        case .Warning:
            return AnyView(
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color.black, self.getColor())
                    .imageScale(.small)
            )
            
        default:
            return AnyView(
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color.white, self.getColor())
                    .imageScale(.small)
            )
        }
    }
}

struct ValidationLabel: View {
    let label: String?
    let labelWidth: CGFloat?
    let validation: ValidationResult
    let validColor: Color?
    
    init(validation: Bool, isWarning: Bool = false) {
        self.init(validation: ValidationResult.fromBool(validation, isWarning))
    }

    init(validation: ValidationResult) {
        self.label = nil
        self.labelWidth = nil
        self.validation = validation
        self.validColor = nil
    }

    init(_ label: String?, validation: Bool, isWarning: Bool = false) {
        self.init(label, validation: ValidationResult.fromBool(validation, isWarning))
    }
    
    init(_ label: String?, validation: ValidationResult) {
        self.label = label
        self.labelWidth = nil
        self.validation = validation
        self.validColor = nil
    }

    init(_ label: String?, labelWidth: Double, validation: Bool, isWarning: Bool = false) {
        self.init(label, labelWidth: labelWidth, validation: ValidationResult.fromBool(validation, isWarning))
    }
    
    init(_ label: String?, labelWidth: Double, validation: ValidationResult) {
        self.label = label
        self.labelWidth = labelWidth
        self.validation = validation
        self.validColor = nil
    }

    init(validation: Bool, isWarning: Bool = false, validColor: Color) {
        self.init(validation: ValidationResult.fromBool(validation, isWarning), validColor: validColor)
    }

    init(validation: ValidationResult, validColor: Color) {
        self.label = nil
        self.labelWidth = nil
        self.validation = validation
        self.validColor = validColor
    }

    init(_ label: String?, validation: Bool, isWarning: Bool = false, validColor: Color) {
        self.init(label, validation: ValidationResult.fromBool(validation, isWarning), validColor: validColor)
    }
    
    init(_ label: String?, validation: ValidationResult, validColor: Color) {
        self.label = label
        self.labelWidth = nil
        self.validation = validation
        self.validColor = validColor
    }

    init(_ label: String?, labelWidth: Double, validation: Bool, isWarning: Bool = false, validColor: Color) {
        self.init(label, labelWidth: labelWidth, validation: ValidationResult.fromBool(validation, isWarning), validColor: validColor)
    }

    init(_ label: String?, labelWidth: Double, validation: ValidationResult, validColor: Color) {
        self.label = label
        self.labelWidth = labelWidth
        self.validation = validation
        self.validColor = validColor
    }

    var body: some View {
        if let width = labelWidth {
            HStack(alignment: .center) {
                if validation != .Success {
                    validation.getImage()
                }
                if let label {
                    Text(label)
                        .padding([.trailing], 8)
                        .foregroundStyle(
                            validation.getColor(validColor),
                            Color(UIColor.secondaryLabel)
                        )
                }
            }
            .frame(width: abs(width), alignment: width < 0 ? .leading : .trailing)
        } else {
            HStack(alignment: .center) {
                if validation != .Success {
                    validation.getImage()
                }
                if let label {
                    Text(label)
                        .padding([.trailing], 8)
                        .foregroundStyle(
                            validation.getColor(validColor),
                            Color(UIColor.secondaryLabel)
                        )
                }
            }
        }
    }
}

//
//  ValidationLabel.swift
//  Feature Logging
//
//  Created by Andrew Forget on 2024-04-05.
//

import SwiftUI

enum ValidationResult: Equatable {
    case valid
    case warning(_ message: String?)
    case error(_ message: String?)
}

extension ValidationResult {
    static func fromBool(_ value: Bool, _ message: String? = nil, _ isWarning: Bool = false) -> Self {
        return value ? .valid : isWarning ? .warning(message) : .error(message)
    }
    
    var isError: Bool {
        switch self {
        case .error:
            return true
        default:
            return false
        }
    }

    func getColor(_ validColor: Color? = nil) -> Color {
        switch self {
        case .valid:
            return validColor ?? Color(UIColor.label)
        case .warning:
            return Color.orange
        default:
            return Color.red
        }
    }
    
    var message: String? {
        switch self {
        case .valid:
            return nil
        case let .warning(message):
            return message
        case let .error(message):
            return message
        }
    }

    var unwrappedMessage: String {
        switch self {
        case .valid:
            return ""
        case let .warning(message):
            return message ?? ""
        case let .error(message):
            return message ?? ""
        }
    }

    func getImage(small: Bool = false) -> AnyView {
        switch self {
        case .valid:
            return AnyView(Color.black)

        case .warning:
            if small {
                return AnyView(
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 13))
                        .frame(width: 14, height: 16)
                        .foregroundStyle(Color.black, getColor())
                        .imageScale(.small)
                        .help(unwrappedMessage)
                )
            } else {
                return AnyView(
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.black, getColor())
                        .imageScale(.small)
                        .help(unwrappedMessage)
                )
            }

        case .error:
            if small {
                return AnyView(
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 13))
                        .frame(width: 14, height: 16)
                        .foregroundStyle(Color.white, getColor())
                        .imageScale(.small)
                        .help(unwrappedMessage)
                )
            } else {
                return AnyView(
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.white, getColor())
                        .imageScale(.small)
                        .help(unwrappedMessage)
                )
            }
        }
    }
}

struct ValidationLabel: View {
    let label: String?
    let labelWidth: CGFloat?
    let validation: ValidationResult
    let validColor: Color?

    init(validation: Bool, message: String? = nil, isWarning: Bool = false) {
        self.init(validation: ValidationResult.fromBool(validation, message, isWarning))
    }

    init(validation: ValidationResult) {
        label = nil
        labelWidth = nil
        self.validation = validation
        validColor = nil
    }

    init(_ label: String?, validation: Bool, message: String? = nil, isWarning: Bool = false) {
        self.init(label, validation: ValidationResult.fromBool(validation, message, isWarning))
    }

    init(_ label: String?, validation: ValidationResult) {
        self.label = label
        labelWidth = nil
        self.validation = validation
        validColor = nil
    }

    init(_ label: String?, labelWidth: Double, validation: Bool, message: String? = nil, isWarning: Bool = false) {
        self.init(label, labelWidth: labelWidth, validation: ValidationResult.fromBool(validation, message, isWarning))
    }

    init(_ label: String?, labelWidth: Double, validation: ValidationResult) {
        self.label = label
        self.labelWidth = labelWidth
        self.validation = validation
        validColor = nil
    }

    init(validation: Bool, message: String? = nil, isWarning: Bool = false, validColor: Color) {
        self.init(validation: ValidationResult.fromBool(validation, message, isWarning), validColor: validColor)
    }

    init(validation: ValidationResult, validColor: Color) {
        label = nil
        labelWidth = nil
        self.validation = validation
        self.validColor = validColor
    }

    init(_ label: String?, validation: Bool, message: String? = nil, isWarning: Bool = false, validColor: Color) {
        self.init(label, validation: ValidationResult.fromBool(validation, message, isWarning), validColor: validColor)
    }

    init(_ label: String?, validation: ValidationResult, validColor: Color) {
        self.label = label
        labelWidth = nil
        self.validation = validation
        self.validColor = validColor
    }

    init(_ label: String?, labelWidth: Double, validation: Bool, message: String? = nil, isWarning: Bool = false, validColor: Color) {
        self.init(label, labelWidth: labelWidth, validation: ValidationResult.fromBool(validation, message, isWarning), validColor: validColor)
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
                if validation != .valid {
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
                if validation != .valid {
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

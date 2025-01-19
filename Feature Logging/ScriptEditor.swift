//
//  ScriptEditor.swift
//  Feature Logging
//
//  Created by Andrew Forget on 2024-02-10.
//

import SwiftUI

struct ScriptEditor: View {
    var title: String
    @Binding var script: String
    var minHeight: CGFloat
    var maxHeight: CGFloat
    var canCopy: Bool
    var hasPlaceholders: Bool
    var copy: (Bool, Bool) -> Void
    var focusedField: FocusState<FocusField?>.Binding
    var editorFocusField: FocusField
    var buttonFocusField: FocusField

    var body: some View {
        // Header
        HStack {
            Text(title)

            Button(
                action: {
                    copy(true, false)
                },
                label: {
                    Text("Copy")
                        .padding(.horizontal, 20)
                }
            )
            .disabled(!canCopy)
            .focusable()
            .focused(focusedField, equals: buttonFocusField)
            .onKeyPress(.space) {
                if canCopy {
                    copy(true, false)
                }
                return .handled
            }

            Button(
                action: {
                    copy(false, true)
                },
                label: {
                    Text("Copy (with Placeholders)")
                        .padding(.horizontal, 20)
                }
            )
            .disabled(!hasPlaceholders)
            .focusable()
            .onKeyPress(.space) {
                if hasPlaceholders {
                    copy(false, false)
                }
                return .handled
            }

            Spacer()
        }
        .frame(alignment: .leading)
        .padding([.top], 4)

        // Editor
        if #available(macOS 14.0, *) {
            TextEditor(text: $script)
                .font(.system(size: 14))
                .frame(minWidth: 200, maxWidth: .infinity, minHeight: minHeight, maxHeight: maxHeight)
                .focused(focusedField, equals: editorFocusField)
                .textEditorStyle(.plain)
                .foregroundStyle(canCopy ? Color.TextColorPrimary : Color.TextColorRequired, Color.TextColorSecondary)
                .scrollContentBackground(.hidden)
                .padding(4)
                .background(Color.BackgroundColorEditor)
                .border(Color.gray.opacity(0.25))
                .cornerRadius(4)
                .padding([.bottom], 6)
                .autocorrectionDisabled(false)
                .disableAutocorrection(false)
        } else {
            TextEditor(text: $script)
                .font(.system(size: 14))
                .frame(minWidth: 200, maxWidth: .infinity, minHeight: minHeight, maxHeight: maxHeight)
                .focused(focusedField, equals: editorFocusField)
                .foregroundStyle(canCopy ? Color.TextColorPrimary : Color.TextColorRequired, Color.TextColorSecondary)
                .scrollContentBackground(.hidden)
                .padding(4)
                .background(Color.BackgroundColorEditor)
                .border(Color.gray.opacity(0.25))
                .cornerRadius(4)
                .padding([.bottom], 6)
                .autocorrectionDisabled(false)
                .disableAutocorrection(false)
        }
    }
}

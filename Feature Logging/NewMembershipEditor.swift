//
//  NewMembershipEditor.swift
//  Feature Logging
//
//  Created by Andrew Forget on 2024-02-10.
//

import SwiftUI

struct NewMembershipEditor: View {
    @Binding var newMembership: NewMembershipCase
    @Binding var script: String
    @Binding var currentPage: LoadedPage?
    var minHeight: CGFloat
    var maxHeight: CGFloat
    var onChanged: (NewMembershipCase) -> Void
    var valid: Bool
    var canCopy: Bool
    var copy: () -> Void
    var focusedField: FocusState<FocusField?>.Binding
    var editorFocusField: FocusField
    var pickerFocusField: FocusField
    var buttonFocusField: FocusField

    var body: some View {
        HStack {
            Text("New membership:")

            Picker("", selection: $newMembership.onChange { value in
                navigateToNewMembership(.same)
                onChanged(value)
            }) {
                ForEach(NewMembershipCase.casesFor(hub: currentPage?.hub)) { level in
                    Text(level.rawValue)
                        .tag(level)
                        .foregroundStyle(Color.TextColorPrimary, Color.TextColorSecondary)
                }
            }
            .tint(Color.AccentColor)
            .accentColor(Color.AccentColor)
            .foregroundStyle(Color.AccentColor, Color.TextColorPrimary)
            .frame(width: 320)
            .focusable()
            .focused(focusedField, equals: pickerFocusField)
            .onKeyPress(phases: .down) { keyPress in
                let direction = directionFromModifiers(keyPress)
                if direction != .same {
                    navigateToNewMembership(direction)
                    return .handled
                }
                return .ignored
            }

            Button(
                action: {
                    copy()
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
                    copy()
                }
                return .handled
            }

            Spacer()
        }
        .frame(alignment: .leading)
        .padding([.top], 4)

        if #available(macOS 14.0, *) {
            TextEditor(text: $script)
                .font(.system(size: 14))
                .frame(minWidth: 200, maxWidth: .infinity, minHeight: minHeight, maxHeight: maxHeight)
                .focused(focusedField, equals: editorFocusField)
                .focusable()
                .textEditorStyle(.plain)
                .foregroundStyle(valid ? Color.TextColorPrimary : Color.TextColorRequired, Color.TextColorSecondary)
                .scrollContentBackground(.hidden)
                .padding(4)
                .background(Color.BackgroundColorEditor)
                .border(Color.gray.opacity(0.25))
                .cornerRadius(4)
                .autocorrectionDisabled(false)
                .disableAutocorrection(false)
        } else {
            TextEditor(text: $script)
                .font(.system(size: 14))
                .frame(minWidth: 200, maxWidth: .infinity, minHeight: minHeight, maxHeight: maxHeight)
                .focused(focusedField, equals: editorFocusField)
                .focusable()
                .foregroundStyle(valid ? Color.TextColorPrimary : Color.TextColorRequired, Color.TextColorSecondary)
                .scrollContentBackground(.hidden)
                .padding(4)
                .background(Color.BackgroundColorEditor)
                .border(Color.gray.opacity(0.25))
                .cornerRadius(4)
                .autocorrectionDisabled(false)
                .disableAutocorrection(false)
        }
    }
    
    private func navigateToNewMembership(_ direction: Direction) {
        let result = navigateGeneric(NewMembershipCase.casesFor(hub: currentPage?.hub), newMembership, direction)
        if result.0 {
            if direction != .same {
                newMembership = result.1
            }
            onChanged(newMembership)
        }
    }
}

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
    var selectedPage: ObservablePage
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
                ForEach(NewMembershipCase.casesFor(hub: selectedPage.hub)) { level in
                    Text(level.scriptNewMembershipStringForHub(hub: selectedPage.hub))
                        .tag(level)
                        .foregroundStyle(Color.label, Color.secondaryLabel)
                }
            }
            .tint(Color.accentColor)
            .accentColor(Color.accentColor)
            .foregroundStyle(Color.accentColor, Color.label)
            .frame(width: 320)
            .focusable()
            .focused(focusedField, equals: pickerFocusField)
            .onKeyPress(phases: .down) { keyPress in
                return navigateToNewMembershipWithArrows(keyPress)
            }
            .onKeyPress(characters: .alphanumerics) { keyPress in
                return navigateToNewMembershipWithPrefix(keyPress)
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
                .textEditorStyle(.plain)
                .foregroundStyle(valid ? Color.label : Color.red, Color.secondaryLabel)
                .scrollContentBackground(.hidden)
                .padding(4)
                .background(Color.controlBackground.opacity(0.5))
                .border(Color.gray.opacity(0.25))
                .cornerRadius(4)
                .autocorrectionDisabled(false)
                .disableAutocorrection(false)
        } else {
            TextEditor(text: $script)
                .font(.system(size: 14))
                .frame(minWidth: 200, maxWidth: .infinity, minHeight: minHeight, maxHeight: maxHeight)
                .focused(focusedField, equals: editorFocusField)
                .foregroundStyle(valid ? Color.label : Color.red, Color.secondaryLabel)
                .scrollContentBackground(.hidden)
                .padding(4)
                .background(Color.controlBackground.opacity(0.5))
                .border(Color.gray.opacity(0.25))
                .cornerRadius(4)
                .autocorrectionDisabled(false)
                .disableAutocorrection(false)
        }
    }
    
    // MARK: - new membership navigation
    
    private func navigateToNewMembership(_ direction: Direction) {
        let (change, newValue) = navigateGeneric(NewMembershipCase.casesFor(hub: selectedPage.hub), newMembership, direction)
        if change {
            if direction != .same {
                newMembership = newValue
            }
            onChanged(newMembership)
        }
    }

    private func navigateToNewMembershipWithArrows(_ keyPress: KeyPress) -> KeyPress.Result {
        let direction = directionFromModifiers(keyPress)
        if direction != .same {
            navigateToNewMembership(direction)
            return .handled
        }
        return .ignored
    }

    private func navigateToNewMembershipWithPrefix(_ keyPress: KeyPress) -> KeyPress.Result {
        let (change, newValue) = navigateGenericWithPrefix(NewMembershipCase.casesFor(hub: selectedPage.hub), newMembership, keyPress.characters.lowercased())
        if change {
            newMembership = newValue
            onChanged(newMembership)
            return .handled
        }
        return .ignored
    }
}

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

    var body: some View {
        HStack {
            Text("New membership:")

            Picker("", selection: $newMembership.onChange { value in
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

            Button(action: {
                copy()
            }) {
                Text("Copy")
                    .padding(.horizontal, 20)
            }
            .disabled(!canCopy)
            .buttonStyle(.bordered)

            Spacer()
        }
        .frame(alignment: .leading)
        .padding([.top], 4)

        if #available(macOS 14.0, *) {
            TextEditor(text: $script)
                .font(.system(size: 14))
                .frame(minWidth: 200, maxWidth: .infinity, minHeight: minHeight, maxHeight: maxHeight)
                .textEditorStyle(.plain)
                .foregroundStyle(valid ? Color.label : Color.red, Color.secondaryLabel)
                .scrollContentBackground(.hidden)
                .padding(4)
                .background(Color.backgroundColor.opacity(0.5))
                .border(Color.gray.opacity(0.25))
                .cornerRadius(4)
                .autocorrectionDisabled(false)
                .disableAutocorrection(false)
        } else {
            TextEditor(text: $script)
                .font(.system(size: 14))
                .frame(minWidth: 200, maxWidth: .infinity, minHeight: minHeight, maxHeight: maxHeight)
                .foregroundStyle(valid ? Color.label : Color.red, Color.secondaryLabel)
                .scrollContentBackground(.hidden)
                .padding(4)
                .background(Color.backgroundColor.opacity(0.5))
                .border(Color.gray.opacity(0.25))
                .cornerRadius(4)
                .autocorrectionDisabled(false)
                .disableAutocorrection(false)
        }
    }
}

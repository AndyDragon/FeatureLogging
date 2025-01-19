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

    var body: some View {
        // Header
        HStack {
            Text(title)

            Button(action: {
                copy(true, false)
            }) {
                Text("Copy")
                    .padding(.horizontal, 20)
            }
            .disabled(!canCopy)
            .buttonStyle(.bordered)

            Button(action: {
                copy(false, true)
            }) {
                Text("Copy (with Placeholders)")
                    .padding(.horizontal, 20)
            }
            .disabled(!hasPlaceholders)
            .buttonStyle(.bordered)

            Spacer()
        }
        .frame(alignment: .leading)
        .padding([.top], 4)

        // Editor
        if #available(macOS 14.0, *) {
            TextEditor(text: $script)
                .font(.system(size: 14))
                .frame(minWidth: 200, maxWidth: .infinity, minHeight: minHeight, maxHeight: maxHeight)
                .textEditorStyle(.plain)
                .foregroundStyle(canCopy ? Color.label : Color.red, Color.secondaryLabel)
                .scrollContentBackground(.hidden)
                .padding(4)
                .background(Color.backgroundColor.opacity(0.5))
                .border(Color.gray.opacity(0.25))
                .cornerRadius(4)
                .padding([.bottom], 6)
                .autocorrectionDisabled(false)
                .disableAutocorrection(false)
        } else {
            TextEditor(text: $script)
                .font(.system(size: 14))
                .frame(minWidth: 200, maxWidth: .infinity, minHeight: minHeight, maxHeight: maxHeight)
                .foregroundStyle(canCopy ? Color.label : Color.red, Color.secondaryLabel)
                .scrollContentBackground(.hidden)
                .padding(4)
                .background(Color.backgroundColor.opacity(0.5))
                .border(Color.gray.opacity(0.25))
                .cornerRadius(4)
                .padding([.bottom], 6)
                .autocorrectionDisabled(false)
                .disableAutocorrection(false)
        }
    }
}

//
//  PlaceholderEditor.swift
//  Feature Logging
//
//  Created by Andrew Forget on 2024-02-10.
//

import SwiftUI

final class PlaceholderValue: ObservableObject {
    @Published var value = ""
}

final class PlaceholderList: ObservableObject {
    @Published var placeholderDict = [String: PlaceholderValue]()
    @Published var longPlaceholderDict = [String: PlaceholderValue]()
}

struct PlaceholderView: View {
    let element: [String: PlaceholderValue].Element
    var editorName = ""
    var editorLongForm = false
    @State var editorValue: String

    var body: some View {
        HStack(alignment: editorLongForm ? .top : .center) {
            Text(editorName.capitalized)
                .frame(minWidth: 200)
                .padding([.top], editorLongForm ? 4 : 0)

            if editorLongForm {
                if #available(macOS 14.0, *) {
                    TextEditor(text: $editorValue.onChange(editorValueChanged))
                        .font(.body)
                        .frame(height: 48)
                        .frame(minWidth: 320)
                        .foregroundStyle(Color.TextColorPrimary, Color.TextColorSecondary)
                        .scrollContentBackground(.hidden)
                        .padding(4)
                        .background(Color.BackgroundColorEditor)
                        .border(Color.gray.opacity(0.25))
                        .cornerRadius(4)
                        .textEditorStyle(.plain)
                        .autocorrectionDisabled(false)
                        .disableAutocorrection(false)
                } else {
                    TextEditor(text: $editorValue.onChange(editorValueChanged))
                        .font(.body)
                        .frame(height: 48)
                        .frame(minWidth: 320)
                        .foregroundStyle(Color.TextColorPrimary, Color.TextColorSecondary)
                        .scrollContentBackground(.hidden)
                        .padding(4)
                        .background(Color.BackgroundColorEditor)
                        .border(Color.gray.opacity(0.25))
                        .cornerRadius(4)
                        .autocorrectionDisabled(false)
                        .disableAutocorrection(false)
                }
            } else {
                TextField("", text: $editorValue.onChange(editorValueChanged))
                    .lineLimit(1)
                    .font(.body)
                    .frame(minWidth: 320)
                    .foregroundStyle(Color.TextColorPrimary, Color.TextColorSecondary)
                    .textFieldStyle(.plain)
                    .padding(4)
                    .background(Color.BackgroundColorEditor)
                    .border(Color.gray.opacity(0.25))
                    .cornerRadius(4)
                    .autocorrectionDisabled(false)
                    .disableAutocorrection(false)
            }
            Spacer()
                .background(Color.yellow)
        }
        .frame(maxWidth: .infinity)
        .listRowSeparator(.hidden)
    }

    init(_ element: [String: PlaceholderValue].Element, isLongForm: Bool) {
        self.element = element
        let start = element.key.index(element.key.startIndex, offsetBy: 2)
        let end = element.key.index(element.key.endIndex, offsetBy: -3)
        editorName = String(element.key[start...end])
        editorValue = element.value.value
        editorLongForm = isLongForm
    }

    func editorValueChanged(to: String) {
        element.value.value = editorValue
    }
}

struct PlaceholderSheet: View {
    @ObservedObject var placeholders: PlaceholderList
    @Binding var scriptWithPlaceholders: String
    @Binding var scriptWithPlaceholdersInPlace: String
    @Binding var isPresenting: Bool
    var transferPlaceholders: () -> Void
    var toastCopyToClipboard: (_ copySuffix: String) -> Void

    var body: some View {
        ZStack {
            Color.BackgroundColor.edgesIgnoringSafeArea(.all)

            VStack {
                Text("There are manual placeholders that need to be filled out:")
                Text("(leave any fields blank to remove placeholder)")

                List {
                    ForEach(
                        placeholders.placeholderDict.sorted(by: { entry1, entry2 in
                            entry1.key < entry2.key
                        }), id: \.key
                    ) { entry in
                        PlaceholderView(entry, isLongForm: false)
                    }
                    ForEach(
                        placeholders.longPlaceholderDict.sorted(by: { entry1, entry2 in
                            entry1.key < entry2.key
                        }), id: \.key
                    ) { entry in
                        PlaceholderView(entry, isLongForm: true)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .padding(4)
                .background(Color.BackgroundColorList)
                .border(Color.gray.opacity(0.25))
                .cornerRadius(4)

                HStack {
                    Button(action: {
                        scriptWithPlaceholders = scriptWithPlaceholdersInPlace
                        placeholders.placeholderDict.forEach({ placeholder in
                            scriptWithPlaceholders = scriptWithPlaceholders.replacingOccurrences(
                                of: placeholder.key,
                                with: placeholder.value.value)
                        })
                        placeholders.longPlaceholderDict.forEach({ placeholder in
                            scriptWithPlaceholders = scriptWithPlaceholders.replacingOccurrences(
                                of: placeholder.key,
                                with: placeholder.value.value)
                        })
                        transferPlaceholders()
                        copyToClipboard(scriptWithPlaceholders)
                        isPresenting.toggle()
                        toastCopyToClipboard("")
                    }) {
                        Text("Copy")
                            .padding(.horizontal, 20)
                    }
                    .buttonStyle(.bordered)

                    Button(action: {
                        copyToClipboard(scriptWithPlaceholdersInPlace)
                        isPresenting.toggle()
                        toastCopyToClipboard("with placeholders")
                    }) {
                        Text("Copy with Placeholders")
                            .padding(.horizontal, 20)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .foregroundStyle(Color.TextColorPrimary, Color.TextColorSecondary)
            .frame(minWidth: 800, maxWidth: .infinity, minHeight: 600, maxHeight: .infinity)
            .padding()
        }
    }
}

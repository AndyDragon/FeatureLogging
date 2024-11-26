//
//  FeatureEditor.swift
//  Feature Logging
//
//  Created by Andrew Forget on 2024-03-29.
//

import AlertToast
import SwiftUI

struct FeatureEditor: View {
    @State private var viewModel: ContentView.ViewModel
    private var close: () -> Void
    private var updateList: () -> Void
    private var markDocumentDirty: () -> Void
    private var showDownloaderView: () -> Void
    private var showToast: (_ type: AlertToast.AlertType, _ text: String, _ subTitle: String, _ duration: ToastDuration, _ onTap: @escaping () -> Void) -> Void
    
    @AppStorage(
        "preference_includehash",
        store: UserDefaults(suiteName: "com.andydragon.com.Feature-Logging")
    ) var includeHash = false
    
    private let labelWidth: CGFloat = 108
    
    init(
        _ viewModel: ContentView.ViewModel,
        _ close: @escaping () -> Void,
        _ updateList: @escaping () -> Void,
        _ markDocumentDirty: @escaping () -> Void,
        _ showDownloaderView: @escaping () -> Void,
        _ showToast: @escaping (_ type: AlertToast.AlertType, _ text: String, _ subTitle: String, _ duration: ToastDuration, _ onTap: @escaping () -> Void) -> Void
    ) {
        self.viewModel = viewModel
        self.close = close
        self.updateList = updateList
        self.markDocumentDirty = markDocumentDirty
        self.showDownloaderView = showDownloaderView
        self.showToast = showToast
    }
    
    var body: some View {
        if viewModel.selectedPage != nil && viewModel.selectedFeature != nil {
            let selectedPage = Binding<LoadedPage>(
                get: { viewModel.selectedPage! },
                set: { viewModel.selectedPage = $0 }
            )
            
            let selectedFeature = Binding<SharedFeature>(
                get: { viewModel.selectedFeature! },
                set: { viewModel.selectedFeature = $0 }
            )
            
            VStack {
                // Is picked
                HStack(alignment: .center) {
                    Spacer()
                        .frame(width: labelWidth + 16, alignment: .trailing)
                    
                    Toggle(
                        isOn: selectedFeature.feature.isPicked.onChange { value in
                            updateList()
                            markDocumentDirty()
                        }
                    ) {
                        Text("Picked as feature")
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .tint(Color.AccentColor)
                    .accentColor(Color.AccentColor)
                    .focusable()
                    
                    Spacer()
                    
                    Button(action: {
                        close()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundStyle(Color.TextColorPrimary, Color.TextColorSecondary)
                    }
                }
                
                // Post link
                HStack(alignment: .center) {
                    ValidationLabel(
                        "Post link:", labelWidth: labelWidth,
                        validation: !selectedFeature.feature.postLink.wrappedValue.isEmpty && !selectedFeature.feature.postLink.wrappedValue.contains(where: \.isNewline))
                    TextField(
                        "enter the post link",
                        text: selectedFeature.feature.postLink.onChange { value in
                            markDocumentDirty()
                        }
                    )
                    .focusable()
                    .autocorrectionDisabled(false)
                    .textFieldStyle(.plain)
                    .padding(4)
                    .background(Color.BackgroundColorEditor)
                    .border(Color.gray.opacity(0.25))
                    .cornerRadius(4)
                    
                    Button(action: {
                        let linkText = stringFromClipboard().trimmingCharacters(in: .whitespacesAndNewlines)
                        if linkText.starts(with: "https://vero.co/") {
                            selectedFeature.feature.postLink.wrappedValue = linkText
                            let possibleUserAlias = String(linkText.dropFirst(16).split(separator: "/").first ?? "")
                            // If the user doesn't have an alias, the link will have a single letter, often 'p'
                            if possibleUserAlias.count > 1 {
                                selectedFeature.feature.userAlias.wrappedValue = String(linkText.dropFirst(16).split(separator: "/").first ?? "")
                            }
                        }
                    }) {
                        HStack(alignment: .center) {
                            Image(systemName: "list.clipboard.fill")
                                .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                            Text("Paste")
                        }
                    }
                    .focusable()
                    
                    Button(action: {
                        if !selectedFeature.feature.postLink.wrappedValue.isEmpty {
                            showDownloaderView()
                        }
                    }) {
                        HStack(alignment: .center) {
                            Image(systemName: "arrow.down.circle.fill")
                                .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                            Text("Load post")
                                .font(.system(.body, design: .rounded).bold())
                                .foregroundStyle(Color.TextColorPrimary, Color.TextColorSecondary)
                            Text("  ⌘ ⇧ ↓")
                                .font(.system(.body, design: .rounded))
                                .foregroundStyle(Color.gray, Color.TextColorSecondary)
                        }
                    }
                    .focusable()
                    .disabled(!selectedFeature.feature.postLink.wrappedValue.starts(with: "https://vero.co/"))
                    .keyboardShortcut(.downArrow, modifiers: [.command, .shift])
                }
                
                // User alias
                HStack(alignment: .center) {
                    ValidationLabel(
                        "User alias:", labelWidth: labelWidth,
                        validation:
                            !(selectedFeature.feature.userAlias.wrappedValue.isEmpty || selectedFeature.feature.userAlias.wrappedValue.starts(with: "@")
                              || selectedFeature.feature.userAlias.wrappedValue.count <= 1) && !selectedFeature.feature.userAlias.wrappedValue.contains(where: \.isNewline))
                    TextField(
                        "enter the user alias",
                        text: selectedFeature.feature.userAlias.onChange { value in
                            markDocumentDirty()
                        }
                    )
                    .focusable()
                    .autocorrectionDisabled(false)
                    .textFieldStyle(.plain)
                    .padding(4)
                    .background(Color.BackgroundColorEditor)
                    .border(Color.gray.opacity(0.25))
                    .cornerRadius(4)
                    
                    Button(action: {
                        let aliasText = stringFromClipboard().trimmingCharacters(in: .whitespacesAndNewlines)
                        if aliasText.starts(with: "@") {
                            selectedFeature.feature.userAlias.wrappedValue = String(aliasText.dropFirst(1))
                        } else {
                            selectedFeature.feature.userAlias.wrappedValue = aliasText
                        }
                        markDocumentDirty()
                    }) {
                        HStack(alignment: .center) {
                            Image(systemName: "list.clipboard.fill")
                                .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                            Text("Paste")
                        }
                    }
                    .focusable()
                }
                
                // User name
                HStack(alignment: .center) {
                    ValidationLabel(
                        "User name:", labelWidth: labelWidth,
                        validation: !selectedFeature.feature.userName.wrappedValue.isEmpty && !selectedFeature.feature.userName.wrappedValue.contains(where: \.isNewline))
                    TextField(
                        "enter the user name",
                        text: selectedFeature.feature.userName.onChange { value in
                            updateList()
                            markDocumentDirty()
                        }
                    )
                    .focusable()
                    .autocorrectionDisabled(false)
                    .textFieldStyle(.plain)
                    .padding(4)
                    .background(Color.BackgroundColorEditor)
                    .border(Color.gray.opacity(0.25))
                    .cornerRadius(4)
                    
                    Button(action: {
                        let userText = stringFromClipboard().trimmingCharacters(in: .whitespacesAndNewlines)
                        if userText.contains("@") {
                            selectedFeature.feature.userName.wrappedValue = (userText.split(separator: "@").first ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                            selectedFeature.feature.userAlias.wrappedValue = (userText.split(separator: "@").last ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                        } else {
                            selectedFeature.feature.userName.wrappedValue = userText
                        }
                        markDocumentDirty()
                    }) {
                        HStack(alignment: .center) {
                            Image(systemName: "list.clipboard.fill")
                                .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                            Text("Paste")
                        }
                    }
                    .focusable()
                }
                
                // Member level
                HStack(alignment: .center) {
                    ValidationLabel("User level:", labelWidth: labelWidth, validation: selectedFeature.feature.userLevel.wrappedValue != MembershipCase.none)
                    Picker(
                        "",
                        selection: selectedFeature.feature.userLevel.onChange { value in
                            markDocumentDirty()
                        }
                    ) {
                        ForEach(MembershipCase.casesFor(hub: selectedPage.hub.wrappedValue)) { level in
                            Text(level.rawValue)
                                .tag(level)
                                .foregroundStyle(Color.TextColorSecondary, Color.TextColorSecondary)
                        }
                    }
                    .tint(Color.AccentColor)
                    .accentColor(Color.AccentColor)
                    .foregroundStyle(Color.AccentColor, Color.TextColorPrimary)
                    .focusable()
                }
                
                // Team mate
                HStack(alignment: .center) {
                    Spacer()
                        .frame(width: labelWidth + 16, alignment: .trailing)
                    Toggle(
                        isOn: selectedFeature.feature.userIsTeammate.onChange { value in
                            markDocumentDirty()
                        }
                    ) {
                        Text("User is a Team Mate")
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .tint(Color.AccentColor)
                    .accentColor(Color.AccentColor)
                    .focusable()
                    Spacer()
                }
                
                // Tag source
                HStack(alignment: .center) {
                    Text("Found using:")
                        .frame(width: labelWidth, alignment: .trailing)
                    Picker(
                        "",
                        selection: selectedFeature.feature.tagSource.onChange { value in
                            markDocumentDirty()
                        }
                    ) {
                        ForEach(TagSourceCase.casesFor(hub: selectedPage.hub.wrappedValue)) { source in
                            Text(source.rawValue)
                                .tag(source)
                                .foregroundStyle(Color.TextColorSecondary, Color.TextColorSecondary)
                        }
                    }
                    .focusable()
                    .pickerStyle(.segmented)
                }
                
                // Photo featured
                HStack(alignment: .center) {
                    Spacer()
                        .frame(width: labelWidth + 16, alignment: .trailing)
                    
                    // Photo featured on page
                    Toggle(
                        isOn: selectedFeature.feature.photoFeaturedOnPage.onChange { value in
                            updateList()
                            markDocumentDirty()
                        }
                    ) {
                        Text("Photo already featured on page")
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .tint(Color.AccentColor)
                    .accentColor(Color.AccentColor)
                    .focusable()
                    
                    Text("|")
                        .padding([.leading, .trailing])
                    
                    // Photo featured on hub
                    Toggle(
                        isOn: selectedFeature.feature.photoFeaturedOnHub.onChange { value in
                            updateList()
                            markDocumentDirty()
                        }
                    ) {
                        Text("Photo featured on hub")
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .tint(Color.AccentColor)
                    .accentColor(Color.AccentColor)
                    .focusable()
                    
                    if selectedFeature.feature.photoFeaturedOnHub.wrappedValue {
                        Text("|")
                            .padding([.leading, .trailing])
                        
                        ValidationLabel(
                            "Last date featured:",
                            validation: !(selectedFeature.feature.photoLastFeaturedOnHub.wrappedValue.isEmpty || selectedFeature.feature.photoLastFeaturedPage.wrappedValue.isEmpty)
                        )
                        TextField(
                            "",
                            text: selectedFeature.feature.photoLastFeaturedOnHub.onChange { value in
                                markDocumentDirty()
                            }
                        )
                        .focusable()
                        .autocorrectionDisabled(false)
                        .textFieldStyle(.plain)
                        .padding(4)
                        .background(Color.BackgroundColorEditor)
                        .border(Color.gray.opacity(0.25))
                        .cornerRadius(4)
                        
                        TextField(
                            "on page",
                            text: selectedFeature.feature.photoLastFeaturedPage.onChange { value in
                                markDocumentDirty()
                            }
                        )
                        .focusable()
                        .autocorrectionDisabled(false)
                        .textFieldStyle(.plain)
                        .padding(4)
                        .background(Color.BackgroundColorEditor)
                        .border(Color.gray.opacity(0.25))
                        .cornerRadius(4)
                    }
                    
                    Spacer()
                }
                
                // Feature description
                HStack(alignment: .center) {
                    ValidationLabel("Description:", labelWidth: labelWidth, validation: !selectedFeature.feature.featureDescription.wrappedValue.isEmpty)
                    TextField(
                        "enter the description of the feature (not used in scripts)",
                        text: selectedFeature.feature.featureDescription.onChange { value in
                            markDocumentDirty()
                        }
                    )
                    .focusable()
                    .autocorrectionDisabled(false)
                    .textFieldStyle(.plain)
                    .padding(4)
                    .background(Color.BackgroundColorEditor)
                    .border(Color.gray.opacity(0.25))
                    .cornerRadius(4)
                }
                
                // User featured
                if selectedPage.hub.wrappedValue == "click" {
                    // User featured on page
                    HStack(alignment: .center) {
                        Spacer()
                            .frame(width: labelWidth + 16, alignment: .trailing)
                        
                        Toggle(
                            isOn: selectedFeature.feature.userHasFeaturesOnPage.onChange { value in
                                markDocumentDirty()
                            }
                        ) {
                            Text("User featured on page")
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        .tint(Color.AccentColor)
                        .accentColor(Color.AccentColor)
                        .focusable()
                        
                        if selectedFeature.feature.userHasFeaturesOnPage.wrappedValue {
                            Text("|")
                                .padding([.leading, .trailing])
                            
                            ValidationLabel("Last date featured:", validation: !selectedFeature.feature.lastFeaturedOnPage.wrappedValue.isEmpty)
                            TextField(
                                "",
                                text: selectedFeature.feature.lastFeaturedOnPage.onChange { value in
                                    markDocumentDirty()
                                }
                            )
                            .focusable()
                            .autocorrectionDisabled(false)
                            .textFieldStyle(.plain)
                            .padding(4)
                            .background(Color.BackgroundColorEditor)
                            .border(Color.gray.opacity(0.25))
                            .cornerRadius(4)
                            
                            Text("|")
                                .padding([.leading, .trailing])
                            
                            Text("Number of features on page:")
                            Picker(
                                "",
                                selection: selectedFeature.feature.featureCountOnPage.onChange { value in
                                    markDocumentDirty()
                                }
                            ) {
                                Text("many").tag("many")
                                ForEach(0..<76) { value in
                                    Text("\(value)").tag("\(value)")
                                }
                            }
                            .frame(maxWidth: 200)
                            .tint(Color.AccentColor)
                            .accentColor(Color.AccentColor)
                            .foregroundStyle(Color.AccentColor, Color.TextColorPrimary)
                            .focusable()
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            copyToClipboard("\(includeHash ? "#" : "")click_\(selectedPage.name.wrappedValue)_\(selectedFeature.feature.userAlias.wrappedValue)")
                            showToast(.complete(.green), "Copied to clipboard", "Copied the page feature tag for the user to the clipboard", .Success) {}
                        }) {
                            HStack(alignment: .center) {
                                Image(systemName: "tag.fill")
                                    .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                                Text("Copy tag")
                            }
                        }
                        .focusable()
                    }
                    
                    // User featured on hub
                    HStack(alignment: .center) {
                        Spacer()
                            .frame(width: labelWidth + 16, alignment: .trailing)
                        
                        Toggle(
                            isOn: selectedFeature.feature.userHasFeaturesOnHub.onChange { value in
                                markDocumentDirty()
                            }
                        ) {
                            Text("User featured on Click")
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        .tint(Color.AccentColor)
                        .accentColor(Color.AccentColor)
                        .focusable()
                        
                        if selectedFeature.feature.userHasFeaturesOnHub.wrappedValue {
                            Text("|")
                                .padding([.leading, .trailing])
                            
                            ValidationLabel(
                                "Last date featured:",
                                validation: !(selectedFeature.feature.lastFeaturedOnHub.wrappedValue.isEmpty || selectedFeature.feature.lastFeaturedPage.wrappedValue.isEmpty))
                            TextField(
                                "",
                                text: selectedFeature.feature.lastFeaturedOnHub.onChange { value in
                                    markDocumentDirty()
                                }
                            )
                            .focusable()
                            .autocorrectionDisabled(false)
                            .textFieldStyle(.plain)
                            .padding(4)
                            .background(Color.BackgroundColorEditor)
                            .border(Color.gray.opacity(0.25))
                            .cornerRadius(4)
                            
                            TextField(
                                "on page",
                                text: selectedFeature.feature.lastFeaturedPage.onChange { value in
                                    markDocumentDirty()
                                }
                            )
                            .focusable()
                            .autocorrectionDisabled(false)
                            .textFieldStyle(.plain)
                            .padding(4)
                            .background(Color.BackgroundColorEditor)
                            .border(Color.gray.opacity(0.25))
                            .cornerRadius(4)
                            
                            Text("|")
                                .padding([.leading, .trailing])
                            
                            Text("Number of features on Click:")
                            Picker(
                                "",
                                selection: selectedFeature.feature.featureCountOnHub.onChange { value in
                                    markDocumentDirty()
                                }
                            ) {
                                Text("many").tag("many")
                                ForEach(0..<76) { value in
                                    Text("\(value)").tag("\(value)")
                                }
                            }
                            .frame(maxWidth: 200)
                            .tint(Color.AccentColor)
                            .accentColor(Color.AccentColor)
                            .foregroundStyle(Color.AccentColor, Color.TextColorPrimary)
                            .focusable()
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            copyToClipboard("\(includeHash ? "#" : "")click_featured_\(selectedFeature.feature.userAlias.wrappedValue)")
                            showToast(.complete(.green), "Copied to clipboard", "Copied the hub feature tag for the user to the clipboard", .Success) {}
                        }) {
                            HStack(alignment: .center) {
                                Image(systemName: "tag.fill")
                                    .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                                Text("Copy tag")
                            }
                        }
                        .focusable()
                    }
                } else if selectedPage.hub.wrappedValue == "snap" {
                    // User featured on page
                    HStack(alignment: .center) {
                        Spacer()
                            .frame(width: labelWidth + 16, alignment: .trailing)
                        Toggle(
                            isOn: selectedFeature.feature.userHasFeaturesOnPage.onChange { value in
                                markDocumentDirty()
                            }
                        ) {
                            Text("User featured on page")
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        .tint(Color.AccentColor)
                        .accentColor(Color.AccentColor)
                        .focusable()
                        
                        if selectedFeature.feature.userHasFeaturesOnPage.wrappedValue {
                            Text("|")
                                .padding([.leading, .trailing])
                            
                            ValidationLabel("Last date featured:", validation: !selectedFeature.feature.lastFeaturedOnPage.wrappedValue.isEmpty)
                            TextField(
                                "",
                                text: selectedFeature.feature.lastFeaturedOnPage.onChange { value in
                                    markDocumentDirty()
                                }
                            )
                            .focusable()
                            .autocorrectionDisabled(false)
                            .textFieldStyle(.plain)
                            .padding(4)
                            .background(Color.BackgroundColorEditor)
                            .border(Color.gray.opacity(0.25))
                            .cornerRadius(4)
                            
                            Text("|")
                                .padding([.leading, .trailing])
                            
                            Text("Number of features on Snap page:")
                            Picker(
                                "",
                                selection: selectedFeature.feature.featureCountOnPage.onChange { value in
                                    markDocumentDirty()
                                }
                            ) {
                                Text("many").tag("many")
                                ForEach(0..<21) { value in
                                    Text("\(value)").tag("\(value)")
                                }
                            }
                            .tint(Color.AccentColor)
                            .accentColor(Color.AccentColor)
                            .foregroundStyle(Color.AccentColor, Color.TextColorPrimary)
                            .focusable()
                            
                            Text("|")
                                .padding([.leading, .trailing])
                            
                            Text("Number of features on RAW page:")
                            Picker(
                                "",
                                selection: selectedFeature.feature.featureCountOnRawPage.onChange { value in
                                    markDocumentDirty()
                                }
                            ) {
                                Text("many").tag("many")
                                ForEach(0..<21) { value in
                                    Text("\(value)").tag("\(value)")
                                }
                            }
                            .tint(Color.AccentColor)
                            .accentColor(Color.AccentColor)
                            .foregroundStyle(Color.AccentColor, Color.TextColorPrimary)
                            .focusable()
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            copyToClipboard(
                                "\(includeHash ? "#" : "")snap_\(selectedPage.pageName.wrappedValue ?? selectedPage.name.wrappedValue)_\(selectedFeature.feature.userAlias.wrappedValue)"
                            )
                            showToast(.complete(.green), "Copied to clipboard", "Copied the Snap page feature tag for the user to the clipboard", .Success) {}
                        }) {
                            HStack(alignment: .center) {
                                Image(systemName: "tag.fill")
                                    .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                                Text("Copy tag")
                            }
                        }
                        .focusable()
                        
                        Button(action: {
                            copyToClipboard(
                                "\(includeHash ? "#" : "")raw_\(selectedPage.pageName.wrappedValue ?? selectedPage.name.wrappedValue)_\(selectedFeature.feature.userAlias.wrappedValue)"
                            )
                            showToast(.complete(.green), "Copied to clipboard", "Copied the RAW page feature tag for the user to the clipboard", .Success) {}
                        }) {
                            HStack(alignment: .center) {
                                Image(systemName: "tag.fill")
                                    .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                                Text("Copy RAW tag")
                            }
                        }
                        .focusable()
                    }
                    
                    // User featured on hub
                    HStack(alignment: .center) {
                        Spacer()
                            .frame(width: labelWidth + 16, alignment: .trailing)
                        
                        Toggle(
                            isOn: selectedFeature.feature.userHasFeaturesOnHub.onChange { value in
                                markDocumentDirty()
                            }
                        ) {
                            Text("User featured on Snap / RAW")
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        .tint(Color.AccentColor)
                        .accentColor(Color.AccentColor)
                        .focusable()
                        
                        if selectedFeature.feature.userHasFeaturesOnHub.wrappedValue {
                            Text("|")
                                .padding([.leading, .trailing])
                            
                            ValidationLabel(
                                "Last date featured:",
                                validation: !(selectedFeature.feature.lastFeaturedOnHub.wrappedValue.isEmpty || selectedFeature.feature.lastFeaturedPage.wrappedValue.isEmpty))
                            TextField(
                                "",
                                text: selectedFeature.feature.lastFeaturedOnHub.onChange { value in
                                    markDocumentDirty()
                                }
                            )
                            .focusable()
                            .autocorrectionDisabled(false)
                            .textFieldStyle(.plain)
                            .padding(4)
                            .background(Color.BackgroundColorEditor)
                            .border(Color.gray.opacity(0.25))
                            .cornerRadius(4)
                            
                            TextField(
                                "on page",
                                text: selectedFeature.feature.lastFeaturedPage.onChange { value in
                                    markDocumentDirty()
                                }
                            )
                            .focusable()
                            .autocorrectionDisabled(false)
                            .textFieldStyle(.plain)
                            .padding(4)
                            .background(Color.BackgroundColorEditor)
                            .border(Color.gray.opacity(0.25))
                            .cornerRadius(4)
                            
                            Text("|")
                                .padding([.leading, .trailing])
                            
                            Text("Number of features on Snap:")
                            Picker(
                                "",
                                selection: selectedFeature.feature.featureCountOnHub.onChange { value in
                                    markDocumentDirty()
                                }
                            ) {
                                Text("many").tag("many")
                                ForEach(0..<21) { value in
                                    Text("\(value)").tag("\(value)")
                                }
                            }
                            .tint(Color.AccentColor)
                            .accentColor(Color.AccentColor)
                            .foregroundStyle(Color.AccentColor, Color.TextColorPrimary)
                            .focusable()
                            
                            Text("|")
                                .padding([.leading, .trailing])
                            
                            Text("Number of features on RAW:")
                            Picker(
                                "",
                                selection: selectedFeature.feature.featureCountOnRawHub.onChange { value in
                                    markDocumentDirty()
                                }
                            ) {
                                Text("many").tag("many")
                                ForEach(0..<21) { value in
                                    Text("\(value)").tag("\(value)")
                                }
                            }
                            .tint(Color.AccentColor)
                            .accentColor(Color.AccentColor)
                            .foregroundStyle(Color.AccentColor, Color.TextColorPrimary)
                            .focusable()
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            copyToClipboard("\(includeHash ? "#" : "")snap_featured_\(selectedFeature.feature.userAlias.wrappedValue)")
                            showToast(.complete(.green), "Copied to clipboard", "Copied the Snap hub feature tag for the user to the clipboard", .Success) {}
                        }) {
                            HStack(alignment: .center) {
                                Image(systemName: "tag.fill")
                                    .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                                Text("Copy tag")
                            }
                        }
                        .focusable()
                        
                        Button(action: {
                            copyToClipboard("\(includeHash ? "#" : "")raw_featured_\(selectedFeature.feature.userAlias.wrappedValue)")
                            showToast(.complete(.green), "Copied to clipboard", "Copied the RAW hub feature tag for the user to the clipboard", .Success) {}
                        }) {
                            HStack(alignment: .center) {
                                Image(systemName: "tag.fill")
                                    .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                                Text("Copy RAW tag")
                            }
                        }
                        .focusable()
                    }
                }
                
                // Too soon?
                HStack(alignment: .center) {
                    Spacer()
                        .frame(width: labelWidth + 16, alignment: .trailing)
                    
                    Toggle(
                        isOn: selectedFeature.feature.tooSoonToFeatureUser.onChange { value in
                            updateList()
                            markDocumentDirty()
                        }
                    ) {
                        Text("Too soon to feature user")
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .tint(Color.AccentColor)
                    .accentColor(Color.AccentColor)
                    .focusable()
                    
                    Spacer()
                }
                
                // Verification results
                HStack(alignment: .center) {
                    Text("Validation:")
                        .frame(width: labelWidth, alignment: .trailing)
                        .padding([.trailing], 8)
                    
                    Text("TinEye:")
                    Picker(
                        "",
                        selection: selectedFeature.feature.tinEyeResults.onChange { value in
                            updateList()
                            markDocumentDirty()
                        }
                    ) {
                        ForEach(TinEyeResults.allCases) { source in
                            Text(source.rawValue)
                                .tag(source)
                                .foregroundStyle(Color.TextColorSecondary, Color.TextColorSecondary)
                        }
                    }
                    .tint(Color.AccentColor)
                    .accentColor(Color.AccentColor)
                    .foregroundStyle(Color.AccentColor, Color.TextColorPrimary)
                    .focusable()
                    
                    Text("|")
                        .padding([.leading, .trailing])
                    
                    Text("AI Check:")
                    Picker(
                        "",
                        selection: selectedFeature.feature.aiCheckResults.onChange { value in
                            updateList()
                            markDocumentDirty()
                        }
                    ) {
                        ForEach(AiCheckResults.allCases) { source in
                            Text(source.rawValue)
                                .tag(source)
                                .foregroundStyle(Color.TextColorSecondary, Color.TextColorSecondary)
                        }
                    }
                    .tint(Color.AccentColor)
                    .accentColor(Color.AccentColor)
                    .foregroundStyle(Color.AccentColor, Color.TextColorPrimary)
                    .focusable()
                }
            }
            
            Spacer()
        }
    }
}

//
//  FeatureEditor.swift
//  Feature Logging
//
//  Created by Andrew Forget on 2024-03-29.
//

import SwiftUI
import AlertToast

struct FeatureEditor: View {
    @ObservedObject var feature: Feature
    @State var loadedPage: LoadedPage?
    var close: () -> Void
    var updateList: () -> Void
    var showToast: (_ type: AlertToast.AlertType, _ text: String, _ subTitle: String, _ duration: Int, _ onTap: @escaping () -> Void) -> Void

    @AppStorage(
        "preference_includehash",
        store: UserDefaults(suiteName: "com.andydragon.com.Feature-Logging")
    ) var includeHash = false
    
    @State private var isPicked = false
    @State private var postLink = ""
    @State private var userName = ""
    @State private var userAlias = ""
    @State private var userLevel = MembershipCase.none
    @State private var userIsTeammate = false
    @State private var tagSource = TagSourceCase.commonPageTag
    @State private var photoFeaturedOnPage = false
    @State private var photoFeaturedOnHub = false
    @State private var photoLastFeaturedOnHub = ""
    @State private var photoLastFeaturedPage = ""
    @State private var featureDescription = ""
    @State private var userHasFeaturesOnPage = false
    @State private var lastFeaturedOnPage = ""
    @State private var featureCountOnPage = "many"
    @State private var featureCountOnRawPage = "many"
    @State private var userHasFeaturesOnHub = false
    @State private var lastFeaturedOnHub = ""
    @State private var lastFeaturedPage = ""
    @State private var featureCountOnHub = "many"
    @State private var featureCountOnRawHub = "many"
    @State private var tooSoonToFeatureUser = false
    @State private var tinEyeResults = TinEyeResults.zeroMatches
    @State private var aiCheckResults = AiCheckResults.human
    
    private let labelWidth: CGFloat = 108
    
    var body: some View {
        VStack {
            // Tag picked
            HStack(alignment: .center) {
                Spacer()
                    .frame(width: labelWidth + 16, alignment: .trailing)
                Toggle(isOn: $isPicked.onChange { value in
                    feature.isPicked = isPicked
                    updateList()
                }) {
                    Text("Picked as feature")
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .tint(Color.AccentColor)
                .accentColor(Color.AccentColor)
                .focusable()
                Spacer()
                Button(action: {
                    close();
                }) {
                    Image(systemName: "xmark")
                        .foregroundStyle(Color.TextColorPrimary, Color.TextColorSecondary)
                }
            }
            
            // Post link
            HStack(alignment: .center) {
                ValidationLabel("Post link:", labelWidth: labelWidth, validation: !postLink.isEmpty)
                TextField("enter the post link", text: $postLink.onChange { value in feature.postLink = postLink })
                    .focusable()
                    .autocorrectionDisabled(false)
                    .textFieldStyle(.plain)
                    .padding(4)
                    .background(Color.BackgroundColorEditor)
                    .border(Color.gray.opacity(0.25))
                    .cornerRadius(4)
                
                Button(action: {
                    let linkText = pasteFromClipboard().trimmingCharacters(in: .whitespacesAndNewlines)
                    if linkText.starts(with: "https://vero.co/") {
                        postLink = linkText
                        userAlias = String(linkText.dropFirst(16).split(separator: "/").first ?? "")
                    } else {
                        // TODO andydragon : show toast, invalid clipboard text, not a VERO link
                    }
                    feature.postLink = postLink
                    feature.userAlias = userAlias
                }) {
                    HStack(alignment: .center) {
                        Image(systemName: "list.clipboard.fill")
                            .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                        Text("Paste")
                    }
                }
                .focusable()
            }
            
            // User alias
            HStack(alignment: .center) {
                ValidationLabel("User alias:", labelWidth: labelWidth, validation: !(userAlias.isEmpty || userAlias.starts(with: "@")))
                TextField("enter the user alias", text: $userAlias.onChange { value in feature.userAlias = userAlias })
                    .focusable()
                    .autocorrectionDisabled(false)
                    .textFieldStyle(.plain)
                    .padding(4)
                    .background(Color.BackgroundColorEditor)
                    .border(Color.gray.opacity(0.25))
                    .cornerRadius(4)

                Button(action: {
                    let aliasText = pasteFromClipboard().trimmingCharacters(in: .whitespacesAndNewlines)
                    if aliasText.starts(with: "@") {
                        userAlias = String(aliasText.dropFirst(1))
                    } else {
                        userAlias = aliasText
                    }
                    feature.userAlias = userAlias
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
                ValidationLabel("User name:", labelWidth: labelWidth, validation: !userName.isEmpty)
                TextField("enter the user name", text: $userName.onChange { value in
                    feature.userName = userName
                    updateList()
                })
                .focusable()
                .autocorrectionDisabled(false)
                .textFieldStyle(.plain)
                .padding(4)
                .background(Color.BackgroundColorEditor)
                .border(Color.gray.opacity(0.25))
                .cornerRadius(4)
                
                Button(action: {
                    let userText = pasteFromClipboard().trimmingCharacters(in: .whitespacesAndNewlines)
                    if userText.contains("@") {
                        userName = (userText.split(separator: "@").first ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                        userAlias = (userText.split(separator: "@").last ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                    } else {
                        userName = userText
                    }
                    feature.userName = userName
                    feature.userAlias = userAlias
                }) {
                    HStack(alignment: .center) {
                        Image(systemName: "list.clipboard.fill")
                            .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                        Text("Paste")
                    }
                }
                .focusable()
            }
            
            if let selectedPage = loadedPage {
                // Member level
                HStack(alignment: .center) {
                    ValidationLabel("User level:", labelWidth: labelWidth, validation: userLevel != MembershipCase.none)
                    Picker("", selection: $userLevel.onChange { value in feature.userLevel = userLevel }) {
                        ForEach(MembershipCase.casesFor(hub: selectedPage.hub)) { level in
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
                    Toggle(isOn: $userIsTeammate.onChange { value in feature.userIsTeammate = userIsTeammate }) {
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
                    Picker("", selection: $tagSource.onChange { value in feature.tagSource = tagSource }) {
                        ForEach(TagSourceCase.casesFor(hub: selectedPage.hub)) { source in
                            Text(source.rawValue)
                                .tag(source)
                                .foregroundStyle(Color.TextColorSecondary, Color.TextColorSecondary)
                        }
                    }
                    .focusable()
                    .pickerStyle(.segmented)
                }
                
                HStack(alignment: .center) {
                    // Photo featured on page
                    Spacer()
                        .frame(width: labelWidth + 16, alignment: .trailing)
                    
                    Toggle(isOn: $photoFeaturedOnPage.onChange { value in
                        feature.photoFeaturedOnPage = photoFeaturedOnPage
                        updateList()
                    }) {
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
                    Toggle(isOn: $photoFeaturedOnHub.onChange { value in
                        feature.photoFeaturedOnHub = photoFeaturedOnHub
                        updateList()
                    }) {
                        Text("Photo featured on hub")
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .tint(Color.AccentColor)
                    .accentColor(Color.AccentColor)
                    .focusable()
                    if photoFeaturedOnHub {
                        Text("|")
                            .padding([.leading, .trailing])
                        
                        ValidationLabel("Last date featured:", validation: !(photoLastFeaturedOnHub.isEmpty || photoLastFeaturedPage.isEmpty))
                        TextField("", text: $photoLastFeaturedOnHub.onChange { value in feature.photoLastFeaturedOnHub = photoLastFeaturedOnHub })
                            .focusable()
                            .autocorrectionDisabled(false)
                            .textFieldStyle(.plain)
                            .padding(4)
                            .background(Color.BackgroundColorEditor)
                            .border(Color.gray.opacity(0.25))
                            .cornerRadius(4)
                        
                        TextField("on page", text: $photoLastFeaturedPage.onChange { value in feature.photoLastFeaturedPage = photoLastFeaturedPage })
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
                    ValidationLabel("Description:", labelWidth: labelWidth, validation: !featureDescription.isEmpty)
                    TextField("enter the description of the feature (not used in scripts)", text: $featureDescription.onChange { value in feature.featureDescription = featureDescription })
                        .focusable()
                        .autocorrectionDisabled(false)
                        .textFieldStyle(.plain)
                        .padding(4)
                        .background(Color.BackgroundColorEditor)
                        .border(Color.gray.opacity(0.25))
                        .cornerRadius(4)
                }
                
                if selectedPage.hub == "click" {
                    // User featured on page
                    HStack(alignment: .center) {
                        Spacer()
                            .frame(width: labelWidth + 16, alignment: .trailing)
                        Toggle(isOn: $userHasFeaturesOnPage.onChange { value in feature.userHasFeaturesOnPage = userHasFeaturesOnPage }) {
                            Text("User featured on page")
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        .tint(Color.AccentColor)
                        .accentColor(Color.AccentColor)
                        .focusable()
                        
                        if userHasFeaturesOnPage {
                            Text("|")
                                .padding([.leading, .trailing])
                            
                            ValidationLabel("Last date featured:", validation: !lastFeaturedOnPage.isEmpty)
                            TextField("", text: $lastFeaturedOnPage.onChange { value in feature.lastFeaturedOnPage = lastFeaturedOnPage })
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
                            Picker("", selection: $featureCountOnPage.onChange { value in feature.featureCountOnPage = featureCountOnPage }) {
                                Text("many").tag("many")
                                ForEach(0 ..< 76) { value in
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
                            copyToClipboard("\(includeHash ? "#" : "")click_\(selectedPage.name)_\(userAlias)")
                            showToast(.complete(.green), "Copied to clipboard", "Copied the page feature tag for the user to the clipboard", 2) { }
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
                        Toggle(isOn: $userHasFeaturesOnHub.onChange { value in feature.userHasFeaturesOnHub = userHasFeaturesOnHub }) {
                            Text("User featured on Click")
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        .tint(Color.AccentColor)
                        .accentColor(Color.AccentColor)
                        .focusable()
                        
                        if userHasFeaturesOnHub {
                            Text("|")
                                .padding([.leading, .trailing])
                            
                            ValidationLabel("Last date featured:", validation: !(lastFeaturedOnHub.isEmpty || lastFeaturedPage.isEmpty))
                            TextField("", text: $lastFeaturedOnHub.onChange { value in feature.lastFeaturedOnHub = lastFeaturedOnHub })
                                .focusable()
                                .autocorrectionDisabled(false)
                                .textFieldStyle(.plain)
                                .padding(4)
                                .background(Color.BackgroundColorEditor)
                                .border(Color.gray.opacity(0.25))
                                .cornerRadius(4)
                            
                            TextField("on page", text: $lastFeaturedPage.onChange { value in feature.lastFeaturedPage = lastFeaturedPage })
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
                            Picker("", selection: $featureCountOnHub.onChange { value in feature.featureCountOnHub = featureCountOnHub }) {
                                Text("many").tag("many")
                                ForEach(0 ..< 21) { value in
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
                            copyToClipboard("\(includeHash ? "#" : "")click_featured_\(userAlias)")
                            showToast(.complete(.green), "Copied to clipboard", "Copied the hub feature tag for the user to the clipboard", 2) { }
                        }) {
                            HStack(alignment: .center) {
                                Image(systemName: "tag.fill")
                                    .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                                Text("Copy tag")
                            }
                        }
                        .focusable()
                    }
                } else if selectedPage.hub == "snap" {
                    // User featured on page
                    HStack(alignment: .center) {
                        Spacer()
                            .frame(width: labelWidth + 16, alignment: .trailing)
                        Toggle(isOn: $userHasFeaturesOnPage.onChange { value in feature.userHasFeaturesOnPage = userHasFeaturesOnPage }) {
                            Text("User featured on page")
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        .tint(Color.AccentColor)
                        .accentColor(Color.AccentColor)
                        .focusable()
                        
                        if userHasFeaturesOnPage {
                            Text("|")
                                .padding([.leading, .trailing])
                            
                            ValidationLabel("Last date featured:", validation: !lastFeaturedOnPage.isEmpty)
                            TextField("", text: $lastFeaturedOnPage.onChange { value in feature.lastFeaturedOnPage = lastFeaturedOnPage })
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
                            Picker("", selection: $featureCountOnPage.onChange { value in feature.featureCountOnPage = featureCountOnPage }) {
                                Text("many").tag("many")
                                ForEach(0 ..< 21) { value in
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
                            Picker("", selection: $featureCountOnRawPage.onChange { value in feature.featureCountOnRawPage = featureCountOnRawPage }) {
                                Text("many").tag("many")
                                ForEach(0 ..< 21) { value in
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
                            copyToClipboard("\(includeHash ? "#" : "")snap_\(selectedPage.pageName ?? selectedPage.name)_\(userAlias)")
                            showToast(.complete(.green), "Copied to clipboard", "Copied the Snap page feature tag for the user to the clipboard", 2) { }
                        }) {
                            HStack(alignment: .center) {
                                Image(systemName: "tag.fill")
                                    .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                                Text("Copy tag")
                            }
                        }
                        .focusable()
                        
                        Button(action: {
                            copyToClipboard("\(includeHash ? "#" : "")raw_\(selectedPage.pageName ?? selectedPage.name)_\(userAlias)")
                            showToast(.complete(.green), "Copied to clipboard", "Copied the RAW page feature tag for the user to the clipboard", 2) { }
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
                        Toggle(isOn: $userHasFeaturesOnHub.onChange { value in feature.userHasFeaturesOnHub = userHasFeaturesOnHub }) {
                            Text("User featured on Snap / RAW")
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        .tint(Color.AccentColor)
                        .accentColor(Color.AccentColor)
                        .focusable()
                        
                        if userHasFeaturesOnHub {
                            Text("|")
                                .padding([.leading, .trailing])
                            
                            ValidationLabel("Last date featured:", validation: !(lastFeaturedOnHub.isEmpty || lastFeaturedPage.isEmpty))
                            TextField("", text: $lastFeaturedOnHub.onChange { value in feature.lastFeaturedOnHub = lastFeaturedOnHub })
                                .focusable()
                                .autocorrectionDisabled(false)
                                .textFieldStyle(.plain)
                                .padding(4)
                                .background(Color.BackgroundColorEditor)
                                .border(Color.gray.opacity(0.25))
                                .cornerRadius(4)
                            
                            TextField("on page", text: $lastFeaturedPage.onChange { value in feature.lastFeaturedPage = lastFeaturedPage })
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
                            Picker("", selection: $featureCountOnHub.onChange { value in feature.featureCountOnHub = featureCountOnHub }) {
                                Text("many").tag("many")
                                ForEach(0 ..< 21) { value in
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
                            Picker("", selection: $featureCountOnRawHub.onChange { value in feature.featureCountOnRawHub = featureCountOnRawHub }) {
                                Text("many").tag("many")
                                ForEach(0 ..< 21) { value in
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
                            copyToClipboard("\(includeHash ? "#" : "")snap_featured_\(userAlias)")
                            showToast(.complete(.green), "Copied to clipboard", "Copied the Snap hub feature tag for the user to the clipboard", 2) { }
                        }) {
                            HStack(alignment: .center) {
                                Image(systemName: "tag.fill")
                                    .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                                Text("Copy tag")
                            }
                        }
                        .focusable()
                        
                        Button(action: {
                            copyToClipboard("\(includeHash ? "#" : "")raw_featured_\(userAlias)")
                            showToast(.complete(.green), "Copied to clipboard", "Copied the RAW hub feature tag for the user to the clipboard", 2) { }
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
                    Toggle(isOn: $tooSoonToFeatureUser.onChange { value in
                        feature.tooSoonToFeatureUser = tooSoonToFeatureUser
                        updateList()
                    }) {
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
                    Picker("", selection: $tinEyeResults.onChange { value in
                        feature.tinEyeResults = tinEyeResults
                        updateList()
                    }) {
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
                    Picker("", selection: $aiCheckResults.onChange { value in 
                        feature.aiCheckResults = aiCheckResults
                        updateList()
                    }) {
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
        .onChange(of: feature, initial: true) {
            isPicked = feature.isPicked
            postLink = feature.postLink
            userName = feature.userName
            userAlias = feature.userAlias
            userLevel = feature.userLevel
            userIsTeammate = feature.userIsTeammate
            tagSource = feature.tagSource
            photoFeaturedOnPage = feature.photoFeaturedOnPage
            photoFeaturedOnHub = feature.photoFeaturedOnHub
            photoLastFeaturedOnHub = feature.photoLastFeaturedOnHub
            photoLastFeaturedPage = feature.photoLastFeaturedPage
            featureDescription = feature.featureDescription
            userHasFeaturesOnPage = feature.userHasFeaturesOnPage
            lastFeaturedOnPage = feature.lastFeaturedOnPage
            featureCountOnPage = feature.featureCountOnPage
            featureCountOnRawPage = feature.featureCountOnRawPage
            userHasFeaturesOnHub = feature.userHasFeaturesOnHub
            lastFeaturedOnHub = feature.lastFeaturedOnHub
            lastFeaturedPage = feature.lastFeaturedPage
            featureCountOnHub = feature.featureCountOnHub
            featureCountOnRawHub = feature.featureCountOnRawHub
            tooSoonToFeatureUser = feature.tooSoonToFeatureUser
            tinEyeResults = feature.tinEyeResults
            aiCheckResults = feature.aiCheckResults
        }
    }
}

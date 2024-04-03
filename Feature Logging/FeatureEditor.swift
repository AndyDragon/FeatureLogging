//
//  FeatureEditor.swift
//  Feature Logging
//
//  Created by Andrew Forget on 2024-03-29.
//

import SwiftUI
import AlertToast

struct FeatureEditor: View {
    @ObservedObject var user: FeatureUser
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
    @State private var featureDescription = ""
    @State private var userHasFeaturesOnPage = false
    @State private var lastFeaturedOnPage = ""
    @State private var featureCountOnPage = "many"
    @State private var featureCountOnRawPage = "many"
    @State private var userHasFeaturesOnHub = false
    @State private var lastFeaturedOnHub = ""
    @State private var lastFeaturedPage = ""
    @State private var featureCountOnSnap = "many"
    @State private var featureCountOnRaw = "many"
    @State private var tooSoonToFeatureUser = false
    @State private var tinEyeResults = TinEyeResults.zeroMatches
    @State private var aiCheckResults = AiCheckResults.human
    
    var body: some View {
        VStack {
            // Tag source
            HStack(alignment: .center) {
                Spacer()
                    .frame(width: 96, alignment: .trailing)
                Toggle(isOn: $isPicked.onChange { value in 
                    user.isPicked = isPicked
                    updateList()
                }) {
                    Text("Picked as feature")
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .focusable()
                Spacer()
                Button(action: {
                    close();
                }) {
                    Image(systemName: "xmark")
                        .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                }
            }
            
            // Post link
            HStack(alignment: .center) {
                Text("Post link:")
                    .frame(width: 80, alignment: .trailing)
                    .padding([.trailing], 8)
                    .foregroundStyle(postLink.isEmpty ? Color.TextColorRequired : Color.TextColorPrimary, Color.TextColorSecondary)
                TextField("enter the post link", text: $postLink.onChange { value in user.postLink = postLink })
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
                    user.postLink = postLink
                    user.userAlias = userAlias
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
                Text("User alias:")
                    .frame(width: 80, alignment: .trailing)
                    .padding([.trailing], 8)
                    .foregroundStyle(userAlias.isEmpty ? Color.TextColorRequired : Color.TextColorPrimary, Color.TextColorSecondary)
                TextField("enter the user alias", text: $userAlias.onChange { value in user.userAlias = userAlias })
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
                    user.userAlias = userAlias
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
                Text("User name:")
                    .frame(width: 80, alignment: .trailing)
                    .padding([.trailing], 8)
                    .foregroundStyle(userName.isEmpty ? Color.TextColorRequired : Color.TextColorPrimary, Color.TextColorSecondary)
                TextField("enter the user name", text: $userName.onChange { value in
                    user.userName = userName
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
                    user.userName = userName
                    user.userAlias = userAlias
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
                    Text("User level:")
                        .frame(width: 80, alignment: .trailing)
                        .foregroundStyle(userLevel == MembershipCase.none ? Color.TextColorRequired : Color.TextColorPrimary, Color.TextColorSecondary)
                    Picker("", selection: $userLevel.onChange { value in user.userLevel = userLevel }) {
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
                        .frame(width: 96, alignment: .trailing)
                    Toggle(isOn: $userIsTeammate.onChange { value in user.userIsTeammate = userIsTeammate }) {
                        Text("User is a Team Mate")
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .focusable()
                    Spacer()
                }
                
                // Tag source
                HStack(alignment: .center) {
                    Text("Found using:")
                        .frame(width: 80, alignment: .trailing)
                    Picker("", selection: $tagSource.onChange { value in user.tagSource = tagSource }) {
                        ForEach(TagSourceCase.casesFor(hub: selectedPage.hub)) { source in
                            Text(source.rawValue)
                                .tag(source)
                                .foregroundStyle(Color.TextColorSecondary, Color.TextColorSecondary)
                        }
                    }
                    .focusable()
                    .pickerStyle(.segmented)
                }
                
                // Photo featured on page
                HStack(alignment: .center) {
                    Spacer()
                        .frame(width: 96, alignment: .trailing)
                    Toggle(isOn: $photoFeaturedOnPage.onChange { value in
                        user.photoFeaturedOnPage = photoFeaturedOnPage
                        updateList()
                    }) {
                        Text("Photo already featured on page")
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .focusable()
                    Spacer()
                }
                
                // Feature description
                HStack(alignment: .center) {
                    Text("Description:")
                        .frame(width: 80, alignment: .trailing)
                        .padding([.trailing], 8)
                        .foregroundStyle(featureDescription.isEmpty ? Color.TextColorRequired : Color.TextColorPrimary, Color.TextColorSecondary)
                    TextField("enter the description of the feature (not used in scripts)", text: $featureDescription.onChange { value in user.featureDescription = featureDescription })
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
                            .frame(width: 96, alignment: .trailing)
                        Toggle(isOn: $userHasFeaturesOnPage.onChange { value in user.userHasFeaturesOnPage = userHasFeaturesOnPage }) {
                            Text("User featured on page")
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        .focusable()
                        
                        if userHasFeaturesOnPage {
                            Text("|")
                                .padding([.leading, .trailing])
                            
                            Text("Last date featured:")
                                .foregroundStyle(lastFeaturedOnPage.isEmpty ? Color.TextColorRequired : Color.TextColorPrimary, Color.TextColorSecondary)
                            TextField("", text: $lastFeaturedOnPage.onChange { value in user.lastFeaturedOnPage = lastFeaturedOnPage })
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
                            Picker("", selection: $featureCountOnPage.onChange { value in user.featureCountOnPage = featureCountOnPage }) {
                                Text("many").tag("many")
                                ForEach(0 ..< 76) { value in
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
                            copyToClipboard("\(includeHash ? "#" : "")click_\(selectedPage.name)_\(userAlias)")
                            showToast(.complete(.green), "Copied to clipboard", "Copied the page feature tag for the user to the clipboard", 3) { }
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
                            .frame(width: 96, alignment: .trailing)
                        Toggle(isOn: $userHasFeaturesOnHub.onChange { value in user.userHasFeaturesOnHub = userHasFeaturesOnHub }) {
                            Text("User featured on Click")
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        .focusable()
                        
                        if userHasFeaturesOnHub {
                            Text("|")
                                .padding([.leading, .trailing])
                            
                            Text("Last date featured:")
                                .foregroundStyle(lastFeaturedOnHub.isEmpty ? Color.TextColorRequired : Color.TextColorPrimary, Color.TextColorSecondary)
                            TextField("", text: $lastFeaturedOnHub.onChange { value in user.lastFeaturedOnHub = lastFeaturedOnHub })
                                .focusable()
                                .autocorrectionDisabled(false)
                                .textFieldStyle(.plain)
                                .padding(4)
                                .background(Color.BackgroundColorEditor)
                                .border(Color.gray.opacity(0.25))
                                .cornerRadius(4)
                            
                            TextField("on page", text: $lastFeaturedPage.onChange { value in user.lastFeaturedPage = lastFeaturedPage })
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
                            Picker("", selection: $featureCountOnSnap.onChange { value in user.featureCountOnSnap = featureCountOnSnap }) {
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
                            copyToClipboard("\(includeHash ? "#" : "")click_featured_\(userAlias)")
                            showToast(.complete(.green), "Copied to clipboard", "Copied the hub feature tag for the user to the clipboard", 3) { }
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
                            .frame(width: 96, alignment: .trailing)
                        Toggle(isOn: $userHasFeaturesOnPage.onChange { value in user.userHasFeaturesOnPage = userHasFeaturesOnPage }) {
                            Text("User featured on page")
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        .focusable()
                        
                        if userHasFeaturesOnPage {
                            Text("|")
                                .padding([.leading, .trailing])
                            
                            Text("Last date featured:")
                                .foregroundStyle(lastFeaturedOnPage.isEmpty ? Color.TextColorRequired : Color.TextColorPrimary, Color.TextColorSecondary)
                            TextField("", text: $lastFeaturedOnPage.onChange { value in user.lastFeaturedOnPage = lastFeaturedOnPage })
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
                            Picker("", selection: $featureCountOnPage.onChange { value in user.featureCountOnPage = featureCountOnPage }) {
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
                            Picker("", selection: $featureCountOnRawPage.onChange { value in user.featureCountOnRawPage = featureCountOnRawPage }) {
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
                            showToast(.complete(.green), "Copied to clipboard", "Copied the Snap page feature tag for the user to the clipboard", 3) { }
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
                            showToast(.complete(.green), "Copied to clipboard", "Copied the RAW page feature tag for the user to the clipboard", 3) { }
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
                            .frame(width: 96, alignment: .trailing)
                        Toggle(isOn: $userHasFeaturesOnHub.onChange { value in user.userHasFeaturesOnHub = userHasFeaturesOnHub }) {
                            Text("User featured on Snap / RAW")
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        .focusable()
                        
                        if userHasFeaturesOnHub {
                            Text("|")
                                .padding([.leading, .trailing])
                            
                            Text("Last date featured:")
                                .foregroundStyle(lastFeaturedOnHub.isEmpty ? Color.TextColorRequired : Color.TextColorPrimary, Color.TextColorSecondary)
                            TextField("", text: $lastFeaturedOnHub.onChange { value in user.lastFeaturedOnHub = lastFeaturedOnHub })
                                .focusable()
                                .autocorrectionDisabled(false)
                                .textFieldStyle(.plain)
                                .padding(4)
                                .background(Color.BackgroundColorEditor)
                                .border(Color.gray.opacity(0.25))
                                .cornerRadius(4)
                            
                            TextField("on page", text: $lastFeaturedPage.onChange { value in user.lastFeaturedPage = lastFeaturedPage })
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
                            Picker("", selection: $featureCountOnSnap.onChange { value in user.featureCountOnSnap = featureCountOnSnap }) {
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
                            Picker("", selection: $featureCountOnRaw.onChange { value in user.featureCountOnRaw = featureCountOnRaw }) {
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
                            showToast(.complete(.green), "Copied to clipboard", "Copied the Snap hub feature tag for the user to the clipboard", 3) { }
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
                            showToast(.complete(.green), "Copied to clipboard", "Copied the RAW hub feature tag for the user to the clipboard", 3) { }
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
                        .frame(width: 96, alignment: .trailing)
                    Toggle(isOn: $tooSoonToFeatureUser.onChange { value in
                        user.tooSoonToFeatureUser = tooSoonToFeatureUser
                        updateList()
                    }) {
                        Text("Too soon to feature user")
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .focusable()

                    Spacer()
                }

                // Verification results
                HStack(alignment: .center) {
                    Text("Validation:")
                        .frame(width: 80, alignment: .trailing)
                        .padding([.trailing], 8)

                    Text("TinEye:")
                    Picker("", selection: $tinEyeResults.onChange { value in
                        user.tinEyeResults = tinEyeResults
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
                        user.aiCheckResults = aiCheckResults
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
        .onChange(of: user, initial: true) {
            isPicked = user.isPicked
            postLink = user.postLink
            userName = user.userName
            userAlias = user.userAlias
            userLevel = user.userLevel
            userIsTeammate = user.userIsTeammate
            tagSource = user.tagSource
            photoFeaturedOnPage = user.photoFeaturedOnPage
            featureDescription = user.featureDescription
            userHasFeaturesOnPage = user.userHasFeaturesOnPage
            lastFeaturedOnPage = user.lastFeaturedOnPage
            featureCountOnPage = user.featureCountOnPage
            userHasFeaturesOnHub = user.userHasFeaturesOnHub
            lastFeaturedOnHub = user.lastFeaturedOnHub
            lastFeaturedPage = user.lastFeaturedPage
            featureCountOnSnap = user.featureCountOnSnap
            featureCountOnRaw = user.featureCountOnRaw
            tooSoonToFeatureUser = user.tooSoonToFeatureUser
            tinEyeResults = user.tinEyeResults
            aiCheckResults = user.aiCheckResults
        }
    }
}

//
//  FeatureListRow.swift
//  Feature Logging
//
//  Created by Andrew Forget on 2024-11-23.
//

import SwiftUI
import UniformTypeIdentifiers
import AlertToast

struct FeatureListRow: View {
    // SHARED FEATURE
    @AppStorage(
        "feature",
        store: UserDefaults(suiteName: "group.com.andydragon.VeroTools")
    ) var sharedFeature = ""
    
    @ObservedObject var feature: Feature
    var loadedPage: LoadedPage
    var pageStaffLevel: StaffLevelCase
    var markDocumentDirty: () -> Void
    var ensureSelected: () -> Void
    var showToast: (_ type: AlertToast.AlertType, _ text: String, _ subTitle: String, _ duration: Int, _ onTap: @escaping () -> Void) -> Void
    var showScriptView: () -> Void
    
    @State var userName = ""
    @State var userAlias = ""
    @State var featureDescription = ""
    @State var photoFeaturedOnHub = false
    @State var userIsTeammate = false
    @State var userHasFeaturesOnPage = false
    @State var userHasFeaturesOnHub = false
    @State var postLink = ""
    @State var showingMessageEditor = false
    
    @AppStorage(
        "preference_personalMessage",
        store: UserDefaults(suiteName: "com.andydragon.com.Feature-Logging")
    ) var personalMessageFormat = "🎉💫 Congratulations on your @%%PAGENAME%% feature %%USERNAME%% @%%USERALIAS%%! %%PERSONALMESSAGE%% 💫🎉"
    @AppStorage(
        "preference_personalMessageFirst",
        store: UserDefaults(suiteName: "com.andydragon.com.Feature-Logging")
    ) var personalMessageFirstFormat = "🎉💫 Congratulations on your first @%%PAGENAME%% feature %%USERNAME%% @%%USERALIAS%%! %%PERSONALMESSAGE%% 💫🎉"
    
    var body: some View {
        HStack(alignment: .center) {
            if feature.photoFeaturedOnPage {
                Image(systemName: "exclamationmark.octagon.fill")
                    .foregroundColor(.red)
                    .font(.system(size: 20))
                    .frame(width: 32, height: 32)
                    .help("Photo is already featured on this page")
            } else if feature.tooSoonToFeatureUser {
                Image(systemName: "stopwatch.fill")
                    .foregroundColor(.red)
                    .font(.system(size: 20))
                    .frame(width: 32, height: 32)
                    .help("Too soon to feature this user")
            } else if feature.tinEyeResults == .matchFound {
                Image(systemName: "eye.trianglebadge.exclamationmark")
                    .foregroundColor(.red)
                    .font(.system(size: 20))
                    .frame(width: 32, height: 32)
                    .help("TinEye matches found, possibly stolen photo")
            } else if feature.aiCheckResults == .ai {
                Image(systemName: "gear.badge.xmark")
                    .foregroundColor(.red)
                    .font(.system(size: 20))
                    .frame(width: 32, height: 32)
                    .help("AI check verdict is image is AI generated")
            } else if feature.isPicked {
                Image(systemName: "star.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 20))
                    .frame(width: 32, height: 32)
                    .help("Photo is picked for feature")
            } else {
                Image(systemName: "xmark")
                    .foregroundColor(.gray)
                    .font(.system(size: 20))
                    .frame(width: 32, height: 32)
                    .opacity(0.0000001)
            }
            
            VStack {
                HStack {
                    Text("Feature: ")
                    
                    if !userName.isEmpty {
                        Text(userName)
                    } else {
                        Text("user name")
                            .foregroundStyle(.gray, .secondary)
                            .italic()
                    }
                    
                    Text(" | ")
                    
                    if !userAlias.isEmpty {
                        Text("@\(userAlias)")
                    } else {
                        Text("user alias")
                            .foregroundStyle(.gray, .secondary)
                            .italic()
                    }
                    
                    Text(" | ")
                    
                    if !featureDescription.isEmpty {
                        Text(featureDescription)
                    } else {
                        Text("description")
                            .foregroundStyle(.gray, .secondary)
                            .italic()
                    }
                    
                    Text(" | ")
                    
                    Image(systemName: "tag.square")
                        .foregroundStyle(photoFeaturedOnHub ? Color.AccentColor : Color.TextColorSecondary, photoFeaturedOnHub ? Color.AccentColor : Color.TextColorSecondary)
                        .font(.system(size: 14))
                        .frame(width: 16, height: 16)
                        .help(photoFeaturedOnHub ? "Photo featured on hub" : "Photo not featured on hub")
                    Spacer()
                        .frame(width: 6)
                    Image(systemName: "tag")
                        .foregroundStyle(userHasFeaturesOnPage ? Color.AccentColor : Color.TextColorSecondary, Color.TextColorSecondary)
                        .font(.system(size: 14))
                        .frame(width: 16, height: 16)
                        .help(userHasFeaturesOnPage ? "User has features on page" : "First feature on page")
                    Spacer()
                        .frame(width: 6)
                    Image(systemName: "tag.fill")
                        .foregroundStyle(userHasFeaturesOnHub ? Color.AccentColor : Color.TextColorSecondary, Color.TextColorSecondary)
                        .font(.system(size: 14))
                        .frame(width: 16, height: 16)
                        .help(userHasFeaturesOnHub ? "User has features on hub" : "First feature on hub")
                    Spacer()
                        .frame(width: 6)
                    Image(systemName: "person.badge.key.fill")
                        .foregroundStyle(Color.TextColorSecondary, userIsTeammate ? Color.AccentColor : Color.TextColorSecondary)
                        .font(.system(size: 14))
                        .frame(width: 16, height: 16)
                        .help(userIsTeammate ? "User is teammate" : "User is not a teammate")
                    
                    Spacer()
                    
                    if feature.isPickedAndAllowed {
                        Button(action: {
                            ensureSelected()
                            launchVeroScripts()
                        }) {
                            HStack(alignment: .center) {
                                Image(systemName: "pencil.and.list.clipboard")
                                    .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                                Text("Edit scripts")
                            }
                        }
                        
                        Spacer()
                            .frame(width: 8)
                        
                        Button(action: {
                            ensureSelected()
                            showingMessageEditor.toggle()
                        }) {
                            HStack(alignment: .center) {
                                Image(systemName: "square.and.pencil")
                                    .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                                Text("Edit personal message")
                            }
                        }
                        .disabled(!feature.isPickedAndAllowed)
                    }
                }
                HStack {
                    Text(postLink)
                        .font(.footnote)
                    
                    Spacer()
                }
            }
            .sheet(isPresented: $showingMessageEditor, content: {
                ZStack {
                    Color.BackgroundColor.edgesIgnoringSafeArea(.all)
                    
                    VStack(alignment: .leading)  {
                        Text("Personal message for feature: \(feature.userName) - \(feature.featureDescription)")
                        
                        Spacer()
                            .frame(height: 8)
                        
                        HStack(alignment: .center) {
                            Text("Personal message (from your account): ")
                            TextField("", text: $feature.personalMessage.onChange { value in
                                markDocumentDirty()
                            })
                            .focusable()
                            .autocorrectionDisabled(false)
                            .disableAutocorrection(false)
                            .textFieldStyle(.plain)
                            .padding(4)
                            .background(Color.BackgroundColorEditor)
                            .border(Color.gray.opacity(0.25))
                            .cornerRadius(4)
                        }
                        
                        Spacer()
                        
                        HStack(alignment: .center)  {
                            Spacer()
                            
                            Button(action: {
                                let personalMessage = feature.personalMessage.isEmpty ? "[PERSONAL MESSAGE]" : feature.personalMessage
                                let personalMessageTemplate = feature.userHasFeaturesOnPage ? personalMessageFormat : personalMessageFirstFormat
                                let fullPersonalMessage = personalMessageTemplate
                                    .replacingOccurrences(of: "%%PAGENAME%%", with: loadedPage.displayName)
                                    .replacingOccurrences(of: "%%HUBNAME%%", with: loadedPage.hub == "other" ? "" : loadedPage.hub)
                                    .replacingOccurrences(of: "%%USERNAME%%", with: feature.userName)
                                    .replacingOccurrences(of: "%%USERALIAS%%", with: feature.userAlias)
                                    .replacingOccurrences(of: "%%PERSONALMESSAGE%%", with: personalMessage)
                                copyToClipboard(fullPersonalMessage)
                                showingMessageEditor.toggle()
                                showToast(.complete(.green), "Copied to clipboard", "The personal message was copied to the clipboard", 2) { }
                            }) {
                                HStack(alignment: .center) {
                                    Image(systemName: "pencil.and.list.clipboard")
                                        .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                                    Text("Copy full text")
                                }
                            }
                            
                            Button(action: {
                                showingMessageEditor.toggle()
                            }) {
                                HStack(alignment: .center) {
                                    Image(systemName: "xmark")
                                        .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                                    Text("Close")
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                }
                .frame(width: 800, height: 160)
            })
        }
        .onChange(of: feature, initial: true) {
            userName = feature.userName
            userAlias = feature.userAlias
            featureDescription = feature.featureDescription
            userIsTeammate = feature.userIsTeammate
            photoFeaturedOnHub = feature.photoFeaturedOnHub
            userHasFeaturesOnPage = feature.userHasFeaturesOnPage
            userHasFeaturesOnHub = feature.userHasFeaturesOnHub
            postLink = feature.postLink
        }
        .onChange(of: feature.userName) {
            userName = feature.userName
        }
        .onChange(of: feature.userAlias) {
            userAlias = feature.userAlias
        }
        .onChange(of: feature.featureDescription) {
            featureDescription = feature.featureDescription
        }
        .onChange(of: feature.userIsTeammate) {
            userIsTeammate = feature.userIsTeammate
        }
        .onChange(of: feature.photoFeaturedOnHub) {
            photoFeaturedOnHub = feature.photoFeaturedOnHub
        }
        .onChange(of: feature.userHasFeaturesOnPage) {
            userHasFeaturesOnPage = feature.userHasFeaturesOnPage
        }
        .onChange(of: feature.userHasFeaturesOnHub) {
            userHasFeaturesOnHub = feature.userHasFeaturesOnHub
        }
        .onChange(of: feature.postLink) {
            postLink = feature.postLink
        }
    }
    
    private func launchVeroScripts() {
        if feature.photoFeaturedOnPage {
            showToast(.systemImage("exclamationmark.octagon.fill", .red), "Cannot feature photo", "That photo has already been featured on this page", 0) { }
            return
        }
        if feature.tinEyeResults == .matchFound {
            showToast(.systemImage("exclamationmark.octagon.fill", .red), "Cannot feature photo", "This photo had a TinEye match", 0) { }
            return
        }
        if feature.aiCheckResults == .ai {
            showToast(.systemImage("exclamationmark.octagon.fill", .red), "Cannot feature photo", "This photo was flagged as AI", 0) { }
            return
        }
        if feature.tooSoonToFeatureUser {
            showToast(.systemImage("exclamationmark.octagon.fill", .red), "Cannot feature photo", "The user has been featured too recently", 0) { }
            return
        }
        if !feature.isPicked {
            showToast(.systemImage("exclamationmark.triangle.fill", .yellow), "Should not feature photo", "The photo is not marked as picked, mark the photo as picked and try again", 0) { }
            return
        }
        do {
            // Encode the feature for the scripts view
            let encoder = JSONEncoder()
            let json = try encoder.encode(CodableFeature(using: loadedPage, pageStaffLevel: pageStaffLevel, from: feature))
            let jsonString = String(decoding: json, as: UTF8.self)
            
            // Store the feature in the shared storage
            sharedFeature = jsonString
            
            // Launch the ScriptContentView
            showScriptView()
        } catch {
            debugPrint(error)
        }
    }
}

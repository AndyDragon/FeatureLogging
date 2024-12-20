//
//  FeatureListRow.swift
//  Feature Logging
//
//  Created by Andrew Forget on 2024-11-23.
//

import AlertToast
import SwiftUI

struct FeatureListRow: View {
    private var viewModel: ContentView.ViewModel
    private var toastManager: ContentView.ToastManager
    @Bindable private var feature: ObservableFeature
    private var showScriptView: () -> Void

    @State var showingMessageEditor = false

    @AppStorage(
        "preference_personalMessage",
        store: UserDefaults(suiteName: "com.andydragon.com.Feature-Logging")
    ) var personalMessageFormat = "🎉💫 Congratulations on your @%%PAGENAME%% feature %%USERNAME%% @%%USERALIAS%%! %%PERSONALMESSAGE%% 💫🎉"
    @AppStorage(
        "preference_personalMessageFirst",
        store: UserDefaults(suiteName: "com.andydragon.com.Feature-Logging")
    ) var personalMessageFirstFormat = "🎉💫 Congratulations on your first @%%PAGENAME%% feature %%USERNAME%% @%%USERALIAS%%! %%PERSONALMESSAGE%% 💫🎉"

    init(
        _ viewModel: ContentView.ViewModel,
        _ toastManager: ContentView.ToastManager,
        _ feature: ObservableFeature,
        _ showScriptView: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.toastManager = toastManager
        self.feature = feature
        self.showScriptView = showScriptView
    }
    
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

                    if !feature.userName.isEmpty {
                        Text(feature.userName)
                    } else {
                        Text("user name")
                            .foregroundStyle(.gray, .secondary)
                            .italic()
                    }

                    Text(" | ")

                    if !feature.userAlias.isEmpty {
                        Text("@\(feature.userAlias)")
                    } else {
                        Text("user alias")
                            .foregroundStyle(.gray, .secondary)
                            .italic()
                    }

                    Text(" | ")

                    if !feature.featureDescription.isEmpty {
                        Text(feature.featureDescription)
                    } else {
                        Text("description")
                            .foregroundStyle(.gray, .secondary)
                            .italic()
                    }

                    Text(" | ")

                    Image(systemName: "tag.square")
                        .foregroundStyle(feature.photoFeaturedOnHub ? Color.AccentColor : Color.TextColorSecondary, feature.photoFeaturedOnHub ? Color.AccentColor : Color.TextColorSecondary)
                        .font(.system(size: 14))
                        .frame(width: 16, height: 16)
                        .help(feature.photoFeaturedOnHub ? "Photo featured on hub" : "Photo not featured on hub")
                    Spacer()
                        .frame(width: 6)
                    Image(systemName: "tag")
                        .foregroundStyle(feature.userHasFeaturesOnPage ? Color.AccentColor : Color.TextColorSecondary, Color.TextColorSecondary)
                        .font(.system(size: 14))
                        .frame(width: 16, height: 16)
                        .help(feature.userHasFeaturesOnPage ? "User has features on page" : "First feature on page")
                    Spacer()
                        .frame(width: 6)
                    Image(systemName: "tag.fill")
                        .foregroundStyle(feature.userHasFeaturesOnHub ? Color.AccentColor : Color.TextColorSecondary, Color.TextColorSecondary)
                        .font(.system(size: 14))
                        .frame(width: 16, height: 16)
                        .help(feature.userHasFeaturesOnHub ? "User has features on hub" : "First feature on hub")
                    Spacer()
                        .frame(width: 6)
                    Image(systemName: "person.badge.key.fill")
                        .foregroundStyle(Color.TextColorSecondary, feature.userIsTeammate ? Color.AccentColor : Color.TextColorSecondary)
                        .font(.system(size: 14))
                        .frame(width: 16, height: 16)
                        .help(feature.userIsTeammate ? "User is teammate" : "User is not a teammate")

                    Spacer()

                    if feature.isPickedAndAllowed {
                        Button(action: {
                            viewModel.selectedFeature = ObservableFeatureWrapper(using: viewModel.selectedPage!, from: feature)
                            launchVeroScripts()
                        }) {
                            HStack(alignment: .center) {
                                Image(systemName: "pencil.and.list.clipboard")
                                    .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                                Text("Edit scripts")
                            }
                        }
                        .focusable()
                        .onKeyPress(.space) {
                            viewModel.selectedFeature = ObservableFeatureWrapper(using: viewModel.selectedPage!, from: feature)
                            launchVeroScripts()
                            return .handled
                        }

                        Spacer()
                            .frame(width: 8)

                        Button(action: {
                            viewModel.selectedFeature = ObservableFeatureWrapper(using: viewModel.selectedPage!, from: feature)
                            showingMessageEditor.toggle()
                        }) {
                            HStack(alignment: .center) {
                                Image(systemName: "square.and.pencil")
                                    .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                                Text("Edit personal message")
                            }
                        }
                        .focusable()
                        .onKeyPress(.space) {
                            viewModel.selectedFeature = ObservableFeatureWrapper(using: viewModel.selectedPage!, from: feature)
                            showingMessageEditor.toggle()
                            return .handled
                        }
                    }
                }
                HStack {
                    Text(feature.postLink)
                        .font(.footnote)

                    Spacer()
                }
            }
            .sheet(
                isPresented: $showingMessageEditor,
                content: {
                    ZStack {
                        Color.BackgroundColor.edgesIgnoringSafeArea(.all)

                        VStack(alignment: .leading) {
                            Text("Personal message for feature: \(feature.userName) - \(feature.featureDescription)")

                            Spacer()
                                .frame(height: 8)

                            HStack(alignment: .center) {
                                Text("Personal message (from your account): ")
                                TextField(
                                    "",
                                    text: $feature.personalMessage.onChange { value in
                                        viewModel.markDocumentDirty()
                                    }
                                )
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

                            HStack(alignment: .center) {
                                Spacer()

                                Button(action: {
                                    copyPersonalMessage()
                                }) {
                                    HStack(alignment: .center) {
                                        Image(systemName: "pencil.and.list.clipboard")
                                            .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                                        Text("Copy full text")
                                    }
                                }
                                .focusable()
                                .onKeyPress(.space) {
                                    copyPersonalMessage()
                                    return .handled
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
                                .focusable()
                                .onKeyPress(.space) {
                                    showingMessageEditor.toggle()
                                    return .handled
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                    }
                    .frame(width: 800, height: 160)
                })
        }
        .testBackground()
    }

    private func copyPersonalMessage() {
        let personalMessage = feature.personalMessage.isEmpty ? "[PERSONAL MESSAGE]" : feature.personalMessage
        let personalMessageTemplate = feature.userHasFeaturesOnPage ? personalMessageFormat : personalMessageFirstFormat
        let fullPersonalMessage =
        personalMessageTemplate
            .replacingOccurrences(of: "%%PAGENAME%%", with: viewModel.selectedPage!.displayName)
            .replacingOccurrences(of: "%%HUBNAME%%", with: viewModel.selectedPage!.hub == "other" ? "" : viewModel.selectedPage!.hub)
            .replacingOccurrences(of: "%%USERNAME%%", with: feature.userName)
            .replacingOccurrences(of: "%%USERALIAS%%", with: feature.userAlias)
            .replacingOccurrences(of: "%%PERSONALMESSAGE%%", with: personalMessage)
        copyToClipboard(fullPersonalMessage)
        showingMessageEditor.toggle()
        toastManager.showCompletedToast("Copied to clipboard", "The personal message was copied to the clipboard")
    }

    private func launchVeroScripts() {
        if feature.photoFeaturedOnPage {
            toastManager.showToast(.systemImage("exclamationmark.octagon.fill", .red), "Cannot feature photo", "That photo has already been featured on this page", .Blocking, {})
            return
        }
        if feature.tinEyeResults == .matchFound {
            toastManager.showToast(.systemImage("exclamationmark.octagon.fill", .red), "Cannot feature photo", "This photo had a TinEye match", .Blocking, {})
            return
        }
        if feature.aiCheckResults == .ai {
            toastManager.showToast(.systemImage("exclamationmark.octagon.fill", .red), "Cannot feature photo", "This photo was flagged as AI", .Blocking, {})
            return
        }
        if feature.tooSoonToFeatureUser {
            toastManager.showToast(.systemImage("exclamationmark.octagon.fill", .red), "Cannot feature photo", "The user has been featured too recently", .Blocking, {})
            return
        }
        if !feature.isPicked {
            toastManager.showToast(
                .systemImage("exclamationmark.triangle.fill", .yellow), "Should not feature photo", "The photo is not marked as picked, mark the photo as picked and try again", .Blocking, {})
            return
        }

        // Store the feature in the shared storage
        viewModel.selectedFeature = ObservableFeatureWrapper(using: viewModel.selectedPage!, from: feature)

        // Launch the ScriptContentView
        showScriptView()
    }
}

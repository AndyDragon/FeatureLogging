//
//  FeatureListRow.swift
//  Feature Logging
//
//  Created by Andrew Forget on 2024-11-23.
//

import SwiftUI
import SwiftyBeaver

struct FeatureListRow: View {
    private var viewModel: ContentView.ViewModel
    @Bindable private var feature: ObservableFeature

    @State var showingMessageEditor = false

    @AppStorage(
        "preference_personalMessage",
        store: UserDefaults(suiteName: "com.andydragon.com.Feature-Logging")
    ) var personalMessageFormat = "🎉💫 Congratulations on your @%%PAGENAME%% feature %%USERNAME%% @%%USERALIAS%%! %%PERSONALMESSAGE%% 💫🎉"
    @AppStorage(
        "preference_personalMessageFirst",
        store: UserDefaults(suiteName: "com.andydragon.com.Feature-Logging")
    ) var personalMessageFirstFormat = "🎉💫 Congratulations on your first @%%PAGENAME%% feature %%USERNAME%% @%%USERALIAS%%! %%PERSONALMESSAGE%% 💫🎉"

    private let logger = SwiftyBeaver.self

    init(
        _ viewModel: ContentView.ViewModel,
        _ feature: ObservableFeature
    ) {
        self.viewModel = viewModel
        self.feature = feature
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
                        .font(.system(size: 13))

                    if !feature.userName.isEmpty {
                        Text(feature.userName)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .font(.system(size: 13))
                    } else {
                        Text("user name")
                            .foregroundStyle(.gray, .secondary)
                            .italic()
                            .font(.system(size: 13))
                    }

                    Text(" | ")

                    if !feature.userAlias.isEmpty {
                        Text("@\(feature.userAlias)")
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .font(.system(size: 13))
                    } else {
                        Text("user alias")
                            .foregroundStyle(.gray, .secondary)
                            .italic()
                            .font(.system(size: 13))
                    }

                    Text(" | ")

                    if !feature.featureDescription.isEmpty {
                        Text(feature.featureDescription)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .font(.system(size: 13))
                    } else {
                        Text("description")
                            .foregroundStyle(.gray, .secondary)
                            .italic()
                            .font(.system(size: 13))
                    }

                    Text(" | ")

                    Image(systemName: "tag.square")
                        .foregroundStyle(
                            feature.photoFeaturedOnHub ? Color.accentColor : Color(UIColor.secondaryLabel).opacity(0.5),
                            feature.photoFeaturedOnHub ? Color(UIColor.secondaryLabel) : Color(UIColor.secondaryLabel).opacity(0.5))
                        .font(.system(size: 13))
                        .frame(width: 16, height: 16)
                        .help(feature.photoFeaturedOnHub ? "Photo featured on hub" : "Photo not featured on hub")
                    Spacer()
                        .frame(width: 6)
                    Image(systemName: "tag")
                        .foregroundStyle(
                            feature.userHasFeaturesOnPage ? Color.accentColor : Color(UIColor.secondaryLabel).opacity(0.5),
                            feature.userHasFeaturesOnPage ? Color(UIColor.secondaryLabel) : Color(UIColor.secondaryLabel).opacity(0.5))
                        .font(.system(size: 13))
                        .frame(width: 16, height: 16)
                        .help(feature.userHasFeaturesOnPage ? "User has features on page" : "First feature on page")
                    Spacer()
                        .frame(width: 6)
                    Image(systemName: "tag.fill")
                        .foregroundStyle(
                            feature.userHasFeaturesOnHub ? Color.accentColor : Color(UIColor.secondaryLabel).opacity(0.5),
                            feature.userHasFeaturesOnHub ? Color(UIColor.secondaryLabel) : Color(UIColor.secondaryLabel).opacity(0.5))
                        .font(.system(size: 13))
                        .frame(width: 16, height: 16)
                        .help(feature.userHasFeaturesOnHub ? "User has features on hub" : "First feature on hub")
                    Spacer()
                        .frame(width: 6)
                    Image(systemName: "person.badge.key.fill")
                        .foregroundStyle(
                            feature.userIsTeammate ? Color(UIColor.secondaryLabel) : Color(UIColor.secondaryLabel).opacity(0.5),
                            feature.userIsTeammate ? Color.accentColor : Color(UIColor.secondaryLabel).opacity(0.5))
                        .font(.system(size: 13))
                        .frame(width: 16, height: 16)
                        .help(feature.userIsTeammate ? "User is teammate" : "User is not a teammate")

                    let validationResult = feature.validationResult
                    if validationResult != .Success {
                        Text(" | ")
                        validationResult.getImage()
                            .help(validationResult == .Warning ? "Feature has some warnings" : "Feature has some errors")
                    }

                    Spacer()
                }
                HStack {
                    if !feature.postLink.isEmpty {
                        Text(feature.postLink)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .font(.system(size: 12))
                    } else {
                        Text("link to post")
                            .foregroundStyle(.gray, .secondary)
                            .italic()
                            .font(.system(size: 12))
                    }

                    Spacer()
                }
            }

            Spacer()

            if feature.isPickedAndAllowed {
                Spacer()
                    .frame(width: 12)

                Button(action: {
                    logger.verbose("Tapped edit scripts for feature", context: "User")
                    viewModel.selectedFeature = ObservableFeatureWrapper(using: viewModel.selectedPage!, from: feature)
                    launchVeroScripts()
                }) {
                    HStack(alignment: .center) {
                        Image(systemName: "pencil.and.list.clipboard")
                            .foregroundStyle(Color.accentColor, Color(UIColor.secondaryLabel))
                    }
                }
                .buttonStyle(.plain)

                Spacer()
                    .frame(width: 12)

                Button(action: {
                    logger.verbose("Tapped edit personal message for feature", context: "User")
                    viewModel.selectedFeature = ObservableFeatureWrapper(using: viewModel.selectedPage!, from: feature)
                    showingMessageEditor.toggle()
                }) {
                    HStack(alignment: .center) {
                        Image(systemName: "bubble.and.pencil")
                            .foregroundStyle(Color.accentColor, Color(UIColor.secondaryLabel))
                    }
                }
                .buttonStyle(.plain)
            }

            if feature.isPickAllowed {
                Spacer()
                    .frame(width: 12)

                Button(action: {
                    feature.isPicked.toggle()
                }) {
                    HStack(alignment: .center) {
                        Image(systemName: feature.isPicked ? "star.slash" : "star")
                            .foregroundStyle(Color.accentColor, Color(UIColor.secondaryLabel))
                    }
                }
                .buttonStyle(.plain)
            }

            Spacer()
                .frame(width: 12)

            Button(action: {
                withAnimation {
                    viewModel.selectedFeature = ObservableFeatureWrapper(using: viewModel.selectedPage!, from: feature)
                    viewModel.visibleView = .FeatureEditorView
                }
            }) {
                HStack(alignment: .center) {
                    Image(systemName: "pencil")
                        .foregroundStyle(Color.accentColor, Color(UIColor.secondaryLabel))
                }
            }
            .buttonStyle(.plain)

            Spacer()
                .frame(width: 12)

            Button(action: {
                viewModel.selectedFeature = nil
                viewModel.features.removeAll(where: { $0.id == feature.id })
                viewModel.markDocumentDirty()
            }) {
                HStack(alignment: .center) {
                    Image(systemName: "trash")
                        .foregroundStyle(Color.accentColor, Color(UIColor.secondaryLabel))
                }
            }
            .buttonStyle(.plain)
        }
        .sheet(
            isPresented: $showingMessageEditor,
            content: {
                ZStack {
                    Color.backgroundColor.edgesIgnoringSafeArea(.all)

                    VStack(alignment: .leading) {
                        Text("Personal message for feature: \(feature.userName) - \(feature.featureDescription)")

                        Spacer()
                            .frame(height: 8)

                        HStack(alignment: .center) {
                            Text("Personal message (from your account): ")
                            TextField(
                                "",
                                text: $feature.personalMessage.onChange { _ in
                                    viewModel.markDocumentDirty()
                                }
                            )
                            .autocorrectionDisabled(false)
                            .disableAutocorrection(false)
                            .textFieldStyle(.plain)
                            .padding(4)
                            .background(Color.backgroundColor.opacity(0.5))
                            .border(Color.gray.opacity(0.25))
                            .cornerRadius(4)
                        }

                        Spacer()

                        HStack(alignment: .center) {
                            Spacer()

                            Button(action: {
                                logger.verbose("Tapped copy personal message for feature", context: "User")
                                copyPersonalMessage()
                            }) {
                                HStack(alignment: .center) {
                                    Image(systemName: "pencil.and.list.clipboard")
                                        .foregroundStyle(Color.accentColor, Color(UIColor.secondaryLabel))
                                    Text("Copy full text")
                                }
                            }
                            .buttonStyle(.bordered)

                            Button(action: {
                                showingMessageEditor.toggle()
                            }) {
                                HStack(alignment: .center) {
                                    Image(systemName: "xmark")
                                        .foregroundStyle(Color.accentColor, Color(UIColor.secondaryLabel))
                                    Text("Close")
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                }
                .frame(width: 800, height: 160)
            })
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
        viewModel.showSuccessToast("Copied to clipboard", "The personal message was copied to the clipboard")
    }

    private func launchVeroScripts() {
        if feature.photoFeaturedOnPage {
            viewModel.showToast(.error, "Cannot feature photo", "That photo has already been featured on this page")
            return
        }
        if feature.tinEyeResults == .matchFound {
            viewModel.showToast(.error, "Cannot feature photo", "This photo had a TinEye match")
            return
        }
        if feature.aiCheckResults == .ai {
            viewModel.showToast(.error, "Cannot feature photo", "This photo was flagged as AI")
            return
        }
        if feature.tooSoonToFeatureUser {
            viewModel.showToast(.error, "Cannot feature photo", "The user has been featured too recently")
            return
        }
        if !feature.isPicked {
            viewModel.showToast(.alert, "Should not feature photo", "The photo is not marked as picked, mark the photo as picked and try again")
            return
        }

        // Store the feature in the shared storage
        viewModel.selectedFeature = ObservableFeatureWrapper(using: viewModel.selectedPage!, from: feature)

        // Launch the ScriptContentView
        viewModel.visibleView = .ScriptView
    }
}

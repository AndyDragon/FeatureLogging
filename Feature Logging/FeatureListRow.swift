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
                Image(systemName: "star.fill")
                    .foregroundColor(.gray)
                    .font(.system(size: 20))
                    .frame(width: 32, height: 32)
                    .help("Photo is not picked for feature")
                    .opacity(0.00001)
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
                        .foregroundStyle(feature.photoFeaturedOnHub ? Color.accentColor : Color.secondaryLabel, feature.photoFeaturedOnHub ? Color.accentColor : Color.secondaryLabel)
                        .font(.system(size: 13))
                        .frame(width: 14, height: 16)
                        .imageScale(.small)
                        .padding(.top, 3)
                        .help(feature.photoFeaturedOnHub ? "Photo featured on hub" : "Photo not featured on hub")
                    Spacer()
                        .frame(width: 2)
                    Image(systemName: "tag")
                        .foregroundStyle(feature.userHasFeaturesOnPage ? Color.accentColor : Color.secondaryLabel, Color.secondaryLabel)
                        .font(.system(size: 13))
                        .frame(width: 14, height: 16)
                        .imageScale(.small)
                        .padding(.top, 3)
                        .help(feature.userHasFeaturesOnPage ? "User has features on page" : "First feature on page")
                    Spacer()
                        .frame(width: 2)
                    Image(systemName: "tag.fill")
                        .foregroundStyle(feature.userHasFeaturesOnHub ? Color.accentColor : Color.secondaryLabel, Color.secondaryLabel)
                        .font(.system(size: 13))
                        .frame(width: 14, height: 16)
                        .imageScale(.small)
                        .padding(.top, 3)
                        .help(feature.userHasFeaturesOnHub ? "User has features on hub" : "First feature on hub")
                    Spacer()
                        .frame(width: 2)
                    Image(systemName: "person.badge.key.fill")
                        .foregroundStyle(Color.secondaryLabel, feature.userIsTeammate ? Color.accentColor : Color.secondaryLabel)
                        .font(.system(size: 13))
                        .frame(width: 14, height: 16)
                        .imageScale(.small)
                        .padding(.top, 3)
                        .help(feature.userIsTeammate ? "User is teammate" : "User is not a teammate")

                    let validationResult = feature.validationResult(viewModel)
                    if validationResult != .valid {
                        Spacer()
                            .frame(width: 2)
                        validationResult.getImage(small: true)
                            .padding(.top, 3)
                            .help(!validationResult.isError ? "Feature has some warnings" : "Feature has some errors")
                    }

                    Spacer()

                    if feature.isPickAllowed {
                        Button(action: {
                            feature.isPicked.toggle()
                        }) {
                            HStack(alignment: .center) {
                                Image(systemName: feature.isPicked ? "star.slash" : "star")
                                    .foregroundStyle(Color.white, Color(Color.secondaryLabel))
                                Text(feature.isPicked ? "Unpick" : "Pick")
                            }
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer()
                        .frame(width: 12)

                    Button(action: {
                        viewModel.selectedFeature = nil
                        viewModel.features.removeAll(where: { $0.id == feature.id })
                        viewModel.markDocumentDirty()
                    }) {
                        HStack(alignment: .center) {
                            Image(systemName: "trash")
                                .foregroundStyle(Color.white, Color(Color.secondaryLabel))
                            Text("Remove")
                        }
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                    }
                    .buttonStyle(.plain)

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
                                    .foregroundStyle(Color.white, Color(Color.secondaryLabel))
                                Text("Edit scripts")
                            }
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
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
                                    .foregroundStyle(Color.white, Color(Color.secondaryLabel))
                                Text("Edit message")
                            }
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                        }
                        .buttonStyle(.plain)
                    }
                }
                HStack {
                    if !feature.postLink.isEmpty {
                        Text(feature.postLink)
                            .font(.footnote)
                    } else {
                        Text("link to post")
                            .font(.footnote)
                            .foregroundStyle(.gray, .secondary)
                            .italic()
                    }

                    Spacer()
                }
            }
            .sheet(
                isPresented: $showingMessageEditor,
                content: {
                    ZStack {
                        Color.backgroundColor.edgesIgnoringSafeArea(.all)

                        VStack(alignment: .leading) {
                            Text("Personal message for feature:")
                            if !feature.userName.isEmpty {
                                Text("\(feature.userName) (\(feature.userAlias))")
                                    .padding(.leading, 12)
                            } else {
                                Text("\(feature.userAlias)")
                                    .padding(.leading, 12)
                            }
                            if !feature.featureDescription.isEmpty {
                                Text("\(feature.featureDescription)")
                                    .padding(.leading, 12)
                            } else {
                                Text("- no description -")
                                    .padding(.leading, 12)
                                    .italic()
                            }

                            Spacer()
                                .frame(height: 16)

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
                                .background(Color.controlBackground.opacity(0.5))
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
                                            .foregroundStyle(Color.accentColor, Color.secondaryLabel)
                                        Text("Copy full text")
                                    }
                                }
                                .focusable()
                                .onKeyPress(.space) {
                                    logger.verbose("Pressed space on copy personal message for feature", context: "User")
                                    copyPersonalMessage()
                                    return .handled
                                }

                                Button(action: {
                                    showingMessageEditor.toggle()
                                }) {
                                    HStack(alignment: .center) {
                                        Image(systemName: "xmark")
                                            .foregroundStyle(Color.accentColor, Color.secondaryLabel)
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
    }
}

extension FeatureListRow {
    // MARK: - utilities

    private func copyPersonalMessage() {
        let personalMessage = feature.personalMessage.isEmpty ? "[PERSONAL MESSAGE]" : feature.personalMessage
        let personalMessageTemplate = feature.userHasFeaturesOnPage ? personalMessageFormat : personalMessageFirstFormat
        let fullPersonalMessage = personalMessageTemplate
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

//
//  ImageValidationView.swift
//  Feature Logging
//
//  Created by Andrew Forget on 2024-03-11.
//

import AlertToast
import SwiftUI
import UniformTypeIdentifiers

enum AiVerdict {
    case notAi
    case ai
    case indeterminate
}

struct ImageValidationView: View {
    @Environment(\.openURL) private var openURL

    private var viewModel: ContentView.ViewModel
    private var toastManager: ContentView.ToastManager
    @State private var focusedField: FocusState<FocusField?>.Binding
    @State private var imageValidationImageUrl: Binding<URL?>
    private var hideImageValidationView: () -> Void
    private var updateList: () -> Void

    @State private var aiVerdictString = ""
    @State private var aiVerdict = AiVerdict.indeterminate
    @State private var returnedJson = ""
    @State private var errorFromServer = ""
    @State private var uploadToServer: String? = nil
    @State private var loadedImageUrl: URL?
    @State private var isLoading = false
    @State private var error: Error?

    private let languagePrefix = Locale.preferredLanguageCode

    init(
        _ viewModel: ContentView.ViewModel,
        _ toastManager: ContentView.ToastManager,
        _ focusedField: FocusState<FocusField?>.Binding,
        _ imageValidationImageUrl: Binding<URL?>,
        _ hideImageValidationView: @escaping () -> Void,
        _ updateList: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.toastManager = toastManager
        self.focusedField = focusedField
        self.imageValidationImageUrl = imageValidationImageUrl
        self.hideImageValidationView = hideImageValidationView
        self.updateList = updateList
    }

    var body: some View {
        ZStack {
            Color.BackgroundColor.edgesIgnoringSafeArea(.all)

            if viewModel.selectedFeature != nil {
                let selectedFeature = Binding<ObservableFeatureWrapper>(
                    get: { viewModel.selectedFeature! },
                    set: { viewModel.selectedFeature = $0 }
                )

                VStack(alignment: .leading) {
                    VStack(alignment: .leading) {
                        HStack(alignment: .center) {
                            Spacer()
                                .frame(width: 0, height: 26)
                            Text("TinEye:")
                            Picker(
                                "",
                                selection: selectedFeature.feature.tinEyeResults.onChange { value in
                                    navigateToTinEyeResult(selectedFeature, .same)
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
                            .frame(width: 160)
                            .focusable()
                            .focused(focusedField, equals: .tinEyeResults)
                            .onKeyPress(phases: .down) { keyPress in
                                return navigateToTinEyeResultWithArrows(selectedFeature, keyPress)
                            }
                            .onKeyPress(characters: .alphanumerics) { keyPress in
                                return navigateToTinEyeResultWithPrefix(selectedFeature, keyPress)
                            }

                            Text("|")
                                .padding([.leading, .trailing])

                            Text("AI Check:")
                            Picker(
                                "",
                                selection: selectedFeature.feature.aiCheckResults.onChange { value in
                                    navigateToAiCheckResult(selectedFeature, .same)
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
                            .frame(width: 160)
                            .focusable()
                            .focused(focusedField, equals: .aiCheckResults)
                            .onKeyPress(phases: .down) { keyPress in
                                return navigateToAiCheckResultWithArrows(selectedFeature, keyPress)
                            }
                            .onKeyPress(phases: .down) { keyPress in
                                return navigateToAiCheckResultWithPrefix(selectedFeature, keyPress)
                            }

                            if !aiVerdictString.isEmpty {
                                Text("|")
                                    .padding([.leading, .trailing])

                                HStack {
                                    Text("HIVE verdict: ")
                                    Text(aiVerdictString)
                                    Image(systemName: aiVerdict == .notAi ? "checkmark.shield" : aiVerdict == .ai ? "exclamationmark.warninglight" : "questionmark.diamond")
                                }
                                .font(.system(size: 24))
                                .foregroundStyle(aiVerdict == .notAi ? .green : aiVerdict == .ai ? .red : .yellow, .secondary)
                            }

                            Spacer()
                        }

                        CustomTabView(tabBarPosition: .top, content: [
                            (
                                tabText: "TinEye Results",
                                tabIconName: "globe",
                                tabIconColors: (.accentColor, .secondary),
                                view: AnyView(
                                    VStack {
                                        if let realizedImageUrl = loadedImageUrl {
                                            ZStack {
                                                PlatformIndependentWebView(url: realizedImageUrl, isLoading: $isLoading, error: $error)
                                                    .cornerRadius(4)
                                                if isLoading {
                                                    ProgressView()
                                                        .scaleEffect(2)
                                                }
                                            }
                                        } else {
                                            Spacer()
                                            Text("Enter an image URL to search")
                                            Spacer()
                                        }
                                    }
                                )
                            ),
                            (
                                tabText: "HIVE Results",
                                tabIconName: "photo.badge.checkmark.fill",
                                tabIconColors: (.secondary, .accentColor),
                                view: AnyView(
                                    VStack {
                                        if !returnedJson.isEmpty {
                                            HStack {
                                                Spacer()
                                                Button(action: {
                                                    copyToClipboard(returnedJson)
                                                    toastManager.showCompletedToast("Copied to clipboard", "Copied the logging data to the clipboard")
                                                }) {
                                                    HStack(alignment: .center) {
                                                        Image(systemName: "pencil.and.list.clipboard")
                                                            .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                                                        Text("Copy result")
                                                    }
                                                }
                                                .focusable()
                                                .onKeyPress(.space) {
                                                    copyToClipboard(returnedJson)
                                                    toastManager.showCompletedToast("Copied to clipboard", "Copied the logging data to the clipboard")
                                                    return .handled
                                                }
                                            }
                                            ScrollView(.vertical) {
                                                HStack {
                                                    VStack(alignment: .leading) {
                                                        Text("Result from server: ")
                                                            .font(.system(size: 16))
                                                            .bold()
                                                            .padding([.top, .leading], 8)
                                                        Spacer().frame(height: 0) // fix bug with text being truncated
                                                        Text(returnedJson)
                                                            .lineLimit(...2048)
                                                            .padding(8)
                                                        Spacer().frame(height: 0) // fix bug with text being truncated
                                                    }
                                                    Spacer()
                                                }
                                            }
                                            .background(Color.BackgroundColorList)
                                            .cornerRadius(10)
                                        }

                                        if !errorFromServer.isEmpty {
                                            HStack {
                                                Text("Error: ")
                                                Text(errorFromServer)
                                            }
                                            .font(.system(size: 32))
                                            .foregroundStyle(.red, .secondary)
                                        }

                                        Spacer()
                                    }
                                )
                            )
                        ])
                    }

                    Spacer()
                        .frame(height: 8)

                    HStack {
                        Image(systemName: uploadToServer != nil ? "arrow.triangle.2.circlepath.icloud" : "icloud")
                            .foregroundColor(uploadToServer != nil ? .yellow : .green)
                            .symbolEffect(.pulse, options: uploadToServer != nil ? .repeating.speed(3) : .default, value: uploadToServer)
                            .symbolRenderingMode(uploadToServer != nil ? .hierarchical : .monochrome)
                        if let uploadToServer {
                            Text("Sending image to \(uploadToServer)...")
                        }
                        Spacer()
                    }
                    .font(.system(size: 16))
                }
                .padding([.leading, .top, .trailing])
                .foregroundStyle(Color.TextColorPrimary, Color.TextColorSecondary)
                .toolbar {
                    Button(action: {
                        hideImageValidationView()
                    }) {
                        HStack {
                            Image(systemName: "xmark")
                                .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                            Text("Close")
                                .font(.system(.body, design: .rounded).bold())
                                .foregroundStyle(Color.TextColorPrimary, Color.TextColorSecondary)
                            Text(languagePrefix == "en" ? "    ⌘ `" : "    ⌘ ⌥ x")
                                .font(.system(.body, design: .rounded))
                                .foregroundStyle(Color.gray, Color.TextColorSecondary)
                        }
                        .padding(4)
                    }
                    .disabled(toastManager.isShowingAnyToast || uploadToServer != nil)
                    .keyboardShortcut(languagePrefix == "en" ? "`" : "x", modifiers: languagePrefix == "en" ? .command : [.command, .option])
                }
                .allowsHitTesting(!toastManager.isShowingAnyToast)
            }
        }
        .frame(minWidth: 1280, minHeight: 800)
        .background(Color.BackgroundColor)
        .onAppear {
            openTinEyeResults()
            prepareHiveResults()
        }
    }

    private func openTinEyeResults() {
        let imageUrlToEncode = imageValidationImageUrl.wrappedValue
        if imageUrlToEncode != nil {
            let finalUrl = imageUrlToEncode!.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
            loadedImageUrl = URL(string: "https://www.tineye.com/search/?pluginver=chrome-2.0.4&sort=score&order=desc&url=\(finalUrl!)")
        }
    }

    private func prepareHiveResults() {
        toastManager.showProgressToast("Loading image AI data...")
        Task {
            aiVerdict = .indeterminate
            aiVerdictString = ""
            errorFromServer = ""
            returnedJson = ""
            sendToHiveServer()
        }
    }

    private func sendToHiveServer() {
        uploadToServer = "Hive"
        returnedJson = ""
        aiVerdict = .indeterminate
        aiVerdictString = ""
        errorFromServer = ""
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-M-d-HH-mm-ss"
        sendRequestToHive() { data, urlResponse, error in
            uploadToServer = nil
            if let errorResult = error {
                errorFromServer = "Error result: " + errorResult.localizedDescription
                debugPrint("Error result: " + errorResult.localizedDescription)
                toastManager.hideAnyToast()
            } else if let dataResult = data {
                do
                {
                    returnedJson = String(data: dataResult, encoding: .utf8) ?? ""
                    let decoder = JSONDecoder()
                    let results = try decoder.decode(HiveResponse.self, from: dataResult)
                    if results.status_code >= 200 && results.status_code <= 299 {
                        if let verdictClass = results.data.classes.first(where : { $0.class == "not_ai_generated" }) {
                            aiVerdictString = "\(verdictClass.score > 0.8 ? "Not AI" : verdictClass.score < 0.5 ? "AI" : "Indeterminate") (\(String(format: "%.1f", verdictClass.score * 100)) % not AI)"
                            aiVerdict = verdictClass.score > 0.8 ? .notAi : verdictClass.score < 0.5 ? .ai : .indeterminate
                        }
                    } else {
                        aiVerdictString = "unknown (non-success result)"
                        aiVerdict = .indeterminate
                    }
                    if let json = try? JSONSerialization.jsonObject(with: dataResult, options: .mutableContainers),
                       let jsonData = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]) {
                        returnedJson = String(decoding: jsonData, as: UTF8.self)
                    }
                } catch {
                    do
                    {
                        let decoder = JSONDecoder()
                        let results = try decoder.decode(ServerMessage.self, from: dataResult)
                        errorFromServer = results.message
                    } catch {
                        errorFromServer = "JSON decode error: " + error.localizedDescription
                        debugPrint("JSON decode error: " + error.localizedDescription)
                        debugPrint(String(decoding: dataResult, as: UTF8.self))
                    }
                }
                toastManager.hideAnyToast()
            }
        }
    }

    private func sendRequestToHive(
        completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void
    ) {
        aiVerdict = .indeterminate
        aiVerdictString = ""
        errorFromServer = ""
        let url = "https://plugin.hivemoderation.com/api/v1/image/ai_detection"
        var request = MultipartFormDataRequest(url: URL(string: url)!)
        request.addHeader(header: "Accept", value: "application/json")
        request.addDataField(fieldName: "url", fieldValue: imageValidationImageUrl.wrappedValue!.absoluteString)
        request.addDataField(fieldName: "request_id", fieldValue: UUID().uuidString)
        URLSession.shared.dataTask(with: request, completionHandler: completionHandler).resume()
    }

    private func navigateToTinEyeResult(_ selectedFeature: Binding<ObservableFeatureWrapper>, _ direction: Direction) {
        let (change, newValue) = navigateGeneric(TinEyeResults.allCases, selectedFeature.feature.tinEyeResults.wrappedValue, direction)
        if change {
            if direction != .same {
                selectedFeature.feature.tinEyeResults.wrappedValue = newValue
            }
            updateList()
            viewModel.markDocumentDirty()
        }
    }

    private func navigateToTinEyeResultWithArrows(_ selectedFeature: Binding<ObservableFeatureWrapper>, _ keyPress: KeyPress) -> KeyPress.Result {
        let direction = directionFromModifiers(keyPress)
        if direction != .same {
            navigateToTinEyeResult(selectedFeature, direction)
            return .handled
        }
        return .ignored
    }

    private func navigateToTinEyeResultWithPrefix(_ selectedFeature: Binding<ObservableFeatureWrapper>, _ keyPress: KeyPress) -> KeyPress.Result {
        let (change, newValue) = navigateGenericWithPrefix(TinEyeResults.allCases, selectedFeature.feature.tinEyeResults.wrappedValue, keyPress.characters.lowercased())
        if change {
            selectedFeature.feature.tinEyeResults.wrappedValue = newValue
            updateList()
            viewModel.markDocumentDirty()
            return .handled
        }
        return .ignored
    }

    private func navigateToAiCheckResult(_ selectedFeature: Binding<ObservableFeatureWrapper>, _ direction: Direction) {
        let (change, newValue) = navigateGeneric(AiCheckResults.allCases, selectedFeature.feature.aiCheckResults.wrappedValue, direction)
        if change {
            if direction != .same {
                selectedFeature.feature.aiCheckResults.wrappedValue = newValue
            }
            updateList()
            viewModel.markDocumentDirty()
        }
    }

    private func navigateToAiCheckResultWithArrows(_ selectedFeature: Binding<ObservableFeatureWrapper>, _ keyPress: KeyPress) -> KeyPress.Result {
        let direction = directionFromModifiers(keyPress)
        if direction != .same {
            navigateToAiCheckResult(selectedFeature, direction)
            return .handled
        }
        return .ignored
    }

    private func navigateToAiCheckResultWithPrefix(_ selectedFeature: Binding<ObservableFeatureWrapper>, _ keyPress: KeyPress) -> KeyPress.Result {
        let (change, newValue) = navigateGenericWithPrefix(AiCheckResults.allCases, selectedFeature.feature.aiCheckResults.wrappedValue, keyPress.characters.lowercased())
        if change {
            selectedFeature.feature.aiCheckResults.wrappedValue = newValue
            updateList()
            viewModel.markDocumentDirty()
            return .handled
        }
        return .ignored
    }
}

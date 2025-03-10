//
//  ImageValidationView.swift
//  Feature Logging
//
//  Created by Andrew Forget on 2024-03-11.
//

import SwiftUI
import SwiftyBeaver
import UniformTypeIdentifiers

enum AiVerdict {
    case notAi
    case ai
    case indeterminate
}

struct ImageValidationView: View {
    @Environment(\.openURL) private var openURL

    private var viewModel: ContentView.ViewModel
    private var updateList: () -> Void

    @State private var aiVerdictString = ""
    @State private var aiVerdict = AiVerdict.indeterminate
    @State private var returnedJson = ""
    @State private var errorFromServer = ""
    @State private var uploadToServer: String? = nil
    @State private var loadedImageUrl: URL?
    @State private var isLoading = false
    @State private var error: Error?
    @State private var storedCookies: [HTTPCookie] = []

    private let languagePrefix = Locale.preferredLanguageCode
    private let logger = SwiftyBeaver.self

    init(
        _ viewModel: ContentView.ViewModel,
        _ updateList: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.updateList = updateList
    }

    var body: some View {
        ZStack {
            Color.backgroundColor.edgesIgnoringSafeArea(.all)

            if viewModel.selectedFeature != nil {
                let selectedFeature = Binding<ObservableFeatureWrapper>(
                    get: { viewModel.selectedFeature! },
                    set: { viewModel.selectedFeature = $0 }
                )

                VStack(alignment: .leading) {
                    VStack(alignment: .leading) {
                        ValidationSummaryView(selectedFeature)

                        CustomTabView(tabBarPosition: .top, content: [
                            (
                                tabText: "TinEye Results",
                                tabIconName: "globe",
                                tabIconColors: (.accentColor, .secondary),
                                view: AnyView(TinEyeResultsView())
                            ),
                            (
                                tabText: "HIVE Results",
                                tabIconName: "photo.badge.checkmark.fill",
                                tabIconColors: (.secondary, .accentColor),
                                view: AnyView(HiveAiResultsView())
                            ),
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
                .foregroundStyle(Color(UIColor.label), Color(UIColor.secondaryLabel))
                .toolbar {
                    ToolbarItemGroup(placement: .bottomBar) {
                        Spacer()

                        Button(action: {
                            viewModel.visibleView = .PostDownloadView
                        }) {
                            HStack {
                                Image(systemName: "xmark.circle")
                                    .foregroundStyle(Color.accentColor, Color(UIColor.secondaryLabel))
                                Text("Close")
                            }
                            .padding(4)
                        }
                        .disabled(viewModel.hasModalToasts || uploadToServer != nil)

                        Button(action: {
                            viewModel.visibleView = .FeatureListView
                        }) {
                            HStack {
                                Image(systemName: "house.circle")
                                    .foregroundStyle(Color.accentColor, Color(UIColor.secondaryLabel))
                                Text("Home")
                            }
                            .padding(4)
                        }
                        .disabled(viewModel.hasModalToasts || uploadToServer != nil)

                        Button(action: {
                            logger.verbose("Tapped remove feature button", context: "System")
                            if let currentFeature = viewModel.selectedFeature {
                                viewModel.selectedFeature = nil
                                viewModel.features.removeAll(where: { $0.id == currentFeature.feature.id })
                                viewModel.markDocumentDirty()
                                viewModel.visibleView = .FeatureListView
                            }
                        }) {
                            HStack(alignment: .center) {
                                Image(systemName: "person.fill.badge.minus")
                                    .foregroundStyle(Color.red, Color(UIColor.secondaryLabel))
                                Text("Remove feature")
                            }
                        }
                        .disabled(viewModel.hasModalToasts || viewModel.selectedFeature == nil)

                        Spacer()
                    }
                }
                .safeToolbarVisibility(.visible, for: .bottomBar)
            }
        }
        .background(Color.backgroundColor)
        .onAppear {
            openTinEyeResults()
            prepareHiveResults()
        }
    }

    private func ValidationSummaryView(_ selectedFeature: Binding<ObservableFeatureWrapper>) -> some View {
        VStack {
            HStack(alignment: .center) {
                Spacer()
                    .frame(width: 0, height: 26)
                Text("TinEye:")
                Picker(
                    "",
                    selection: selectedFeature.feature.tinEyeResults.onChange { _ in
                        updateList()
                        viewModel.markDocumentDirty()
                    }
                ) {
                    ForEach(TinEyeResults.allCases) { source in
                        Text(source.rawValue)
                            .tag(source)
                            .foregroundStyle(Color(UIColor.secondaryLabel), Color(UIColor.secondaryLabel))
                    }
                }
                .tint(Color.accentColor)
                .accentColor(Color.accentColor)
                .foregroundStyle(Color.accentColor, Color(UIColor.label))
                .frame(width: 160)

                Text("|")
                    .padding([.leading, .trailing])

                Text("AI Check:")
                Picker(
                    "",
                    selection: selectedFeature.feature.aiCheckResults.onChange { _ in
                        updateList()
                        viewModel.markDocumentDirty()
                    }
                ) {
                    ForEach(AiCheckResults.allCases) { source in
                        Text(source.rawValue)
                            .tag(source)
                            .foregroundStyle(Color(UIColor.secondaryLabel), Color(UIColor.secondaryLabel))
                    }
                }
                .tint(Color.accentColor)
                .accentColor(Color.accentColor)
                .foregroundStyle(Color.accentColor, Color(UIColor.label))
                .frame(width: 160)
                Spacer()
            }

            HStack {
                if !aiVerdictString.isEmpty {
                    Text("HIVE verdict: ")
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Text(aiVerdictString)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Image(systemName: aiVerdict == .notAi ? "checkmark.shield" : aiVerdict == .ai ? "exclamationmark.warninglight" : "questionmark.diamond")
                } else {
                    Text("HIVE verdict loading ")
                }
                Spacer()
            }
            .font(.system(size: 24))
            .foregroundStyle(aiVerdictString.isEmpty ? .gray : aiVerdict == .notAi ? .green : aiVerdict == .ai ? .red : .yellow, .secondary)
        }
    }

    private func TinEyeResultsView() -> some View {
        VStack {
            if let realizedImageUrl = loadedImageUrl {
                ZStack {
                    VStack(alignment: .leading) {
                        Button(action: {
                            logger.info("Tapped open TinEye in browser", context: "System")
                            openURL(realizedImageUrl)
                        }) {
                            HStack(alignment: .center) {
                                Image(systemName: "arrow.up.right.bottomleft.rectangle")
                                    .foregroundStyle(Color.accentColor, .secondary)
                                    .font(.system(size: 28, weight: .semibold))
                                Text("Open in browser")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .padding(4)
                        }
                        .padding(.vertical, 4)
                        PlatformIndependentWebView(
                            url: realizedImageUrl,
                            storedCookies: $storedCookies,
                            isLoading: $isLoading,
                            error: $error
                        )
                        .cornerRadius(4)
                    }
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
    }

    private func HiveAiResultsView() -> some View {
        VStack {
            if !returnedJson.isEmpty {
                HStack {
                    Spacer()
                    Button(action: {
                        copyToClipboard(returnedJson)
                        viewModel.showSuccessToast("Copied to clipboard", "Copied the logging data to the clipboard")
                    }) {
                        HStack(alignment: .center) {
                            Image(systemName: "pencil.and.list.clipboard")
                                .foregroundStyle(Color.accentColor, Color(UIColor.secondaryLabel))
                            Text("Copy result")
                        }
                    }
                    .buttonStyle(.bordered)
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
                .background(Color.secondaryBackgroundColor)
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
    }

    private func openTinEyeResults() {
        logger.verbose("Opening the TinEye browser URL", context: "System")
        let imageUrlToEncode = viewModel.imageValidationImageUrl
        if imageUrlToEncode != nil {
            let finalUrl = imageUrlToEncode!.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
            loadedImageUrl = URL(string: "https://www.tineye.com/search/?pluginver=chrome-2.0.4&sort=score&order=desc&url=\(finalUrl!)")
        }
    }

    private func prepareHiveResults() {
        logger.verbose("Loading results from HIVE", context: "System")
        viewModel.showToast(.progress, "Loading", "Loading image AI data from HIVE...")
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
        sendRequestToHive { data, _, error in
            uploadToServer = nil
            if let errorResult = error {
                errorFromServer = "Error result: " + errorResult.localizedDescription
                logger.error("Error result from HIVE: \(errorResult.localizedDescription)", context: "System")
                debugPrint("Error result: " + errorResult.localizedDescription)
                viewModel.dismissAllNonBlockingToasts(includeProgress: true)
            } else if let dataResult = data {
                logger.verbose("Received result from HIVE", context: "System")
                do {
                    returnedJson = String(data: dataResult, encoding: .utf8) ?? ""
                    let decoder = JSONDecoder()
                    let results = try decoder.decode(HiveResponse.self, from: dataResult)
                    if results.status_code >= 200 && results.status_code <= 299 {
                        if let verdictClass = results.data.classes.first(where: { $0.class == "not_ai_generated" }) {
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
                    logger.verbose("Parsed result from HIVE", context: "System")
                } catch {
                    logger.error("Error parsing results from HIVE: \(error.localizedDescription)", context: "System")
                    do {
                        let decoder = JSONDecoder()
                        let results = try decoder.decode(ServerMessage.self, from: dataResult)
                        errorFromServer = results.message
                        logger.error("Error from HIVE: \(errorFromServer)", context: "System")
                    } catch {
                        logger.error("JSON decode error decoding HIVE response: \(error.localizedDescription)", context: "System")
                        errorFromServer = "JSON decode error: " + error.localizedDescription
                        debugPrint("JSON decode error: " + error.localizedDescription)
                        debugPrint(String(decoding: dataResult, as: UTF8.self))
                    }
                }
                viewModel.dismissAllNonBlockingToasts(includeProgress: true)
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
        request.addDataField(fieldName: "url", fieldValue: viewModel.imageValidationImageUrl!.absoluteString)
        request.addDataField(fieldName: "request_id", fieldValue: UUID().uuidString)
        URLSession.shared.dataTask(with: request, completionHandler: completionHandler).resume()
    }
}

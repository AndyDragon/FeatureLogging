//
//  ImageValidationView.swift
//  Feature Logging
//
//  Created by Andrew Forget on 2024-03-11.
//

import SwiftUI
import UniformTypeIdentifiers
import AlertToast

enum AiVerdict {
    case notAi
    case ai
    case indeterminate
}

struct ImageValidationView: View {
    @Environment(\.openURL) private var openURL

    @State private var viewModel: ContentView.ViewModel
    @State private var focusedField: FocusState<FocusField?>.Binding
    @State private var isShowingToast: Binding<Bool>
    @State private var isShowingProgressToast: Binding<Bool>
    @State private var imageValidationImageData: Binding<Data?>
    @State private var imageValidationImageUrl: Binding<URL?>
    private var hideImageValidationView: () -> Void
    private var updateList: () -> Void
    private var markDocumentDirty: () -> Void
    private var showToast: (_ type: AlertToast.AlertType, _ text: String, _ subTitle: String, _ duration: ToastDuration, _ onTap: @escaping () -> Void) -> Void
    private var toggleProgressToast: () -> Void

    @State private var image: NSImage?
    @State private var size = NSSize()
    @State private var dataSize = 0
    @State private var aiVerdictString = ""
    @State private var aiVerdict = AiVerdict.indeterminate
    @State private var returnedJson = ""
    @State private var errorFromServer = ""
    @State private var uploadToServer: String? = nil
    
    private let languagePrefix = Locale.preferredLanguageCode

    init(
        _ viewModel: ContentView.ViewModel,
        _ focusedField: FocusState<FocusField?>.Binding,
        _ isShowingToast: Binding<Bool>,
        _ isShowingProgressToast: Binding<Bool>,
        _ imageValidationImageData: Binding<Data?>,
        _ imageValidationImageUrl: Binding<URL?>,
        _ hideImageValidationView: @escaping () -> Void,
        _ updateList: @escaping () -> Void,
        _ markDocumentDirty: @escaping () -> Void,
        _ showToast: @escaping (_ type: AlertToast.AlertType, _ text: String, _ subTitle: String, _ duration: ToastDuration, _ onTap: @escaping () -> Void) -> Void,
        _ toggleProgressToast: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.focusedField = focusedField
        self.isShowingToast = isShowingToast
        self.isShowingProgressToast = isShowingProgressToast
        self.imageValidationImageData = imageValidationImageData
        self.imageValidationImageUrl = imageValidationImageUrl
        self.hideImageValidationView = hideImageValidationView
        self.updateList = updateList
        self.markDocumentDirty = markDocumentDirty
        self.showToast = showToast
        self.toggleProgressToast = toggleProgressToast
    }
    
    var body: some View {
        ZStack {
            Color.BackgroundColor.edgesIgnoringSafeArea(.all)
            
            if viewModel.selectedFeature != nil {
                let selectedFeature = Binding<SharedFeature>(
                    get: { viewModel.selectedFeature! },
                    set: { viewModel.selectedFeature = $0 }
                )
                
                VStack(alignment: .leading) {
                    HStack {
                        if let image = self.image {
                            VStack(alignment: .center) {
                                Spacer()
                                    .frame(height: 8)
                                Text("Image size: \(Int(size.width)) x \(Int(size.height)) | \(String(format: "%.2f", Double(dataSize) / (1024.0 * 1024.0))) MB | png")
                                    .padding([.bottom], 4)
                                Image(nsImage: image)
                                    .antialiased(true)
                                    .interpolation(.high)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 480)
                                    .frame(maxWidth: .infinity)
                                    .padding(8)
                                    .background(Color(nsColor: .controlBackgroundColor))
                                    .cornerRadius(4)
                            }
                            .frame(maxWidth: .infinity)
                            .background(Color.BackgroundColorList)
                            .cornerRadius(10)
                        }
                    }

                    Spacer()
                        .frame(height: 8)

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
                                let direction = directionFromModifiers(keyPress)
                                if direction != .same {
                                    navigateToTinEyeResult(selectedFeature, direction)
                                    return .handled
                                }
                                return .ignored
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
                                let direction = directionFromModifiers(keyPress)
                                if direction != .same {
                                    navigateToAiCheckResult(selectedFeature, direction)
                                    return .handled
                                }
                                return .ignored
                            }
                            
                            if !aiVerdictString.isEmpty {
                                Text("|")
                                    .padding([.leading, .trailing])
                                
                                HStack {
                                    Text("Verdict: ")
                                    Text(aiVerdictString)
                                    Image(systemName: aiVerdict == .notAi ? "checkmark.shield" : aiVerdict == .ai ? "exclamationmark.warninglight" : "questionmark.diamond")
                                }
                                .font(.system(size: 24))
                                .foregroundStyle(aiVerdict == .notAi ? .green : aiVerdict == .ai ? .red : .yellow, .secondary)
                            }
                            
                            Spacer()
                        }
                        
                        if !returnedJson.isEmpty {
                            HStack {
                                Spacer()
                                Button(action: {
                                    copyToClipboard(returnedJson)
                                    showToast(.complete(.green), "Copied to clipboard", "Copied the logging data to the clipboard", .Success) {}
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
                                    showToast(.complete(.green), "Copied to clipboard", "Copied the logging data to the clipboard", .Success) {}
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
                        openInTinEye()
                    }, label: {
                        HStack {
                            Image(systemName: "link")
                                .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                            Text("Open in Tin Eye")
                                .font(.system(.body, design: .rounded).bold())
                                .foregroundStyle(Color.TextColorPrimary, Color.TextColorSecondary)
                            Text("    ⌘ T")
                                .font(.system(.body, design: .rounded))
                                .foregroundStyle(Color.gray, Color.TextColorSecondary)
                        }
                        .padding(4)
                    })
                    .disabled(image == nil)
                    .keyboardShortcut("T", modifiers: .command)
                    
                    Spacer()
                        .frame(width: 16)
                    
                    Button(action: {
                        sendToHiveServer()
                    }, label: {
                        HStack {
                            Image(systemName: "icloud.and.arrow.up")
                                .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                            Text("Send to Hive")
                                .font(.system(.body, design: .rounded).bold())
                                .foregroundStyle(Color.TextColorPrimary, Color.TextColorSecondary)
                            Text("    ⌘ ↑")
                                .font(.system(.body, design: .rounded))
                                .foregroundStyle(Color.gray, Color.TextColorSecondary)
                        }
                        .padding(4)
                    })
                    .disabled(uploadToServer != nil || image == nil)
                    .keyboardShortcut(.upArrow, modifiers: .command)
                    
                    Spacer()
                        .frame(width: 16)
                    
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
                    .disabled(isShowingToast.wrappedValue || isShowingProgressToast.wrappedValue || uploadToServer != nil)
                    .keyboardShortcut(languagePrefix == "en" ? "`" : "x", modifiers: languagePrefix == "en" ? .command : [.command, .option])
                }
                .allowsHitTesting(!isShowingToast.wrappedValue && !isShowingProgressToast.wrappedValue)
            }
        }
        .frame(minWidth: 1280, minHeight: 800)
        .background(Color.BackgroundColor)
        .onAppear {
            loadImage()
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
        uploadFileToHive() { data, urlResponse, error in
            uploadToServer = nil
            if let errorResult = error {
                errorFromServer = "Error result: " + errorResult.localizedDescription
                debugPrint("Error result: " + errorResult.localizedDescription)
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
            }
        }
    }
    
    private func openInTinEye() {
        if let imageUrl = imageValidationImageUrl.wrappedValue {
            let finalUrl = imageUrl.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
            if let url = URL(string: "https://www.tineye.com/search/?pluginver=chrome-2.0.4&sort=score&order=desc&url=\(finalUrl!)") {
                openURL(url)
            }
        } else {
            if let url = URL(string: "https://www.tineye.com") {
                openURL(url)
            }
        }
    }

    private func loadImage() {
        toggleProgressToast()
        Task {
            if let imageData = imageValidationImageData.wrappedValue {
                aiVerdict = .indeterminate
                aiVerdictString = ""
                errorFromServer = ""
                returnedJson = ""
                if let loadedImage = NSImage(data: imageData) {
                    image = loadedImage
                    size = image!.size
                    dataSize = imageData.count
                }
            }
            toggleProgressToast()
            if image != nil {
                sendToHiveServer()
            }
        }
    }
    
    private func uploadFileToHive(
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

    private func navigateToTinEyeResult(_ selectedFeature: Binding<SharedFeature>, _ direction: Direction) {
        let result = navigateGeneric(TinEyeResults.allCases, selectedFeature.feature.tinEyeResults.wrappedValue, direction)
        if result.0 {
            if direction != .same {
                selectedFeature.feature.tinEyeResults.wrappedValue = result.1
            }
            updateList()
            markDocumentDirty()
        }
    }
    
    private func navigateToAiCheckResult(_ selectedFeature: Binding<SharedFeature>, _ direction: Direction) {
        let result = navigateGeneric(AiCheckResults.allCases, selectedFeature.feature.aiCheckResults.wrappedValue, direction)
        if result.0 {
            if direction != .same {
                selectedFeature.feature.aiCheckResults.wrappedValue = result.1
            }
            updateList()
            markDocumentDirty()
        }
    }
}

struct MultipartFormDataRequest {
    private let boundary: String = UUID().uuidString
    var httpBody = NSMutableData()
    var headers = [String:String]()
    let url: URL
    
    init(url: URL) {
        self.url = url
    }
    
    func addTextField(named name: String, value: String) {
        httpBody.appendString(textFormField(named: name, value: value))
    }
    
    private func textFormField(named name: String, value: String) -> String {
        var fieldString = "--\(boundary)\r\n"
        fieldString += "Content-Disposition: form-data; name=\"\(name)\"\r\n"
        fieldString += "Content-Type: text/plain; charset=ISO-8859-1\r\n"
        fieldString += "Content-Transfer-Encoding: 8bit\r\n"
        fieldString += "\r\n"
        fieldString += "\(value)\r\n"
        
        return fieldString
    }
    
    func addDataField(fieldName: String, fieldValue: String) {
        httpBody.append(dataFormField(fieldName: fieldName, fieldValue: fieldValue))
    }

    private func dataFormField(fieldName: String, fieldValue: String) -> Data {
        let fieldData = NSMutableData()
        fieldData.appendString("--\(boundary)\r\n")
        fieldData.appendString("Content-Disposition: form-data; name=\"\(fieldName)\"\r\n")
        fieldData.appendString("\r\n")
        fieldData.appendString(fieldValue)
        fieldData.appendString("\r\n")
        return fieldData as Data
    }
    
    mutating func addHeader(header: String, value: String) {
        headers[header] = value
    }
    
    func asURLRequest() -> URLRequest {
        var request = URLRequest(url: url)
        for header in headers {
            request.addValue(header.value, forHTTPHeaderField: header.key)
        }
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        httpBody.appendString("--\(boundary)--")
        request.httpBody = httpBody as Data
        return request
    }
}

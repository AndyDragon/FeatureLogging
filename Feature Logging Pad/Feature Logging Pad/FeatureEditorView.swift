//
//  FeatureEditorView.swift
//  Feature Logging Pad
//
//  Created by Andrew Forget on 2025-01-16.
//

import SwiftUI
import SwiftyBeaver
import UniformTypeIdentifiers

struct FeatureEditorView: View {
    // THEME
    @AppStorage(
        Constants.THEME_APP_STORE_KEY,
        store: UserDefaults(suiteName: "com.andydragon.com.Feature-Logging")
    ) var theme = Theme.notSet
    @Environment(\.colorScheme) private var colorScheme: ColorScheme
    @State private var isDarkModeOn = true

    // PREFS
    @AppStorage(
        "preference_personalMessage",
        store: UserDefaults(suiteName: "com.andydragon.com.Feature-Logging")
    ) var personalMessageFormat = "🎉💫 Congratulations on your @%%PAGENAME%% feature %%USERNAME%% @%%USERALIAS%%! %%PERSONALMESSAGE%% 💫🎉"
    @AppStorage(
        "preference_personalMessageFirst",
        store: UserDefaults(suiteName: "com.andydragon.com.Feature-Logging")
    ) var personalMessageFirstFormat = "🎉💫 Congratulations on your first @%%PAGENAME%% feature %%USERNAME%% @%%USERALIAS%%! %%PERSONALMESSAGE%% 💫🎉"
    @AppStorage(
        "preference_includehash",
        store: UserDefaults(suiteName: "com.andydragon.com.Feature-Logging")
    ) var includeHash = false

    @Bindable private var viewModel: ContentView.ViewModel
    @State private var logURL: Binding<URL?>
    @State private var logDocument: Binding<LogDocument>
    @State private var showFileImporter: Binding<Bool>
    @State private var showFileExporter: Binding<Bool>
    @State private var reportDocument: Binding<ReportDocument>
    @State private var showReportFileExporter: Binding<Bool>
    @State private var documentDirtyAlertConfirmation: Binding<String>
    @State private var documentDirtyAfterSaveAction: Binding<() -> Void>
    @State private var documentDirtyAfterDismissAction: Binding<() -> Void>
    @State private var shouldScrollFeatureListToSelection: Binding<Bool>
    @State private var yourNameValidation: (valid: Bool, reason: String?) = (true, nil)
    @State private var yourFirstNameValidation: (valid: Bool, reason: String?) = (true, nil)
    private var showScriptView: () -> Void
    private var showDownloaderView: () -> Void
    private var updateStaffLevelForPage: () -> Void
    private var storeStaffLevelForPage: () -> Void
    private var saveLog: (_ file: URL) -> Void
    private var setTheme: (_ newTheme: Theme) -> Void
    private var logger = SwiftyBeaver.self

    init(
        _ viewModel: ContentView.ViewModel,
        _ logURL: Binding<URL?>,
        _ logDocument: Binding<LogDocument>,
        _ showFileImporter: Binding<Bool>,
        _ showFileExporter: Binding<Bool>,
        _ reportDocument: Binding<ReportDocument>,
        _ showReportFileExporter: Binding<Bool>,
        _ documentDirtyAlertConfirmation: Binding<String>,
        _ documentDirtyAfterSaveAction: Binding<() -> Void>,
        _ documentDirtyAfterDismissAction: Binding<() -> Void>,
        _ shouldScrollFeatureListToSelection: Binding<Bool>,
        _ showScriptView: @escaping () -> Void,
        _ showDownloaderView: @escaping () -> Void,
        _ updateStaffLevelForPage: @escaping () -> Void,
        _ storeStaffLevelForPage: @escaping () -> Void,
        _ saveLog: @escaping (_ file: URL) -> Void,
        _ setTheme: @escaping (_ newTheme: Theme) -> Void
    ) {
        self.viewModel = viewModel
        self.logURL = logURL
        self.logDocument = logDocument
        self.showFileImporter = showFileImporter
        self.showFileExporter = showFileExporter
        self.reportDocument = reportDocument
        self.showReportFileExporter = showReportFileExporter
        self.documentDirtyAlertConfirmation = documentDirtyAlertConfirmation
        self.documentDirtyAfterSaveAction = documentDirtyAfterSaveAction
        self.documentDirtyAfterDismissAction = documentDirtyAfterDismissAction
        self.shouldScrollFeatureListToSelection = shouldScrollFeatureListToSelection
        self.showScriptView = showScriptView
        self.showDownloaderView = showDownloaderView
        self.updateStaffLevelForPage = updateStaffLevelForPage
        self.storeStaffLevelForPage = storeStaffLevelForPage
        self.saveLog = saveLog
        self.setTheme = setTheme
    }

    private let languagePrefix = Locale.preferredLanguageCode
    private let labelWidth: CGFloat = 80

    var body: some View {
        ZStack {
            Color.BackgroundColor.edgesIgnoringSafeArea(.all)

            VStack {
                // Feature editor
                VStack {
                    if let selectedPage = viewModel.selectedPage, let selectedFeature = viewModel.selectedFeature {
                        FeatureEditor(
                            viewModel,
                            selectedPage,
                            selectedFeature,
                            {
                                viewModel.selectedFeature = nil
                                viewModel.visibleView = .FeatureListView
                            },
                            { viewModel.markDocumentDirty() },
                            { shouldScrollFeatureListToSelection.wrappedValue.toggle() },
                            showDownloaderView
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding([.bottom], 4)
            }
            .padding([.leading, .top, .trailing])
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    Spacer()

                    Button(action: {
                        viewModel.selectedFeature = nil
                        viewModel.visibleView = .FeatureListView
                    }) {
                        HStack {
                            Image(systemName: "xmark")
                                .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                            Text("Close")
                        }
                        .padding(4)
                    }
                    .disabled(viewModel.hasModalToasts)

                    Spacer()

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
                                .foregroundStyle(Color.TextColorRequired, Color.TextColorSecondary)
                            Text("Remove feature")
                        }
                    }
                    .disabled(viewModel.selectedFeature == nil)
                }
            }
            .toolbarVisibility(.visible, for: .bottomBar)
        }
        .onAppear(perform: {
            setTheme(theme)
        })
        .preferredColorScheme(isDarkModeOn ? .dark : .light)
        .testBackground()
    }

    private func setThemeLocal(_ newTheme: Theme) {
        if newTheme == .notSet {
            isDarkModeOn = colorScheme != .dark
            isDarkModeOn = colorScheme == .dark
        } else {
            if let details = ThemeDetails[newTheme] {
                isDarkModeOn = !details.darkTheme
                isDarkModeOn = details.darkTheme
                theme = newTheme
            }
        }
    }
}

//
//  ContentView.swift
//  Feature Logging
//
//  Created by Andrew Forget on 2024-07-12.
//

import SwiftUI
import SwiftUICharts
import SwiftyBeaver

struct LogFile {
    var fileName: String
    var log: Log
}

struct StatisticsContentView: View {
    @Environment(\.self) var environment

    private var viewModel: ContentView.ViewModel
    @State private var focusedField: FocusState<FocusField?>.Binding
    private var hideStatisticsView: () -> Void

    @State private var showDirectoryPicker = false
    @State private var location = ""
    @State private var logs = [LogFile]()
    @State private var pages = [String]()
    @State private var selectedPage = ""

    @State private var pickedFeaturePieChart: PieChartData? = nil
    @State private var firstFeaturePieChart: PieChartData? = nil
    @State private var photoFeaturedPieChart: PieChartData? = nil
    @State private var userLevelPieChart: PieChartData? = nil
    @State private var pageFeatureCountPieChart: PieChartData? = nil
    @State private var hubFeatureCountPieChart: PieChartData? = nil

    private let languagePrefix = Locale.preferredLanguageCode
    private let logger = SwiftyBeaver.self

    init(
        _ viewModel: ContentView.ViewModel,
        _ focusedField: FocusState<FocusField?>.Binding,
        _ hideStatisticsView: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.focusedField = focusedField
        self.hideStatisticsView = hideStatisticsView
    }

    var body: some View {
        ZStack {
            Color.backgroundColor.edgesIgnoringSafeArea(.all)

            VStack {
                HStack {
                    Button(action: {
                        showDirectoryPicker.toggle()
                    }) {
                        HStack {
                            Image(systemName: "folder")
                                .foregroundStyle(Color.accentColor, Color.secondaryLabel)
                            Text("Open folder containing your log files...")
                        }
                        .foregroundStyle(Color.label, Color.secondaryLabel)
                    }
                    .focusable()
                    .focused(focusedField, equals: .openFolder)
                    .onKeyPress(.space) {
                        showDirectoryPicker.toggle()
                        return .handled
                    }
                    .fileImporter(
                        isPresented: $showDirectoryPicker, allowedContentTypes: [.folder],
                        onCompletion: { result in
                            switch result {
                            case let .success(folder):
                                selectedPage = ""
                                pickedFeaturePieChart = nil
                                firstFeaturePieChart = nil
                                userLevelPieChart = nil
                                photoFeaturedPieChart = nil
                                pageFeatureCountPieChart = nil
                                hubFeatureCountPieChart = nil
                                logs = [LogFile]()
                                location = folder.path().trimmingCharacters(in: ["/"])
                                let fileManager = FileManager.default
                                let gotAccess = folder.startAccessingSecurityScopedResource()
                                if !gotAccess { return }
                                do {
                                    let items = try fileManager.contentsOfDirectory(at: folder, includingPropertiesForKeys: [.isDirectoryKey]).filter({ item in
                                        item.isFileURL && item.pathExtension == "json"
                                    })
                                    for item in items {
                                        do {
                                            let data = try Data(contentsOf: item)
                                            let log = try JSONDecoder().decode(Log.self, from: data)
                                            logs.append(LogFile(fileName: item.path(), log: log))
                                        } catch {
                                            debugPrint(error.localizedDescription)
                                        }
                                    }
                                    var pageSet = Set(logs.map { $0.log.page })
                                    pageSet.formUnion(Set(logs.map { log in log.log.page.components(separatedBy: [":"]).first ?? "" }.filter { hub in hub != "" }))
                                    pages = Array(pageSet).sorted()
                                    pages.insert("all", at: 0)
                                    selectedPage = pages.first!
                                    navigateToStatsPage(.same)
                                    logger.verbose("Loaded \(pages.count) pages for stats", context: "System")
                                } catch {
                                    logger.error("Failed to load pages for stats: \(error.localizedDescription)", context: "System")
                                    debugPrint(error.localizedDescription)
                                }
                                folder.stopAccessingSecurityScopedResource()
                            case let .failure(error):
                                logger.error("Failed to pick folder for stats: \(error.localizedDescription)", context: "System")
                                debugPrint(error)
                            }
                        })
                    if logs.isEmpty {
                        Text("No logs loaded")
                    } else if selectedPage == "" {
                        Text("\(logs.count) logs loaded from \(location), select a page to see statistics")
                    } else {
                        Text("\(logs.count) logs loaded from \(location), showing statistics for page \(selectedPage)")
                    }
                    Spacer()
                }
                if !logs.isEmpty {
                    HStack(alignment: .center) {
                        Text("Choose a page:")
                        Picker(
                            "",
                            selection: $selectedPage.onChange({ _ in
                                navigateToStatsPage(.same)
                            })
                        ) {
                            ForEach(pages, id: \.self) { page in
                                if page == "all" {
                                    Text("all pages")
                                } else if !page.contains(":") {
                                    Text("\(page) hub")
                                } else {
                                    Text(page.replacingOccurrences(of: ":", with: " hub, page "))
                                }
                            }
                        }
                        .focusable()
                        .focused(focusedField, equals: .statsPagePicker)
                        .tint(Color.accentColor)
                        .accentColor(Color.accentColor)
                        .foregroundStyle(Color.accentColor, Color.label)
                        .onKeyPress(phases: .down) { keyPress in
                            navigateToStatsPageWithArrows(keyPress)
                        }
                        .onKeyPress(characters: .alphanumerics) { keyPress in
                            navigateToStatsPageWithPrefix(keyPress)
                        }
                    }
                }
                if let pickedFeaturePieChart,
                   let firstFeaturePieChart,
                   let userLevelPieChart,
                   let photoFeaturedPieChart,
                   let pageFeatureCountPieChart,
                   let hubFeatureCountPieChart {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8).fill(Color(red: 0.1, green: 0.1, blue: 0.16))

                        Grid {
                            GridRow {
                                PieChart(chartData: pickedFeaturePieChart)
                                    .id(pickedFeaturePieChart.id)
                                    .touchOverlay(chartData: pickedFeaturePieChart)
                                    .headerBox(chartData: pickedFeaturePieChart)
                                    .legends(chartData: pickedFeaturePieChart)
                                    .padding()

                                PieChart(chartData: firstFeaturePieChart)
                                    .id(firstFeaturePieChart.id)
                                    .touchOverlay(chartData: firstFeaturePieChart)
                                    .headerBox(chartData: firstFeaturePieChart)
                                    .legends(chartData: firstFeaturePieChart)
                                    .padding()

                                PieChart(chartData: photoFeaturedPieChart)
                                    .id(photoFeaturedPieChart.id)
                                    .touchOverlay(chartData: photoFeaturedPieChart)
                                    .headerBox(chartData: photoFeaturedPieChart)
                                    .legends(chartData: photoFeaturedPieChart)
                                    .padding()
                            }

                            Divider()

                            GridRow {
                                PieChart(chartData: userLevelPieChart)
                                    .id(userLevelPieChart.id)
                                    .touchOverlay(chartData: userLevelPieChart)
                                    .headerBox(chartData: userLevelPieChart)
                                    .legends(chartData: userLevelPieChart, columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())])
                                    .padding()

                                PieChart(chartData: pageFeatureCountPieChart)
                                    .id(pageFeatureCountPieChart.id)
                                    .touchOverlay(chartData: pageFeatureCountPieChart)
                                    .headerBox(chartData: pageFeatureCountPieChart)
                                    .legends(chartData: pageFeatureCountPieChart, columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())])
                                    .padding()

                                PieChart(chartData: hubFeatureCountPieChart)
                                    .id(hubFeatureCountPieChart.id)
                                    .touchOverlay(chartData: hubFeatureCountPieChart)
                                    .headerBox(chartData: hubFeatureCountPieChart)
                                    .legends(chartData: hubFeatureCountPieChart, columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())])
                                    .padding()
                            }
                        }
                        .padding()
                    }
                } else {
                    Spacer()
                }
            }
            .padding()
            .toolbar {
                Button(action: {
                    hideStatisticsView()
                }) {
                    HStack {
                        Image(systemName: "xmark")
                            .foregroundStyle(Color.accentColor, Color.secondaryLabel)
                        Text("Close")
                            .font(.system(.body, design: .rounded).bold())
                            .foregroundStyle(Color.label, Color.secondaryLabel)
                        Text(languagePrefix == "en" ? "    ⌘ `" : "    ⌘ ⌥ x")
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(Color.gray, Color.secondaryLabel)
                    }
                    .padding(4)
                }
                .keyboardShortcut(languagePrefix == "en" ? "`" : "x", modifiers: languagePrefix == "en" ? .command : [.command, .option])
                .disabled(viewModel.hasModalToasts)
            }
        }
        .frame(minWidth: 1024, minHeight: 600)
        .background(Color.backgroundColor)
        .onAppear(perform: {
            focusedField.wrappedValue = .openFolder
        })
    }

    private func updateCharts() {
        let pageLogs = logs.filter({ log in
            if selectedPage == "all" {
                return true
            }
            if !selectedPage.contains(":") {
                return log.log.page.starts(with: selectedPage)
            }
            return log.log.page == selectedPage
        })

        pickedFeaturePieChart = makePickedFeatureChartData(pageLogs)
        firstFeaturePieChart = makeFirstFeatureChartData(pageLogs)
        photoFeaturedPieChart = makePhotoFeaturedChartData(pageLogs)
        userLevelPieChart = makeUserLevelChartData(pageLogs)
        pageFeatureCountPieChart = makePageFeatureCountChartData(pageLogs)
        hubFeatureCountPieChart = makeHubFeatureCountChartData(pageLogs)
    }

    // MARK: - stats page navigation

    private func navigateToStatsPage(_ direction: Direction) {
        let (change, newValue) = navigateGeneric(pages, selectedPage, direction)
        if change {
            selectedPage = newValue
            updateCharts()
        }
    }

    private func navigateToStatsPageWithArrows(_ keyPress: KeyPress) -> KeyPress.Result {
        let direction = directionFromModifiers(keyPress)
        if direction != .same {
            navigateToStatsPage(direction)
            return .handled
        }
        return .ignored
    }

    private func navigateToStatsPageWithPrefix(_ keyPress: KeyPress) -> KeyPress.Result {
        let (change, newValue) = navigateGenericWithPrefix(pages, selectedPage, keyPress.characters.lowercased())
        if change {
            selectedPage = newValue
            updateCharts()
            return .handled
        }
        return .ignored
    }

    // MARK: - chart data factories

    private func makePickedFeatureChartData(_ logs: [LogFile]) -> PieChartData {
        let levelColors = makeLevelColors(1)
        let data = PieDataSet(
            dataPoints: [
                PieChartDataPoint(
                    value: Double(logs.reduce(0) { $0 + $1.log.features.filter({ isFeaturePicked($0) }).count }),
                    description: "Picked",
                    colour: levelColors[0]),
            ], legendTitle: "??")
        return PieChartData(
            dataSets: data,
            metadata: ChartMetadata(title: "Picked", subtitle: "Total picks"),
            chartStyle: PieChartStyle(infoBoxPlacement: .header))
    }

    private func makeFirstFeatureChartData(_ logs: [LogFile]) -> PieChartData {
        let levelColors = makeLevelColors(2)
        let data = PieDataSet(
            dataPoints: [
                PieChartDataPoint(
                    value: Double(logs.reduce(0) { $0 + $1.log.features.filter({ isFeaturePicked($0) && !$0.userHasFeaturesOnPage }).count }),
                    description: "First on page",
                    colour: levelColors[0]),
                PieChartDataPoint(
                    value: Double(logs.reduce(0) { $0 + $1.log.features.filter({ isFeaturePicked($0) && $0.userHasFeaturesOnPage }).count }),
                    description: "Not first",
                    colour: levelColors[1]),
            ], legendTitle: "??")
        return PieChartData(
            dataSets: data,
            metadata: ChartMetadata(title: "First feature", subtitle: "First time user is featured"),
            chartStyle: PieChartStyle(infoBoxPlacement: .header))
    }

    private func makePhotoFeaturedChartData(_ logs: [LogFile]) -> PieChartData {
        let levelColors = makeLevelColors(2)
        let data = PieDataSet(
            dataPoints: [
                PieChartDataPoint(
                    value: Double(logs.reduce(0) { $0 + $1.log.features.filter({ isFeaturePicked($0) && $0.photoFeaturedOnHub }).count }),
                    description: "Featured on hub",
                    colour: levelColors[0]),
                PieChartDataPoint(
                    value: Double(logs.reduce(0) { $0 + $1.log.features.filter({ isFeaturePicked($0) && !$0.photoFeaturedOnHub }).count }),
                    description: "Not featured",
                    colour: levelColors[1]),
            ], legendTitle: "??")
        return PieChartData(
            dataSets: data,
            metadata: ChartMetadata(title: "Photo featured", subtitle: "Photo feature on different page on hub"),
            chartStyle: PieChartStyle(infoBoxPlacement: .header))
    }

    private func makeUserLevelChartData(_ logs: [LogFile]) -> PieChartData {
        let levels = logs.reduce([MembershipCase]()) {
            var newVal = Set($1.log.features.filter { isFeaturePicked($0) }.map { $0.userLevel })
            newVal.formUnion($0)
            return Array(newVal)
        }.sorted(by: { (MembershipCase.allCasesSorted().firstIndex(of: $0) ?? 0) < (MembershipCase.allCasesSorted().firstIndex(of: $1) ?? 0) })
        let levelColors = makeLevelColors(levels.count)
        var levelColor = levelColors[0]
        let data = PieDataSet(
            dataPoints: levels.map({ level in
                let dataPoint = PieChartDataPoint(
                    value: Double(logs.reduce(0) { $0 + $1.log.features.filter({ isFeaturePicked($0) && $0.userLevel == level }).count }),
                    description: level.rawValue,
                    colour: levelColor)
                levelColor = nextColor(levelColor, levelColors)
                return dataPoint
            }), legendTitle: "??")
        return PieChartData(
            dataSets: data,
            metadata: ChartMetadata(title: "User level", subtitle: "Membership of the user before feature"),
            chartStyle: PieChartStyle(infoBoxPlacement: .header))
    }

    private func makePageFeatureCountChartData(_ logs: [LogFile]) -> PieChartData {
        let buckets = logs.reduce([Int]()) { accumulation, log in
            var newVal = Set(log.log.features.filter { isFeaturePicked($0) }.map { binFeatureCount(getPageFeatureCount(log.log, $0)) })
            newVal.formUnion(accumulation)
            return Array(newVal)
        }.sorted()
        let bucketColors = makeBucketColors(buckets.count)
        var bucketColor = bucketColors[0]
        let data = PieDataSet(
            dataPoints: buckets.map({ bucket in
                let dataPoint = PieChartDataPoint(
                    value: Double(
                        logs.reduce(0) { accumulation, log in
                            accumulation + log.log.features.filter({ isFeaturePicked($0) && binFeatureCount(getPageFeatureCount(log.log, $0)) == bucket }).count
                        }),
                    description: featureCountString(bucket, "page"),
                    colour: bucketColor)
                bucketColor = nextColor(bucketColor, bucketColors)
                return dataPoint
            }), legendTitle: "??")
        return PieChartData(
            dataSets: data,
            metadata: ChartMetadata(title: "Previous page features", subtitle: "Number of features the user has on page"),
            chartStyle: PieChartStyle(infoBoxPlacement: .header))
    }

    private func makeHubFeatureCountChartData(_ logs: [LogFile]) -> PieChartData {
        let buckets = logs.reduce([Int]()) { accumulation, log in
            var newVal = Set(log.log.features.filter { isFeaturePicked($0) }.map { binFeatureCount(getHubFeatureCount(log.log, $0)) })
            newVal.formUnion(accumulation)
            return Array(newVal)
        }.sorted()
        let bucketColors = makeBucketColors(buckets.count)
        var bucketColor = bucketColors[0]
        let data = PieDataSet(
            dataPoints: buckets.map({ bucket in
                let dataPoint = PieChartDataPoint(
                    value: Double(
                        logs.reduce(0) { accumulation, log in
                            accumulation + log.log.features.filter({ isFeaturePicked($0) && binFeatureCount(getHubFeatureCount(log.log, $0)) == bucket }).count
                        }),
                    description: featureCountString(bucket, "hub"),
                    colour: bucketColor)
                bucketColor = nextColor(bucketColor, bucketColors)
                return dataPoint
            }), legendTitle: "??")
        return PieChartData(
            dataSets: data,
            metadata: ChartMetadata(title: "Previous hub features", subtitle: "Number of features the user has on entire hub"),
            chartStyle: PieChartStyle(infoBoxPlacement: .header))
    }

    // MARK: - utilities

    private func isFeaturePicked(_ feature: LogFeature) -> Bool {
        return feature.isPicked && !feature.photoFeaturedOnPage && feature.tinEyeResults != .matchFound && feature.aiCheckResults != .ai && !feature.tooSoonToFeatureUser
    }

    private func makeLevelColors(_ slices: Int) -> [Color] {
        if slices <= 1 {
            return [Color(red: 0, green: 0, blue: 1)]
        }
        let sliceAmount = 0.8 / Double(slices - 1)
        return (0 ..< slices).map { Color(red: 0, green: 0.2 + sliceAmount * Double($0), blue: 1 - sliceAmount * Double($0)) }
    }

    private func makeBucketColors(_ slices: Int) -> [Color] {
        if slices <= 1 {
            return [Color(red: 0, green: 0, blue: 1)]
        }
        let sliceAmount = 0.8 / Double(slices - 1)
        return (0 ..< slices).map { Color(red: 0.2 + sliceAmount * Double($0), green: 0, blue: 1 - sliceAmount * Double($0)) }
    }

    private func nextColor(_ color: Color, _ colors: [Color]) -> Color {
        if let index = colors.firstIndex(of: color) {
            return colors[(index + 1) % colors.count]
        }
        return colors[0]
    }

    private func getPageFeatureCount(_ log: Log, _ feature: LogFeature) -> Int {
        if feature.userHasFeaturesOnPage && feature.featureCountOnPage == "many" {
            return Int.max
        }
        return feature.userHasFeaturesOnPage ? (Int(feature.featureCountOnPage) ?? 0) : 0
    }

    private func getHubFeatureCount(_ log: Log, _ feature: LogFeature) -> Int {
        if feature.userHasFeaturesOnHub && feature.featureCountOnHub == "many" {
            return Int.max
        }
        return feature.userHasFeaturesOnHub ? (Int(feature.featureCountOnHub) ?? 0) : 0
    }

    private func binFeatureCount(_ featureCount: Int) -> Int {
        if featureCount == 0 || featureCount == Int.max {
            return featureCount // 0 and max are special
        }
        return Int((featureCount - 1) / 5) * 5 + 1
    }

    private func featureCountString(_ featureCount: Int, _ bucket: String) -> String {
        return featureCount == Int.max
            ? "Many existing \(bucket) features"
            : featureCount == 0
            ? "No existing \(bucket) features"
            : "\(featureCount)-\(featureCount + 4) existing \(bucket) features"
    }
}

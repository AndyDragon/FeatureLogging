//
//  ContentView.swift
//  Feature Logging
//
//  Created by Andrew Forget on 2024-07-12.
//

import SwiftUI
import AlertToast
import SwiftUICharts

struct LogFile {
    var fileName: String
    var log: Log
}

struct StatisticsContentView: View {
    @Environment(\.self) var environment
    @State private var showDirectoryPicker = false
    @State private var location = ""
    @State private var logs = [LogFile]()
    @State private var pages = [String]()
    @State private var selectedPage = ""
    @State private var logChartViewModel: StackedBarChartData? = nil
    private var isShowingToast: Binding<Bool>
    private var hideStatisticsView: () -> Void
    private var showToast: (_ type: AlertToast.AlertType, _ text: String, _ subTitle: String, _ duration: Int, _ onTap: @escaping () -> Void) -> Void

    init(
        _ isShowingToast: Binding<Bool>,
        _ hideStatisticsView: @escaping () -> Void,
        _ showToast: @escaping (_ type: AlertToast.AlertType, _ text: String, _ subTitle: String, _ duration: Int, _ onTap: @escaping () -> Void) -> Void
    ) {
        self.isShowingToast = isShowingToast
        self.hideStatisticsView = hideStatisticsView
        self.showToast = showToast
    }

    var body: some View {
        ZStack {
            Color.BackgroundColor.edgesIgnoringSafeArea(.all)
            
            VStack {
                HStack {
                    Button(action: {
                        showDirectoryPicker.toggle()
                    }) {
                        HStack {
                            Image(systemName: "folder")
                            Text("Open folder containing your log files...")
                        }
                        .foregroundStyle(Color.TextColorPrimary, Color.TextColorSecondary)
                    }
                    .fileImporter(isPresented: $showDirectoryPicker, allowedContentTypes: [.folder], onCompletion: { result in
                        switch result {
                        case .success(let folder):
                            selectedPage = ""
                            logChartViewModel = nil
                            logs = [LogFile]()
                            location = folder.path().trimmingCharacters(in: ["/"])
                            let fileManager = FileManager.default
                            let gotAccess = folder.startAccessingSecurityScopedResource()
                            if !gotAccess { return }
                            do {
                                let items = try fileManager.contentsOfDirectory(at: folder, includingPropertiesForKeys: [.isDirectoryKey]).filter({ item in item.isFileURL && item.pathExtension == "json"})
                                for item in items {
                                    do {
                                        let data = try Data(contentsOf: item)
                                        let log = try JSONDecoder().decode(Log.self, from: data)
                                        logs.append(LogFile(fileName: item.path(), log: log))
                                    } catch {
                                        debugPrint(error.localizedDescription)
                                    }
                                }
                                print("Loaded \(logs.count) logs")
                                var pageSet = Set(logs.map { $0.log.page })
                                pageSet.formUnion(Set(logs.map { log in log.log.page.components(separatedBy: [":"]).first ?? "" }.filter { hub in hub != "" }))
                                pages = Array(pageSet).sorted()
                                pages.insert("all", at: 0)
                            }
                            catch {
                                debugPrint(error.localizedDescription)
                            }
                            folder.stopAccessingSecurityScopedResource()
                        case .failure(let error):
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
                    Picker("Choose a page", selection: $selectedPage.onChange({ page in
                        logChartViewModel = nil
                        
                        let pageLogs = logs.filter({ log in
                            if page == "all" {
                                return true;
                            }
                            if !page.contains(":") {
                                return log.log.page.starts(with: page)
                            }
                            return log.log.page == page
                        })
                        var allGroups: [GroupingData] = []
                        
                        let totalGroup = GroupingData(title: "Total picks", colour: ColourStyle(colour: .blue))
                        allGroups.append(totalGroup)
                        
                        let firstTimeGroup = GroupingData(title: "First feature on page", colour: ColourStyle(colour: .green))
                        let notFirstTimeGroup = GroupingData(title: "Already on page", colour: ColourStyle(colour: .red))
                        allGroups.append(firstTimeGroup)
                        allGroups.append(notFirstTimeGroup)
                        
                        let levels = pageLogs.reduce([MembershipCase]()) {
                            var newVal = Set($1.log.features.map { $0.userLevel })
                            if newVal.contains(.none) {
                                debugPrint("Found level None in \($1.fileName)")
                                $1.log.features.forEach({ feature in
                                    if feature.userLevel == MembershipCase.none {
                                        debugPrint("    Feature for \(feature.userName)")
                                    }
                                })
                            }
                            newVal.formUnion($0)
                            return Array(newVal)
                        }.sorted(by: { (MembershipCase.allCasesSorted().firstIndex(of: $0) ?? 0) < (MembershipCase.allCasesSorted().firstIndex(of: $1) ?? 0) })
                        var levelGroups: [MembershipCase: GroupingData] = [:]
                        var levelColor = levelColors[0]
                        levels.forEach({ level in
                            levelGroups[level] = GroupingData(title: level.rawValue, colour: ColourStyle(colour: levelColor))
                            levelColor = nextColor(levelColor, levelColors)
                            allGroups.append(levelGroups[level]!)
                            if level == MembershipCase.none {
                                debugPrint("Found None level")
                            }
                        })
                        
                        let featureCounts = pageLogs.reduce([Int]()) { accumulation, log in
                            var newVal = Set(log.log.features.map { getFeatureCount(log.log, $0) })
                            newVal.formUnion(accumulation)
                            return Array(newVal)
                        }.sorted()
                        var featureCountGroups: [Int: GroupingData] = [:]
                        var featureCountColor = featureCountColors[0]
                        featureCounts.forEach({ featureCount in
                            featureCountGroups[featureCount] = GroupingData(title: featureCountString(featureCount), colour: ColourStyle(colour: featureCountColor))
                            featureCountColor = nextColor(featureCountColor, featureCountColors)
                            allGroups.append(featureCountGroups[featureCount]!)
                        })
                        
                        let featuredOnHubGroup = GroupingData(title: "Photo featured on hub", colour: ColourStyle(colour: .cyan))
                        let notFeaturedGroup = GroupingData(title: "Already on page", colour: ColourStyle(colour: .purple))
                        allGroups.append(featuredOnHubGroup)
                        allGroups.append(notFeaturedGroup)

                        logChartViewModel = StackedBarChartData(
                            dataSets: StackedBarDataSets(dataSets: [
                                StackedBarDataSet(dataPoints: [
                                    StackedBarDataPoint(value: Double(pageLogs.reduce(0) { $0 + $1.log.features.filter({ $0.isPicked }).count }), description: "Picks", group: totalGroup)
                                ], setTitle: "Total Picks"),
                                
                                StackedBarDataSet(dataPoints: [
                                    StackedBarDataPoint(value: Double(pageLogs.reduce(0) { $0 + $1.log.features.filter({ $0.isPicked && !$0.userHasFeaturesOnPage }).count }), description: "First on page", group: firstTimeGroup),
                                    StackedBarDataPoint(value: Double(pageLogs.reduce(0) { $0 + $1.log.features.filter({ $0.isPicked && $0.userHasFeaturesOnPage }).count }), description: "Already on page", group: notFirstTimeGroup)
                                ], setTitle: "First on page"),
                                
                                StackedBarDataSet(dataPoints: levels.map({ level in
                                    StackedBarDataPoint(
                                        value: Double(pageLogs.reduce(0) { $0 + $1.log.features.filter({ $0.isPicked && $0.userLevel == level }).count }),
                                        description: level.rawValue,
                                        group: levelGroups[level]!)
                                }), setTitle: "User level"),
                                
                                StackedBarDataSet(dataPoints: featureCounts.map({ featureCount in
                                    StackedBarDataPoint(
                                        value: Double(pageLogs.reduce(0) { accumulation, log in accumulation + log.log.features.filter({ $0.isPicked && getFeatureCount(log.log, $0) == featureCount }).count }),
                                        description: featureCountString(featureCount),
                                        group: featureCountGroups[featureCount]!)
                                }), setTitle: "Existing page features"),
                                
                                StackedBarDataSet(dataPoints: [
                                    StackedBarDataPoint(value: Double(pageLogs.reduce(0) { $0 + $1.log.features.filter({ $0.isPicked && $0.photoFeaturedOnHub }).count }), description: "Featured on hub", group: featuredOnHubGroup),
                                    StackedBarDataPoint(value: Double(pageLogs.reduce(0) { $0 + $1.log.features.filter({ $0.isPicked && !$0.photoFeaturedOnHub }).count }), description: "Not featured", group: notFeaturedGroup)
                                ], setTitle: "Photo featured"),
                            ]),
                            groups: allGroups,
                            metadata: ChartMetadata(title: "Features"),
                            barStyle: BarStyle(barWidth: 0.5, cornerRadius: CornerRadius(left: 0.1, right: 0.1)),
                            chartStyle: BarChartStyle(infoBoxPlacement: .infoBox(isStatic: false),
                                                      xAxisGridStyle: GridStyle(numberOfLines: 5,
                                                                                lineColour: Color.gray.opacity(0.25)),
                                                      xAxisLabelsFrom: .dataPoint(rotation: .degrees(0)),
                                                      yAxisGridStyle: GridStyle(numberOfLines: 5,
                                                                                lineColour: Color.gray.opacity(0.25)),
                                                      yAxisNumberOfLabels: 10,
                                                      baseline: .zero,
                                                      topLine: .maximum(of: Double(pageLogs.count)),
                                                      globalAnimation: .easeOut(duration: 0.4)))
                    })) {
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
                }
                if let logChartViewModel {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8).fill(Color(red: 0.1, green: 0.1, blue: 0.16))
                        
                        StackedBarChart(chartData: logChartViewModel)
                            .id(logChartViewModel.id)
                            .touchOverlay(chartData: logChartViewModel)
                            .xAxisGrid(chartData: logChartViewModel)
                            .xAxisLabels(chartData: logChartViewModel)
                            .yAxisGrid(chartData: logChartViewModel)
                            .yAxisLabels(chartData: logChartViewModel)
                            .legends(chartData: logChartViewModel, columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())])
                            .infoBox(chartData: logChartViewModel)
                            .headerBox(chartData: logChartViewModel)
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
                            .foregroundStyle(Color.TextColorPrimary, Color.TextColorSecondary)
                        Text("Close (⌘+`)")
                            .font(.system(.body, design: .rounded).bold())
                            .foregroundStyle(Color.TextColorPrimary, Color.TextColorSecondary)
                    }
                    .padding(4)
                    .buttonStyle(.plain)
                }
                .keyboardShortcut("`", modifiers: .command)
                .disabled(isShowingToast.wrappedValue)
            }
            .allowsHitTesting(!isShowingToast.wrappedValue)
        }
        .frame(minWidth: 1024, minHeight: 600)
        .background(Color.BackgroundColor)
    }

    private let levelColors = [
        Color(red: 0.25, green: 0, blue: 0),
        Color(red: 1, green: 0, blue: 0),
        Color(red: 0.01, green: 0, blue: 0.25),
        Color(red: 0.01, green: 0, blue: 1),
        Color(red: 0.25, green: 0, blue: 0.25),
        Color(red: 1, green: 0, blue: 1),
        Color(red: 0.25, green: 0, blue: 0.5),
        Color(red: 1, green: 0, blue: 0.25),
        Color(red: 0.25, green: 0, blue: 0.75),
        Color(red: 1, green: 0, blue: 0.5),
        Color(red: 0.25, green: 0, blue: 1),
        Color(red: 1, green: 0, blue: 0.75),

        
        Color(red: 0.5, green: 0, blue: 0),
        Color(red: 0.75, green: 0, blue: 0),
        Color(red: 0.01, green: 0, blue: 0.5),
        Color(red: 0.01, green: 0, blue: 0.75),
        Color(red: 0.5, green: 0, blue: 0.5),
        Color(red: 0.75, green: 0, blue: 0.75),
        Color(red: 0.5, green: 0, blue: 0.25),
        Color(red: 0.75, green: 0, blue: 0.25),
        Color(red: 0.5, green: 0, blue: 0.75),
        Color(red: 0.75, green: 0, blue: 0.5),
        Color(red: 0.5, green: 0, blue: 1),
        Color(red: 0.75, green: 0, blue: 1),
    ];
    
    private let featureCountColors = [
        Color(red: 0, green: 0.25, blue: 0),
        Color(red: 0, green: 1, blue: 0),
        Color(red: 0, green: 0.01, blue: 0.25),
        Color(red: 0, green: 0.01, blue: 1),
        Color(red: 0, green: 0.25, blue: 0.25),
        Color(red: 0, green: 1, blue: 1),
        Color(red: 0, green: 0.25, blue: 0.5),
        Color(red: 0, green: 1, blue: 0.25),
        Color(red: 0, green: 0.25, blue: 0.75),
        Color(red: 0, green: 1, blue: 0.5),
        Color(red: 0, green: 0.25, blue: 1),
        Color(red: 0, green: 1, blue: 0.75),

        Color(red: 0, green: 0.5, blue: 0),
        Color(red: 0, green: 0.75, blue: 0),
        Color(red: 0, green: 0.01, blue: 0.5),
        Color(red: 0, green: 0.01, blue: 0.75),
        Color(red: 0, green: 0.5, blue: 0.5),
        Color(red: 0, green: 0.75, blue: 0.75),
        Color(red: 0, green: 0.5, blue: 0.25),
        Color(red: 0, green: 0.75, blue: 0.25),
        Color(red: 0, green: 0.5, blue: 0.75),
        Color(red: 0, green: 0.75, blue: 0.5),
        Color(red: 0, green: 0.5, blue: 1),
        Color(red: 0, green: 0.75, blue: 1),
    ];

    private func nextColor(_ color: Color, _ colors: [Color]) -> Color {
        if let index = colors.firstIndex(of: color) {
            return colors[(index + 1) % colors.count]
        }
        return colors[0]
    }
    
    private func getFeatureCount(_ log: Log, _ feature: LogFeature) -> Int {
        if log.page.starts(with: "snap:") {
            if feature.userHasFeaturesOnPage && feature.featureCountOnPage == "many" {
                return Int.max
            }
            if feature.userHasFeaturesOnPage && feature.featureCountOnRawPage == "many" {
                return Int.max
            }
            let featureCountOnPage = feature.userHasFeaturesOnPage ? (Int(feature.featureCountOnPage) ?? 0) : 0;
            let featureCountOnRawPage = feature.userHasFeaturesOnPage ? (Int(feature.featureCountOnRawPage) ?? 0) : 0;
            return featureCountOnPage + featureCountOnRawPage
        }
        if feature.userHasFeaturesOnPage && feature.featureCountOnPage == "many" {
            return Int.max
        }
        return feature.userHasFeaturesOnPage ? (Int(feature.featureCountOnPage) ?? 0) : 0
    }
    
    private func featureCountString(_ featureCount: Int) -> String {
        return featureCount == Int.max
        ? "Many existing features"
        : featureCount == 0
        ? "No existing features"
        : "\(featureCount) existing feature\(featureCount == 1 ? "" : "s")"
    }
}

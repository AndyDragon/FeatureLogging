//
//  FeatureList.swift
//  Feature Logging
//
//  Created by Andrew Forget on 2024-12-18.
//

import SwiftUI
import SystemColors

struct FeatureList: View {
    private var viewModel: ContentView.ViewModel
    private var showScriptView: () -> Void

    @State private var hoveredFeature: UUID? = nil

    init(
        _ viewModel: ContentView.ViewModel,
        _ showScriptView: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.showScriptView = showScriptView
    }

    var body: some View {
        List {
            ForEach(viewModel.sortedFeatures, id: \.self) { feature in
                FeatureListRow(
                    viewModel,
                    feature,
                    showScriptView
                )
                .padding([.top, .bottom], 8)
                .padding([.leading, .trailing])
#if os(macOS)
                .foregroundStyle(
                    Color(
                        nsColor: hoveredFeature == feature.id
                        ? NSColor.selectedControlTextColor
                        : NSColor.labelColor), Color(nsColor: .labelColor)
                )
#else
//                .foregroundStyle(
//                    hoveredFeature == feature.id
//                        ? Color.selectedControlText
//                        : Color.label,
//                    Color.label
//                )
#endif
                .background(
                    viewModel.selectedFeature?.feature == feature
                    ? Color.BackgroundColorListSelected
                    : hoveredFeature == feature.id
                    ? Color.BackgroundColorListSelected.opacity(0.33)
                    : Color.BackgroundColorList
                )
                .cornerRadius(4)
                .onHover(perform: { hovering in
                    if !hovering {
                        if hoveredFeature == feature.id {
                            hoveredFeature = nil
                        }
                    } else {
                        if hoveredFeature != feature.id {
                            hoveredFeature = feature.id
                        }
                    }
                })
                .onTapGesture {
                    if viewModel.selectedFeature?.feature != feature {
                        withAnimation {
                            viewModel.selectedFeature = ObservableFeatureWrapper(using: viewModel.selectedPage!, from: feature)
                            viewModel.visibleView = .FeatureEditorView
                        }
                    }
                }
            }
        }
    }
}

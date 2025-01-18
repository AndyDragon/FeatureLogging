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

#if os(macOS)
    @State private var hoveredFeature: UUID? = nil
#endif

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
#if os(macOS)
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
#endif
                .onTapGesture {
                    withAnimation {
                        viewModel.selectedFeature = ObservableFeatureWrapper(using: viewModel.selectedPage!, from: feature)
                        viewModel.visibleView = .FeatureEditorView
                    }
                }
                .padding([.top, .bottom], 4)
                .padding([.leading, .trailing])
#if os(macOS)
                .foregroundStyle(
                    Color(
                        nsColor: hoveredFeature == feature.id
                        ? NSColor.selectedControlTextColor
                        : NSColor.labelColor), Color(nsColor: .labelColor)
                )
#else
                .foregroundStyle(Color.label, Color.label)
#endif
                .background(Color.backgroundColor)
                .cornerRadius(4)
                .padding([.top, .bottom], 4)
            }
            .listRowSeparator(.hidden)
            .listRowSeparatorTint(.clear)
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        }
        .listStyle(SidebarListStyle())
        .listSectionSeparator(.hidden)
        .contentMargins(.top, 12)
    }
}

//
//  FeatureList.swift
//  Feature Logging
//
//  Created by Andrew Forget on 2024-12-18.
//

import SwiftUI

struct FeatureList: View {
    private var viewModel: ContentView.ViewModel

    init(
        _ viewModel: ContentView.ViewModel
    ) {
        self.viewModel = viewModel
    }

    var body: some View {
        List {
            ForEach(viewModel.sortedFeatures, id: \.self) { feature in
                FeatureListRow(
                    viewModel,
                    feature
                )
                .onTapGesture {
                    withAnimation {
                        viewModel.selectedFeature = ObservableFeatureWrapper(using: viewModel.selectedPage!, from: feature)
                        viewModel.visibleView = .FeatureEditorView
                    }
                }
                .padding([.top, .bottom], 4)
                .padding([.leading, .trailing])
                .foregroundStyle(Color(UIColor.label), Color(UIColor.label))
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

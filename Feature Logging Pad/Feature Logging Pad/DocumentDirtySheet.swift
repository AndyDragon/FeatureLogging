//
//  DocumentDirtySheet.swift
//  Feature Logging
//
//  Created by Andrew Forget on 2024-11-23.
//

import SwiftUI
import UniformTypeIdentifiers

struct DocumentDirtySheet: View {
    @Binding var isShowing: Bool
    @Binding var confirmationText: String
    var saveAction: () -> Void
    var dismissAction: () -> Void
    var cancelAction: () -> Void

    var body: some View {
        VStack {
            HStack(alignment: .center) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color.black, Color.yellow)
                    .font(.largeTitle)
                Spacer()
                    .frame(width: 16)
                Text("The log file has been edited and not saved")
                    .font(.title)
                Spacer()
            }
            Spacer()
                .frame(height: 16)
            Text(confirmationText)
            Spacer()
                .frame(height: 16)
            HStack(alignment: .bottom) {
                Spacer()
                Button(
                    "Yes",
                    action: {
                        isShowing.toggle()
                        saveAction()
                    })
                .buttonStyle(.bordered)
                Spacer()
                    .frame(width: 8)
                Button(
                    "No", role: .destructive,
                    action: {
                        isShowing.toggle()
                        dismissAction()
                    })
                .buttonStyle(.bordered)
                Spacer()
                    .frame(width: 8)
                Button(
                    "Cancel", role: .cancel,
                    action: {
                        isShowing.toggle()
                        cancelAction()
                    })
                .buttonStyle(.bordered)
                Spacer()
            }
        }
        .padding(24)
    }
}

//
//  ToastDismissShield.swift
//  Feature Logging
//
//  Created by Andrew Forget on 2024-03-29.
//

import SwiftUI

struct ToastDismissShield: View {
    private var toastManager: ContentView.ToastManager

    init(
        _ toastManager: ContentView.ToastManager
    ) {
        self.toastManager = toastManager
    }

    var body: some View {
        if toastManager.isShowingAnyToast {
            VStack {
                Rectangle().opacity(0.0000001)
            }
            .onTapGesture {
                toastManager.hideAnyToast()
            }
        }
    }
}

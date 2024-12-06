//
//  ToastDismissShield.swift
//  Feature Logging
//
//  Created by Andrew Forget on 2024-03-29.
//

import SwiftUI

struct ToastDismissShield: View {
    let isAnyToastShowing: Bool
    @Binding var isShowingToast: Bool
    @Binding var toastId: UUID?
    @Binding var isShowingVersionAvailableToast: Bool

    var body: some View {
        if isAnyToastShowing {
            VStack {
                Rectangle().opacity(0.0000001)
            }
            .onTapGesture {
                if isShowingToast {
                    toastId = nil
                    isShowingToast.toggle()
                } else if isShowingVersionAvailableToast {
                    isShowingVersionAvailableToast.toggle()
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var isShowingToast: Bool = false
    @Previewable @State var isShowingVersionAvailableToast: Bool = false
    @Previewable @State var toastId: UUID? = nil
    let isAnyToastShowing: Bool = false
    return ToastDismissShield(
        isAnyToastShowing: isAnyToastShowing,
        isShowingToast: $isShowingToast,
        toastId: $toastId,
        isShowingVersionAvailableToast: $isShowingVersionAvailableToast)
}

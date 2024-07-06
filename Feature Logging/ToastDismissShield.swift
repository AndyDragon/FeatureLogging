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
                    isShowingToast.toggle()
                    toastId = nil
                } else if isShowingVersionAvailableToast {
                    isShowingVersionAvailableToast.toggle()
                }
            }
        }
    }
}

#Preview {
    let isAnyToastShowing: Bool = false
    @State var isShowingToast: Bool = false
    @State var isShowingVersionAvailableToast: Bool = false
    @State var toastId: UUID? = nil
    return ToastDismissShield(
        isAnyToastShowing: isAnyToastShowing,
        isShowingToast: $isShowingToast,
        toastId: $toastId,
        isShowingVersionAvailableToast: $isShowingVersionAvailableToast)
}

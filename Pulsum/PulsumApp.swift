//
//  PulsumApp.swift
//  Pulsum
//
//  Created by Martin Demel on 9/28/25.
//

import SwiftUI
import PulsumUI
import PulsumTypes

@main
struct PulsumApp: App {
    init() {
#if canImport(UIKit)
        if AppRuntimeConfig.disableAnimations {
            UIView.setAnimationsEnabled(false)
        }
#endif
    }

    var body: some Scene {
        WindowGroup {
            PulsumRootView()
                .transaction { transaction in
                    if AppRuntimeConfig.disableAnimations {
                        transaction.disablesAnimations = true
                        transaction.animation = nil
                    }
                }
        }
    }
}

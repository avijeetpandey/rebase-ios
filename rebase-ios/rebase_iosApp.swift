//
//  rebase_iosApp.swift
//  rebase-ios
//
//  Created by Avijeet Pandey on 17/04/26.
//

import SwiftUI

@main
struct rebase_iosApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}

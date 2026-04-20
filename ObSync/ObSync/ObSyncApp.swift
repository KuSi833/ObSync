//
//  ObSyncApp.swift
//  ObSync
//
//  Created by Karlo Milicic on 07/04/2026.
//

import SwiftUI
import UIKit

@main
struct ObSyncApp: App {
    init() {
        let firaBody = UIFont(name: "FiraCodeRoman-Regular", size: 17) ?? .monospacedSystemFont(ofSize: 17, weight: .regular)
        let firaBold = UIFont(name: "FiraCodeRoman-SemiBold", size: 17) ?? .monospacedSystemFont(ofSize: 17, weight: .semibold)
        let firaLargeTitle = UIFont(name: "FiraCodeRoman-Bold", size: 34) ?? .monospacedSystemFont(ofSize: 34, weight: .bold)

        // Navigation bar
        let navAppearance = UINavigationBarAppearance()
        navAppearance.largeTitleTextAttributes = [.font: firaLargeTitle]
        navAppearance.titleTextAttributes = [.font: firaBold]
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance

        // Bar button items
        UIBarButtonItem.appearance().setTitleTextAttributes([.font: firaBody], for: .normal)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .font(.firaCode(.body))
        }
    }
}

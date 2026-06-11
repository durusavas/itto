//
//  ittoApp.swift
//  itto
//
//  Created by Duru SAVAŞ on 17/11/2023.
//

import SwiftUI

@main
struct ittoApp: App {
    init() {
            UIView.appearance().overrideUserInterfaceStyle = .dark
        
        }
    var body: some Scene {
        WindowGroup {
            SplashScreenView()
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
    }
    
    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "itto" else { return }
        let path = url.host ?? url.path
        let tab: Int
        switch path {
        case "today":
            tab = 0
        case "timer":
            tab = 1
        case "subjects":
            tab = 2
        case "reports":
            tab = 3
        default:
            tab = 0
        }
        UserDefaults.standard.set(tab, forKey: "selectedTab")
        // Post notification for MainView to pick up if needed
        NotificationCenter.default.post(name: Notification.Name("DeepLinkTab"), object: tab)
    }
}

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
        }
    }
}

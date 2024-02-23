//
//  ittoApp.swift
//  itto
//
//  Created by Duru SAVAŞ on 17/11/2023.
//

import SwiftUI

@main
struct ittoApp: App {
  
   // @StateObject private var dataController = DataController() // ben ekledim coredata için
    
    var body: some Scene {
        WindowGroup {
            SplashScreenView()
            //MainView()
             //   .environment(\.managedObjectContext, dataController.container.viewContext) // reading data
        }
    }
}

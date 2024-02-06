//
//  MainView.swift
//  itto
//
//  Created by Duru SAVAŞ on 19/11/2023.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        TabView {
            ContentView()
                .tabItem {
                    Label("Timer", systemImage: "timer")
                    
                }
            SubjectView()
                .tabItem {
                    Label("Subjects", systemImage: "list.bullet")
                    
                }
            ReportView()
                .tabItem {
                    Label("Report", systemImage: "chart.bar.fill")
                }
        }
        .accentColor(.blue)
    }
}



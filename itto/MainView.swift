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
            TodayView()
                .tabItem{
                    Label(LocalizedStringKey("Today"), systemImage: "house" )
                }
            
            ContentView()
                .tabItem {
                    Label(LocalizedStringKey("Timer"), systemImage: "timer")
                    
                }
            SubjectView()
                .tabItem {
                    Label(LocalizedStringKey("Subjects"), systemImage: "list.bullet")
                    
                }
            ReportView()
                .tabItem {
                    Label(LocalizedStringKey("Report"), systemImage: "chart.bar.fill")
                }
        }
        .accentColor(.blue)
    }
}



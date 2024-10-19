//
//  MainView.swift
//  itto
//
//  Created by Duru SAVAŞ on 19/11/2023.
//

import SwiftUI

struct MainView: View {
    @State private var selectedTab = 0
    
    init() {
        UITabBar.appearance().isHidden = true
    }
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                TodayView()
                    .tag(0)
                
                ContentView()
                    .tag(1)
                
                SubjectView()
                    .tag(2)
                
                ReportView()
                    .tag(3)
            }
            
            
            VStack {
                Spacer()
                
                HStack(spacing: 40) {
                    
                    TabBarItem(iconName: "house", isSelected: selectedTab == 0)
                        .onTapGesture {
                            selectedTab = 0
                        }
                    TabBarItem(iconName: "timer", isSelected: selectedTab == 1)
                        .onTapGesture {
                            selectedTab = 1
                        }
                    TabBarItem(iconName: "list.bullet", isSelected: selectedTab == 2)
                        .onTapGesture {
                            selectedTab = 2
                        }
                    TabBarItem(iconName: "chart.bar.fill", isSelected: selectedTab == 3)
                        .onTapGesture {
                            selectedTab = 3
                        }
                }
                .padding(20)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(30)
                
            }
        }
    }
}

struct TabBarItem: View {
    let iconName: String
    let isSelected: Bool
    
    var body: some View {
        Image(systemName: iconName)
            .font(.system(size: 24))
            .foregroundColor(isSelected ? .white : .gray)
    }
}




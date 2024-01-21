//
//  MainView.swift
//  itto
//
//  Created by Duru SAVAŞ on 19/11/2023.
//

import SwiftUI

let gradient = LinearGradient(
    gradient: Gradient(colors: [
        Color(red: 0 / 255, green: 28 / 255, blue: 40 / 255, opacity: 1),
        Color(red: 0 / 255, green: 59 / 255, blue: 139 / 255, opacity: 1)
    ]),
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)



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


struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
        MainView()
            .preferredColorScheme(.dark)
    }
}

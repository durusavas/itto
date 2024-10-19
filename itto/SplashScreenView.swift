//
//  SplashScreenView.swift
//  itto
//
//  Created by Duru SAVAŞ on 06/02/2024.
//


import SwiftUI

struct SplashScreenView: View {
    
    @StateObject private var dataController = DataController()
    @State var isActive: Bool = false
    @State private var size = 0.2
    @State private var opacity = 1.0
    let demoColors: [Color] = [.red, .blue, .purple]
    
    var body: some View {
        if isActive {
            MainView()
                .environment(\.managedObjectContext, dataController.container.viewContext)
        } else {
            VStack {
                MainCircleView(colors: demoColors) {
                    Text("")
                }
                .scaleEffect(size)
                .opacity(opacity)
            }
            .onAppear {
                withAnimation(.easeIn(duration: 0.8)) {
                    self.size = 6.0
                    self.opacity = 1.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    withAnimation {
                        self.isActive = true
                    }
                }
            }
        }
    }
}

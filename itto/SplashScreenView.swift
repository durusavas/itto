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
    @State private var size = 0.5
    @State private var opacity = 1.0
    
    var body: some View {
        if isActive {
            MainView()
                .environment(\.managedObjectContext, dataController.container.viewContext)
        } else {
            VStack {
                Image("logo1")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: UIScreen.main.bounds.width * size)
            }
            .scaleEffect(size)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeIn(duration: 1.3)) {
                    self.size = 0.6
                    self.opacity = 0.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation {
                        self.isActive = true
                    }
                }
            }
        }
    }
}

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
    @State private var size = 0.5 // Start with an initial size that fits the screen
    @State private var opacity = 1.0 // Start fully visible
    
    var body: some View {
        if isActive {
            MainView()
                .environment(\.managedObjectContext, dataController.container.viewContext)
        } else {
            VStack {
                Image("logo1")
                    .resizable() // Make sure your image is resizable
                    .aspectRatio(contentMode: .fit) // Keep the logo's aspect ratio
                    .frame(width: UIScreen.main.bounds.width * size) // Adjust the width as necessary
            }
            .scaleEffect(size)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeIn(duration: 1.3)) {
                    self.size = 0.6 // Increase size to make the logo expand beyond the screen bounds
                    self.opacity = 0.0 // Fade out the logo
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation {
                        self.isActive = true // Transition to the next view
                    }
                }
            }
        }
    }
}

// Preview provider omitted for brevity

//
//  MainCircleView.swift
//  itto
//
//  Created by Duru SAVAŞ on 09/07/2024.
//

import SwiftUI

struct MainCircleView<Content: View>: View {
    var colors: [Color]
    var content: () -> Content
    @State private var startAngle: Angle = .degrees(0)
    @State private var endAngle: Angle = .degrees(360)

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(
                    AngularGradient(
                        gradient: Gradient(colors: colors.isEmpty ? [Color.black] : colors),
                        center: .center,
                        startAngle: startAngle,
                        endAngle: endAngle
                    ),
                    lineWidth: 15
                )
                .frame(width: 250, height: 250)
                .blur(radius: 30)
                .overlay {
                  Circle()
                    .stroke(lineWidth: 4.0)
                    .fill(.white)
                        .blur(radius: 10.0)
                }
                .mask(
                    Circle()
                        .frame(width: 250, height: 250)
                    
                )
                .onAppear {
                    withAnimation(Animation.linear(duration: 15).repeatForever(autoreverses: false)) {
                        startAngle = .degrees(360)
                        endAngle = .degrees(720)
                    }
                }
            
            
              

            Circle()
                .fill(Color.clear)
                .frame(width: 180, height: 180)

            VStack {
                content()
            } 
        }
       
    }
    
}

struct MainCircleView_Previews: PreviewProvider {
    static var previews: some View {
        MainCircleView(colors: [Color.red, Color.blue, Color.green]) {
            Button(action: {
                // Timer start action
            }) {
                Image(systemName: "play.fill")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(10)
            }
        }
    }
}

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
                .fill(Color.ittoPurple)
                .frame(width: 320, height: 320)
                .blur(radius: 55)
            
            Circle()
                .fill(Color.bg2)
                .frame(width: 250, height: 250)
            
            Circle()
                .strokeBorder(
                    AngularGradient(
                        gradient: Gradient(colors: colors.isEmpty ? [Color.black] : colors),
                        center: .center,
                        startAngle: startAngle,
                        endAngle: endAngle
                    ),
                    lineWidth: 10
                )
                .frame(width: 250, height: 250)
                .blur(radius: 20)
                .overlay {
                    Circle()
                        .stroke(lineWidth: 4)
                        .fill(.white.opacity(0.7))
                        .blur(radius: 7)
                }
                .mask(
                    Circle()
                        .frame(width: 250, height: 250)
                )
                .onAppear {
                    withAnimation(Animation.linear(duration: 10).repeatForever(autoreverses: false)) {
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
        .edgesIgnoringSafeArea(.all)
    }
}

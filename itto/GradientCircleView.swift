//
//  GradientCircleView.swift
//  itto
//
//  Created by Duru SAVAŞ on 03/07/2024.
//

import SwiftUI

struct GradientCircleView: View {
    var baseColor: Color
    
    var body: some View {
        Circle()
            .fill(LinearGradient(
                gradient: Gradient(colors: [baseColor, baseColor.lighter(by: 50)]),
                startPoint: .top,
                endPoint: .bottom
            ))
    }
}

extension Color {
    func lighter(by percentage: Double) -> Color {
        let components = UIColor(self).cgColor.components!
        let red = components[0] + (1 - components[0]) * CGFloat(percentage / 100)
        let green = components[1] + (1 - components[1]) * CGFloat(percentage / 100)
        let blue = components[2] + (1 - components[2]) * CGFloat(percentage / 100)
        return Color(red: red, green: green, blue: blue)
    }
}

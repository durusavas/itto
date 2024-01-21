//
//  ReportView.swift
//  itto
//
//  Created by Duru SAVAŞ on 19/11/2023.
//

import SwiftUI
import CoreData
import Charts

let gradientBackground = LinearGradient(
    gradient: Gradient(colors: [
        Color(red: 0 / 255, green: 28 / 255, blue: 40 / 255, opacity: 1),
        Color(red: 0 / 255, green: 59 / 255, blue: 139 / 255, opacity: 1)
    ]),
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)

struct ReportView: View {
    @FetchRequest(sortDescriptors: []) var report: FetchedResults<Report>
    @FetchRequest(sortDescriptors: []) var subject: FetchedResults<Subjects>

    var combinedReports: [CombinedReport] {
        var combinedList: [CombinedReport] = []
        for reportItem in report {
            if let subjectItem = subject.first(where: { $0.name == reportItem.subjectName }) {
                let combinedReport = CombinedReport(report: reportItem, subject: subjectItem)
                combinedList.append(combinedReport)
            }
        }
        return combinedList
    }

    var lastSevenDaysReports: [CombinedReport] {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        return combinedReports.filter { $0.date >= sevenDaysAgo }
    }
  
    var body: some View {
        ZStack{
            gradientBackground.ignoresSafeArea()
            NavigationView{
                Chart {
                    ForEach(lastSevenDaysReports, id: \.subjectId) { item in
                        BarMark(
                            x: .value("Date", item.formattedDate), // Using formattedDate here
                            y: .value("Work Time", Double(item.totalTime) / 60)
                        )
                        .foregroundStyle(item.color) // Use the computed color property here
                    }
                    
                }
                .frame(width: 300, height: 300)
                .padding(.all, 0.0)
                .navigationTitle("This week")
                .shadow(radius: 3)
                .cornerRadius(10)
                
            }
        }
    }
}


struct CombinedReport {
    var date: Date
    var subjectName: String
    var totalTime: Int16
    var subjectColor: String
    var subjectId: UUID
    
    var color: Color {
        let defaultRGB = "R:255, G:255, B:255" // White color as default
        let colorString = subjectColor 
        let rgbValues = colorString.split(separator: ",")
            .compactMap { Double($0.split(separator: ":").last?.trimmingCharacters(in: .whitespaces) ?? "0") }
        
        if rgbValues.count == 3 {
            return Color(red: rgbValues[0] / 255, green: rgbValues[1] / 255, blue: rgbValues[2] / 255)
        } else {
            return Color.white // Fallback color if there's an issue with parsing
        }
    }

    var formattedDate: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d" // Change this format as needed
            return formatter.string(from: date)
        }

    init(report: Report, subject: Subjects) {
        self.date = report.date ?? Date()
        self.subjectName = report.subjectName ?? "None"
        self.totalTime = report.totalTime
        self.subjectColor = subject.color ?? "R:0, G:0, B:0"
        self.subjectId = subject.id ?? UUID()
    }
}


#Preview {
    ReportView()
}

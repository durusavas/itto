//
//  ReportView.swift
//  itto
//
//  Created by Duru SAVAŞ on 19/11/2023.
import SwiftUI
import CoreData
import Charts

// Main View
struct ReportView: View {
    @FetchRequest(sortDescriptors: []) var report: FetchedResults<Report>
    @FetchRequest(sortDescriptors: []) var subject: FetchedResults<Subjects>
    @State private var weekOffset = 0
    
    
    var body: some View {
        NavigationView {
            VStack {
                
                WeeklyChartView(weekOffset: weekOffset, reports: report, subjects: subject)
                
            }
            .navigationTitle(navigationTitle(for: weekOffset))
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button(action: { self.weekOffset -= 1 }) {
                        Image(systemName: "arrow.left")
                    }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: { self.weekOffset += 1 }) {
                        Image(systemName: "arrow.right")
                    }
                    .disabled(weekOffset == 0)
                }
            }
        }
    }
    private func weekRange(offset: Int) -> (Date, Date) {
        let calendar = Calendar(identifier: .gregorian)
        let currentDate = Date()
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: currentDate) else {
            return (currentDate, currentDate)
        }
        
        var startOfWeek = calendar.date(byAdding: .day, value: 7 * offset, to: weekInterval.start)!
        // Check if the startOfWeek is Sunday and adjust
        if calendar.component(.weekday, from: startOfWeek) == 1 {
            startOfWeek = calendar.date(byAdding: .day, value: 1, to: startOfWeek)!
        }
        let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek)!
        
        return (startOfWeek, endOfWeek)
    }
    
    
    private func navigationTitle(for weekOffset: Int) -> String {
        let (startOfWeek, _) = weekRange(offset: weekOffset)
        let endOfWeek = Calendar.current.date(byAdding: .day, value: 6, to: startOfWeek)!
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d" // Day only
        let startString = dateFormatter.string(from: startOfWeek)
        
        dateFormatter.dateFormat = "d MMMM" // Day and full month name
        let endString = dateFormatter.string(from: endOfWeek)
        
        if weekOffset == 0 {
            return "This week"
        } else {
            return "\(startString)-\(endString)"
        }
    }
    
}



// Chart View
struct WeeklyChartView: View {
    var weekOffset: Int
    var reports: FetchedResults<Report>
    var subjects: FetchedResults<Subjects>
    
    @State private var selectedReport: CombinedReport?
    @State private var currentDayOffset = 0
    
    var combinedReports: [CombinedReport] {
        var combinedList: [CombinedReport] = []
        for reportItem in reports {
            if let subjectItem = subjects.first(where: { $0.name == reportItem.subjectName }) {
                let combinedReport = CombinedReport(report: reportItem, subject: subjectItem)
                combinedList.append(combinedReport)
            }
        }
        return combinedList
    }
    
    var body: some View {
        VStack{
            Chart {
                ForEach(daysOfTheWeek(start: weekRange(offset: weekOffset).0), id: \.self) { day in
                    // Filter reports for the specific day
                    let dayReports = combinedReports.filter { Calendar.current.isDate($0.date, inSameDayAs: day) }
                    if dayReports.isEmpty {
                        // No reports for this day, so add a transparent bar to ensure the axis label is shown
                        BarMark(
                            x: .value("Day", day.formattedDay),
                            y: .value("Work Time", 0)
                        )
                        .foregroundStyle(Color.clear)
                    } else {
                        // Create a stack of bars for each report on this day
                        ForEach(dayReports, id: \.subjectId) { report in
                            BarMark(
                                x: .value("Day", day.formattedDay),
                                y: .value("Work Time", Double(report.totalTime) / 60)
                            )
                            .foregroundStyle(report.color)
                            
                        }
                    }
                }
            }
            
            .frame(width: 300, height: 300)
            .padding()
            .padding()
            
            VStack{
                HStack {
                    Button(action: { self.currentDayOffset -= 1 }) {
                        Image(systemName: "arrow.left")
                    }
                    .disabled(currentDayOffset <= 0)
                    Text(formattedDate(currentDate)) // Display the current date here
                    
                    Button(action: { self.currentDayOffset += 1 }) {
                        Image(systemName: "arrow.right")
                    }
                    .disabled(currentDayOffset >= 6)
                }
                List {
                    ForEach(filteredSubjectsForDay(), id: \.subject.id) { subjectWithTotalTime in
                        VStack(alignment: .leading) {
                            HStack {
                                Circle()
                                    .frame(width: 20, height: 20)
                                    .foregroundColor(subjectWithTotalTime.subject.color?.toColor() ?? Color.white)
                                Text(subjectWithTotalTime.subject.name ?? "Unknown")
                                Spacer()
                                Text("\(subjectWithTotalTime.totalTime/60) mins")
                            }

                            // Only add descriptions if they exist
                            if !subjectWithTotalTime.descriptions.isEmpty {
                                ForEach(subjectWithTotalTime.descriptions, id: \.self) { description in
                                    Text(description)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                }



                
            }
            
        }
        
        
    }
    
    private var currentDate: Date {
        let startOfWeek = weekRange(offset: weekOffset).0
        return Calendar.current.date(byAdding: .day, value: currentDayOffset, to: startOfWeek) ?? Date()
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, MMM d"
        return formatter.string(from: date)
    }
    
    private func filteredSubjectsForDay() -> [SubjectWithTotalTime] {
        let currentDate = daysOfTheWeek(start: weekRange(offset: weekOffset).0)[currentDayOffset]
        let currentDayReports = combinedReports.filter { Calendar.current.isDate($0.date, inSameDayAs: currentDate) }

        return subjects.flatMap { subject -> [SubjectWithTotalTime] in
            guard let subjectName = subject.name else { return [] }
            let subjectReports = currentDayReports.filter { $0.subjectName == subjectName }
            let totalMinutes = subjectReports.map { Int($0.totalTime) }.reduce(0, +)
            let descriptions = subjectReports.map { $0.reportDescription }
            if totalMinutes > 0 {
                return [SubjectWithTotalTime(subject: subject, totalTime: totalMinutes, descriptions: descriptions)]
            } else {
                return []
            }
        }
    }




    
    
    private func weekRange(offset: Int) -> (Date, Date) {
        let calendar = Calendar(identifier: .gregorian)
        let currentDate = Date()
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: currentDate) else {
            return (currentDate, currentDate)
        }
        
        var startOfWeek = calendar.date(byAdding: .day, value: 7 * offset, to: weekInterval.start)!
        // Check if the startOfWeek is Sunday and adjust
        if calendar.component(.weekday, from: startOfWeek) == 1 {
            startOfWeek = calendar.date(byAdding: .day, value: 1, to: startOfWeek)!
        }
        let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek)!
        
        return (startOfWeek, endOfWeek)
    }
    
    
    private func daysOfTheWeek(start: Date) -> [Date] {
        let calendar = Calendar(identifier: .gregorian)
        var days = [Date]()
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: i, to: start) {
                days.append(date)
            }
        }
        return days
    }
    
}
struct SubjectWithTotalTime {
    let subject: Subjects
    let totalTime: Int
    let descriptions: [String]
}

// Combined Report Struct
struct CombinedReport {
    var date: Date
    var subjectName: String
    var totalTime: Int16
    var subjectColor: String
    var subjectId: UUID
    var reportDescription: String
    
    var color: Color {
        let colorString = subjectColor
        let rgbValues = colorString.split(separator: ",")
            .compactMap { Double($0.split(separator: ":").last?.trimmingCharacters(in: .whitespaces) ?? "0") }
        if rgbValues.count == 3 {
            return Color(red: rgbValues[0] / 255, green: rgbValues[1] / 255, blue: rgbValues[2] / 255)
        } else {
            return Color.white
        }
    }
    
    init(report: Report, subject: Subjects) {
        self.date = report.date ?? Date()
        self.subjectName = report.subjectName ?? "None"
        self.totalTime = report.totalTime
        self.subjectColor = subject.color ?? "R:0, G:0, B:0"
        self.subjectId = subject.id ?? UUID()
        self.reportDescription = report.desc ?? ""
    }
    static func totalTimeForSubject(_ subjectName: String, in reports: [CombinedReport]) -> Int {
        return reports.filter { $0.subjectName == subjectName }
            .map { Int($0.totalTime) }
            .reduce(0, +)
    }
}

// Date Extension
extension Date {
    var formattedDay: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E" // Day of the week, e.g., "Mon", "Tue", etc.
        return formatter.string(from: self)
    }
}

/* Preview
 struct ReportView_Previews: PreviewProvider {
 static var previews: some View {
 ReportView()
 }
 }
 */


#Preview {
    ReportView()
}

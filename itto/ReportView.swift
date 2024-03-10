//
//  ReportView.swift
//  itto
//
//  Created by Duru SAVAŞ on 19/11/2023.
// ReportView.swift
// itto
//
// Created by Duru SAVAŞ on 19/11/2023.
import SwiftUI
import CoreData
import Charts


struct WeeklyChartView: View {
    var weekOffset: Int
    var reports: FetchedResults<Report>
    var subjects: FetchedResults<Subjects>
    var projects: FetchedResults<Projects>

    @State private var selectedReport: CombinedReport?
    @State private var currentDayOffset = 0

    var combinedReports: [CombinedReport] {
        var combinedList: [CombinedReport] = []
        for reportItem in reports {
            if let subjectItem = subjects.first(where: { $0.name == reportItem.subjectName }) {
                let combinedReport = CombinedReport(report: reportItem, subject: subjectItem)
                combinedList.append(combinedReport)
            } else if let projectItem = projects.first(where: { $0.name == reportItem.subjectName }) {
                let combinedReport = CombinedReport(report: reportItem, project: projectItem)
                combinedList.append(combinedReport)
            }
        }
        return combinedList
    }

    var body: some View {
        VStack {
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



struct ReportView: View {
    @FetchRequest(sortDescriptors: []) var report: FetchedResults<Report>
    @FetchRequest(sortDescriptors: []) var subject: FetchedResults<Subjects>
    @FetchRequest(sortDescriptors: []) var project: FetchedResults<Projects>
    @State private var weekOffset = 0

    var body: some View {
        NavigationView {
           
                VStack {
                    WeeklyChartView(weekOffset: weekOffset, reports: report, subjects: subject, projects: project)
                    DailyListView(weekOffset: weekOffset, reports: report, subjects: subject, projects: project)
                        .frame(maxWidth: .infinity)
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
        .onAppear {
                   printReportData(report, subject, project)
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
    func printReportData(_ reports: FetchedResults<Report>, _ subjects: FetchedResults<Subjects>, _ projects: FetchedResults<Projects>) {
        print("Report Data:")
        for report in reports {
            print("Date: \(report.date ?? Date())")
            print("Description: \(report.desc ?? "No description")")
            print("Subject Name: \(report.subjectName ?? "No subject name")")
            print("Total Time: \(report.totalTime) minutes")
            
            if let subject = subjects.first(where: { $0.name == report.subjectName }) {
                print("Subject Color: \(subject.color ?? "No color")")
            }
            
            if let project = projects.first(where: { $0.name == report.subjectName }) {
                print("Project Color: \(project.color ?? "No color")")
            }
            
            print("---")
        }
    }
}

struct DailyListView: View {
    var weekOffset: Int
    var reports: FetchedResults<Report>
    var subjects: FetchedResults<Subjects>
    var projects: FetchedResults<Projects>

    @State private var currentDayOffset = 0

    var body: some View {
        VStack {
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
                ForEach(filteredItemsForDay(), id: \.id) { ItemWithTotalTime in
                    VStack(alignment: .leading) {
                        HStack {
                            Circle()
                                .frame(width: 20, height: 20)
                                .foregroundColor(ItemWithTotalTime.color.toColor())
                            Text(ItemWithTotalTime.name)
                            Spacer()
                            Text("\(ItemWithTotalTime.totalTime/60) mins")
                        }

                        // Only add descriptions if they exist
                        if !ItemWithTotalTime.descriptions.isEmpty {
                            ForEach(ItemWithTotalTime.descriptions, id: \.self) { description in
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
    var combinedReports: [CombinedReport] {
        var combinedList: [CombinedReport] = []
        for reportItem in reports {
            if let subjectItem = subjects.first(where: { $0.name == reportItem.subjectName }) {
                let combinedReport = CombinedReport(report: reportItem, subject: subjectItem)
                combinedList.append(combinedReport)
            } else if let projectItem = projects.first(where: { $0.name == reportItem.subjectName }) {
                let combinedReport = CombinedReport(report: reportItem, project: projectItem)
                combinedList.append(combinedReport)
            }
        }
        return combinedList
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

    private func filteredItemsForDay() -> [ItemWithTotalTime] {
        let currentDate = daysOfTheWeek(start: weekRange(offset: weekOffset).0)[currentDayOffset]
        let currentDayReports = combinedReports.filter { Calendar.current.isDate($0.date, inSameDayAs: currentDate) }

        // Create a dictionary to hold combined data for both subjects and projects
        var combinedItems = [String: ItemWithTotalTime]()

        // Process reports to aggregate information
        for report in currentDayReports {
            let itemName = report.subjectName
            let itemID = report.subjectId
            let itemColor = report.subjectColor
            let itemTime = Int(report.totalTime)
            let itemDescription = report.reportDescription

            if let existingItem = combinedItems[itemName] {
                // Update existing item with new time and descriptions
                let updatedTime = existingItem.totalTime + itemTime
                let updatedDescriptions = existingItem.descriptions + [itemDescription]
                combinedItems[itemName] = ItemWithTotalTime(name: itemName, color: itemColor, totalTime: updatedTime, descriptions: updatedDescriptions, id: itemID)
            } else {
                // Add new item
                combinedItems[itemName] = ItemWithTotalTime(name: itemName, color: itemColor, totalTime: itemTime, descriptions: [itemDescription], id: itemID)
            }
        }

        return Array(combinedItems.values)
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

struct ItemWithTotalTime {
    let name: String
    let color: String
    let totalTime: Int
    let descriptions: [String]
    let id: UUID // Ensure each item can be uniquely identified, as needed
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
    
 

    init(report: Report, project: Projects) {
        self.date = report.date ?? Date()
        self.subjectName = report.subjectName ?? "None"
        self.totalTime = report.totalTime
        self.subjectColor = project.color ?? "R:0, G:0, B:0"
        self.subjectId = project.id ?? UUID()
        self.reportDescription = report.desc ?? ""
    }

    static func totalTimeForSubject(_ subjectName: String, in reports: [CombinedReport]) -> Int {
        return reports.filter { $0.subjectName == subjectName }
            .map { Int($0.totalTime) }
            .reduce(0, +)
    }
}

extension Date {
    var formattedDay: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E" // Day of the week, e.g., "Mon", "Tue", etc.
        return formatter.string(from: self)
    }
}

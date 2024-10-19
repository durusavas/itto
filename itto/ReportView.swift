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

struct ReportView: View {
    @FetchRequest(sortDescriptors: []) var reports: FetchedResults<Report>
    @FetchRequest(sortDescriptors: []) var subjects: FetchedResults<Subjects>
    @FetchRequest(sortDescriptors: []) var projects: FetchedResults<Projects>
    @State private var weekOffset = 0
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
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color("bg2"), Color("bg1")]),
                    startPoint: .center,
                    endPoint: .topTrailing
                )
                .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    Chart {
                        ForEach(daysOfTheWeek(start: weekRange(offset: weekOffset).0), id: \.self) { day in
                            let dayReports = combinedReports.filter { Calendar.current.isDate($0.date, inSameDayAs: day) }
                            if dayReports.isEmpty {
                                BarMark(
                                    x: .value("Day", day.formattedDay),
                                    y: .value("Work Time", 0)
                                )
                                .foregroundStyle(Color.clear)
                            } else {
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
                    HStack(spacing: 10) {
                        Button(action: { self.currentDayOffset -= 1 }) {
                            Image(systemName: "arrow.left")
                        }
                        .disabled(currentDayOffset <= 0)
                        
                        Text(formattedDate(currentDate))
                            .font(.custom("Poppins-Regular", size: 20))
                        
                        Button(action: { self.currentDayOffset += 1 }) {
                            Image(systemName: "arrow.right")
                        }
                        .disabled(currentDayOffset >= 6)
                    }
                    
                    List {
                        ForEach(filteredItemsForDay(), id: \.id) { item in
                            VStack(alignment: .leading) {
                                HStack {
                                    GradientCircleView(baseColor: item.color.toColor())
                                        .frame(width: 17, height: 17)
                                    
                                    Text(item.name)
                                        .font(.custom("Poppins-Regular", size: 16))
                                    
                                    Spacer()
                                    
                                    Text("\(item.totalTime / 60) \(NSLocalizedString("minutes", comment: ""))")
                                        .font(.custom("Poppins-Regular", size: 16))
                                    
                                }
                                
                                if !item.descriptions.isEmpty {
                                    ForEach(item.descriptions, id: \.self) { description in
                                        Text(description)
                                            .font(.custom("Poppins-Regular", size: 14))
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                        .listRowBackground(Color.gray.opacity(0.1))
                    }
                    .scrollContentBackground(.hidden)
                }
                .padding(.bottom, 70)
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(navigationTitle(for: weekOffset))
                        .font(.custom("Poppins-Regular", size: 23))
                }
                
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
            let calendar = Calendar(identifier: .gregorian)
            let today = Date()
            let startOfWeek = weekRange(offset: weekOffset).0
            let daysOffset = calendar.dateComponents([.day], from: startOfWeek, to: today).day ?? 0
            currentDayOffset = daysOffset
        }
    }
    
    private var currentDate: Date {
        let startOfWeek = weekRange(offset: weekOffset).0
        return Calendar.current.date(byAdding: .day, value: currentDayOffset, to: startOfWeek) ?? Date()
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, d" 
        return formatter.string(from: date)
    }
    
    private func filteredItemsForDay() -> [ItemWithTotalTime] {
        let days = daysOfTheWeek(start: weekRange(offset: weekOffset).0)
        guard currentDayOffset >= 0 && currentDayOffset < days.count else {
            return []
        }
        
        let currentDate = days[currentDayOffset]
        let currentDayReports = combinedReports.filter { Calendar.current.isDate($0.date, inSameDayAs: currentDate) }
        
        var combinedItems = [String: ItemWithTotalTime]()
        
        for report in currentDayReports {
            let itemName = report.subjectName
            let itemID = report.subjectId
            let itemColor = report.subjectColor
            let itemTime = Int(report.totalTime)
            let itemDescription = report.reportDescription
            
            if let existingItem = combinedItems[itemName] {
                let updatedTime = existingItem.totalTime + itemTime
                let updatedDescriptions = existingItem.descriptions + [itemDescription]
                combinedItems[itemName] = ItemWithTotalTime(name: itemName, color: itemColor, totalTime: updatedTime, descriptions: updatedDescriptions, id: itemID)
            } else {
                combinedItems[itemName] = ItemWithTotalTime(name: itemName, color: itemColor, totalTime: itemTime, descriptions: [itemDescription], id: itemID)
            }
        }
        
        return Array(combinedItems.values)
    }
    
    private func navigationTitle(for weekOffset: Int) -> String {
        let (startOfWeek, _) = weekRange(offset: weekOffset)
        let endOfWeek = Calendar.current.date(byAdding: .day, value: 6, to: startOfWeek)!
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d"
        let startString = dateFormatter.string(from: startOfWeek)
        
        dateFormatter.dateFormat = "d MMMM"
        let endString = dateFormatter.string(from: endOfWeek)
        
        return weekOffset == 0 ? NSLocalizedString("this_week", comment: "This week") : "\(startString)-\(endString)"
    }
    
    private func weekRange(offset: Int) -> (Date, Date) {
        let calendar = Calendar(identifier: .gregorian)
        let currentDate = Date()
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: currentDate) else {
            return (currentDate, currentDate)
        }
        
        var startOfWeek = calendar.date(byAdding: .day, value: 7 * offset, to: weekInterval.start)!
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
    let id: UUID
}

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
}

extension Date {
    var formattedDay: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: self)
    }
}


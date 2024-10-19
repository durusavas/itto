//
//  DataController.swift
//  itto
//
//  Created by Duru SAVAŞ on 17/11/2023.
//

import Foundation
import CoreData
import SwiftUI

class DataController: ObservableObject {
    let container = NSPersistentContainer(name: "Itto")
    
    init() {
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Core data load has failed \(error.localizedDescription)")
                return
            }
            self.container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
//            self.deleteAllData(entity: "Report")
//           self.deleteAllData(entity: "Subjects")
//           self.deleteAllData(entity: "DailySubjects")
//           self.deleteAllData(entity: "Exams")
//            self.deleteAllData(entity: "Projects")
//            self.populateDemoData()
        }
    }
    
    func deleteAllData(entity: String) {
        let context = container.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
        fetchRequest.returnsObjectsAsFaults = false
        
        do {
            let results = try context.fetch(fetchRequest)
            for object in results {
                guard let objectData = object as? NSManagedObject else { continue }
                context.delete(objectData)
            }
            try context.save()
        } catch let error {
            print("Delete all data in \(entity) error: \(error)")
        }
    }
    
    // MARK: DEMO DATA
//    private func getNextDate(for day: Weekday) -> Date? {
//        let today = Date()
//        let calendar = Calendar.current
//        
//        if let nextWeekday = calendar.date(bySetting: .weekday, value: day.weekdayIndex, of: today) {
//            if nextWeekday < today {
//                return calendar.date(byAdding: .weekOfYear, value: 1, to: nextWeekday)
//            } else {
//                return nextWeekday
//            }
//        }
//        return nil
//    }
    
//    func populateDemoData() {
//        let context = container.viewContext
//        
//        let subjectsData: [(name: String, color: String, days: [Weekday])] = [
//            ("Introduction to Computer Science", "R:204, G:0, B:102", [.monday, .wednesday]),
//            ("Data Structures and Algorithms", "R:255, G:110, B:64", [.tuesday, .thursday]),
//            ("Operating Systems", "R:180, G:0, B:255", [.wednesday, .friday]),
//            ("Computer Networks", "R:64, G:0, B:255", [.monday, .thursday]),
//            ("Database System", "R:255, G:64, B:255", [.tuesday, .friday]),
//            ("Software Engineering", "R:0, G:170, B:255", [.wednesday]),
//            ("Artificial Intelligence", "R:255, G:53, B:0", [.thursday, .saturday]),
//        ]
//        
//        for subjectData in subjectsData {
//            let newSubject = Subjects(context: context)
//            newSubject.id = UUID()
//            newSubject.name = subjectData.name
//            newSubject.color = subjectData.color
//            newSubject.days = subjectData.days.map { $0.rawValue } as NSObject
//            
//            
//            for day in subjectData.days {
//                if let dateForDay = getNextDate(for: day) {
//                    let dailySubject = DailySubjects(context: context)
//                    dailySubject.subjectName = subjectData.name
//                    dailySubject.category = "Class"
//                    dailySubject.date = dateForDay
//                    dailySubject.isCompleted = false
//                    dailySubject.color = subjectData.color
//                }
//            }
//        }
//        
//        let projectsData: [(name: String, color: String, topics: [String])] = [
//            ("Intro Project", "R:204, G:0, B:102", ["Task1", "Task2"]),
//            ("DSA Project", "R:255, G:110, B:64", ["Task 11"]),
//            ("OS Project", "R:180, G:0, B:255", ["Task 12"]),
//            ("Networks Project", "R:64, G:0, B:255", ["Task123"])
//        ]
//        for projectData in projectsData {
//            let newProject = Projects(context: context)
//            newProject.id = UUID()
//            newProject.name = projectData.name
//            newProject.color = projectData.color
//            newProject.topics = projectData.topics as NSObject
//            
//            let dailySubject = DailySubjects(context: context)
//            dailySubject.category = "Project"
//            dailySubject.subjectName = projectData.name
//            dailySubject.date = Date()
//            dailySubject.isCompleted = false
//            dailySubject.topics = projectData.topics as NSObject
//            dailySubject.color = projectData.color
//        }
//        
//        let examsData: [(name: String, color: String, examName: String, topics: [String])] = [
//            ("Database System", "R:255, G:64, B:255", "Database System Exam", ["Relational Database Management Systems", "SQL Queries", "Normalization"]),
//            ("Software Engineering", "R:0, G:170, B:255", "Software Engineering Exam", ["Software Development Life Cycle", "Agile Methodology"]),
//        ]
//        
//        for examData in examsData {
//            let exam = Exams(context: context)
//            exam.color = examData.color
//            exam.examName = examData.examName
//            exam.id = UUID()
//            exam.name = examData.name
//            exam.topics = examData.topics as NSObject
//            
//            let dailySubject = DailySubjects(context: context)
//            dailySubject.category = "Exam"
//            dailySubject.subjectName = examData.examName
//            dailySubject.date = Date()
//            dailySubject.isCompleted = false
//            dailySubject.topics = examData.topics as NSObject
//            dailySubject.color = examData.color
//        }
//        
//        generateDemoReports(for: subjectsData, context: context)
//        
//        do {
//            try context.save()
//        } catch {
//            print("Failed to load or save demo data: \(error.localizedDescription)")
//        }
//    }
    
//    // MARK: Generate Demo Reports
//    private func generateDemoReports(for subjectsData: [(name: String, color: String, days: [Weekday])], context: NSManagedObjectContext) {
//        
//        guard let currentWeekStart = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) else {
//            fatalError("Failed to calculate the start date of the current week.")
//        }
//        
//        guard let startDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: currentWeekStart) else {
//            fatalError("Failed to calculate the start date of the past week.")
//        }
//        
//        for subjectData in subjectsData {
//            for i in 0..<7 {
//                
//                guard let currentDate = Calendar.current.date(byAdding: .day, value: i, to: startDate) else {
//                    fatalError("Failed to calculate the current date for the past week.")
//                }
//                
//                let totalTime = Int.random(in: 1...240)
//                
//                let report = Report(context: context)
//                report.date = currentDate
//                report.desc = "Demo Report for \(subjectData.name)"
//                report.subjectName = subjectData.name
//                report.totalTime = Int16(totalTime)
//                
//            }
//        }
//    }
}

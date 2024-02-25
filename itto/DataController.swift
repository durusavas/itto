//
//  DataController.swift
//  itto
//
//  Created by Duru SAVAŞ on 17/11/2023.
//
import Foundation
import CoreData

class DataController: ObservableObject {
    let container = NSPersistentContainer(name: "Itto")
    init() {
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Core data load has failed \(error.localizedDescription)")
                return
            }
            self.container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
            self.deleteAllData(entity: "Report")
            self.deleteAllData(entity: "Subjects")
            self.deleteAllData(entity: "DailySubjects")
            self.deleteAllData(entity: "Exams")
            self.deleteAllData(entity: "Projects")
           self.populateDemoData()
        }
    }
    
    
    func deleteAllData(entity: String) {
        let context = container.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
        fetchRequest.returnsObjectsAsFaults = false
        
        do {
            let results = try context.fetch(fetchRequest)
            for object in results {
                guard let objectData = object as? NSManagedObject else {continue}
                context.delete(objectData)
            }
            try context.save()
        } catch let error {
            print("Detele all data in \(entity) error :", error)
        }
    }
    
    
    // MARK: DEMO DATA
    private func getNextDate(for day: Weekday) -> Date? {
        let today = Date()
        let calendar = Calendar.current
        
        // Find the next date for the given day
        if let nextWeekday = calendar.date(bySetting: .weekday, value: day.weekdayIndex, of: today) {
            if nextWeekday < today {
                return calendar.date(byAdding: .weekOfYear, value: 1, to: nextWeekday)
            } else {
                return nextWeekday
            }
        }
        
        return nil
    }
    
    func populateDemoData() {
        let context = container.viewContext
        // Check if the data already exists to avoid duplicates
        // let subjectRequest: NSFetchRequest<Subjects> = Subjects.fetchRequest()
        //let projectRequest: NSFetchRequest<Projects> = Projects.fetchRequest()
        //let examRequest: NSFetchRequest<Exams> = Exams.fetchRequest()
        do {
                // Creating demo Subjects
                let subjectsData: [(name: String, color: String, days: [Weekday])] = [
                    ("Introduction to Computer Science", "R:204, G:0, B:102", [.monday, .wednesday]),
                    ("Data Structures and Algorithms", "R:255, G:110, B:64", [.tuesday, .thursday]),
                    ("Operating Systems", "R:180, G:0, B:255", [.wednesday, .friday]),
                    ("Computer Networks", "R:64, G:0, B:255", [.monday, .thursday]),
                    ("Database System", "R:255, G:64, B:255", [.tuesday, .friday]),
                    ("Software Engineering", "R:0, G:170, B:255", [.wednesday]),
                    ("Artificial Intelligence", "R:255, G:53, B:0", [.thursday, .saturday]),
                ]
                
                for subjectData in subjectsData {
                    let newSubject = Subjects(context: context)
                    newSubject.id = UUID()
                    newSubject.name = subjectData.name
                    newSubject.color = subjectData.color
                    newSubject.days = subjectData.days.map { $0.rawValue } as NSObject
                    
                    // Convert selected weekdays to actual dates and create DailySubjects
                    for day in subjectData.days {
                        if let dateForDay = getNextDate(for: day) {
                            let dailySubject = DailySubjects(context: context)
                            dailySubject.subjectName = subjectData.name
                            dailySubject.category = "Class"
                            dailySubject.date = dateForDay
                            dailySubject.isCompleted = false
                        }
                    }
                }
                
                // Creating demo Projects
                let projectsData: [(name: String, color: String, desc: [String])] = [
                    ("Intro Project", "R:204, G:0, B:102", [""]),
                    ("DSA Project", "R:255, G:110, B:64", [""]),
                    ("OS Project", "R:180, G:0, B:255", [""]),
                    ("Networks Project", "R:64, G:0, B:255", [""])
                ]
                for projectData in projectsData {
                    let newProject = Projects(context: context)
                    newProject.id = UUID()
                    newProject.name = projectData.name
                    newProject.color = projectData.color
                    
                    // Create DailySubjects for each project (category: "Project")
                    let dailySubject = DailySubjects(context: context)
                    dailySubject.category = "Project"
                    dailySubject.subjectName = projectData.name
                    dailySubject.date = Date() // Set the date as needed for projects
                    dailySubject.isCompleted = false
                }
                
                // Creating demo Exams
                let examsData: [(name: String, color: String, examName: String, topics: [String])] = [
                    ("Database System", "R:255, G:64, B:255", "Database System Exam", ["Relational Database Management Systems", "SQL Queries", "Normalization"]),
                    ("Software Engineering", "R:0, G:170, B:255", "Software Engineering Exam", ["Software Development Life Cycle", "Agile Methodology"]),
                 
                ]
                
                // Create Exams manually
                for examData in examsData {
                    let exam = Exams(context: context)
                    exam.color = examData.color
                    exam.examName = examData.examName
                    exam.id = UUID()
                    exam.name = examData.name
                    exam.topics = examData.topics as NSObject
                    
                    // Create DailySubjects for each exam (category: "Exam")
                    let dailySubject = DailySubjects(context: context)
                    dailySubject.category = "Exam"
                    dailySubject.subjectName = examData.name
                    dailySubject.date = Date() // Set the date as needed for exams
                    dailySubject.isCompleted = false
                    dailySubject.topics = examData.topics as NSObject
                }
            // Get the start date of the current week
                   guard let currentWeekStart = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) else {
                       fatalError("Failed to calculate the start date of the current week.")
                   }
                   
                   // Adjust to the previous week's Monday
                   guard let startDate = Calendar.current.date(byAdding: .day, value: 1, to: currentWeekStart) else {
                       fatalError("Failed to calculate the start date of the past week.")
                   }
                   
                   // Adjust to the previous week's Sunday
            guard Calendar.current.date(byAdding: .day, value: 6, to: currentWeekStart) != nil else {
                       fatalError("Failed to calculate the end date of the past week.")
                   }
                   
                   // Iterate over subjects and add reports for each subject for each day of the past week
                   for subjectData in subjectsData {
                       for i in 0..<7 {
                           // Calculate the date for the current day in the past week
                           guard let currentDate = Calendar.current.date(byAdding: .day, value: i, to: startDate) else {
                               fatalError("Failed to calculate the current date for the past week.")
                           }
                           
                           // Generate a random total time for demonstration purposes
                           let totalTime = Int.random(in: 1...240) // Random time between 1 minute and 4 hours
                           
                           // Create Report entity for the current day
                           let report = Report(context: context)
                           report.date = currentDate
                           report.desc = "Demo Description"
                           report.subjectName = subjectData.name
                           report.totalTime = Int16(totalTime)
                         
                       }
                   }
                   
                  

                
                try context.save()
            } catch {
                print("Failed to load or save demo data: \(error.localizedDescription)")
            }
    }
}

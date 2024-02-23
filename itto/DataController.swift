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
           // self.deleteAllData(entity: "Report")
           // self.deleteAllData(entity: "Subjects")
            //self.deleteAllData(entity: "DailySubjects")
           // self.deleteAllData(entity: "Exams")
            //self.deleteAllData(entity: "Projects")
           
          // self.populateDemoData()
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
        deleteAllData(entity: "Subjects")
        deleteAllData(entity: "DailySubjects")
        let context = container.viewContext
        
        // Check if the data already exists to avoid duplicates
        let subjectRequest: NSFetchRequest<Subjects> = Subjects.fetchRequest()
        
        do {
            let subjectsCount = try context.count(for: subjectRequest)
            if subjectsCount == 0 {
                // Creating demo Subjects
                
                let subjectsData: [(name: String, color: String, days: [Weekday])] = [
                    ("Introduction to Computer Science", "R:204, G:0, B:102", [.monday, .wednesday]),
                    ("Data Structures and Algorithms", "R:255, G:110, B:64", [.tuesday, .thursday]),
                    ("Operating Systems", "R:180, G:0, B:255", [.wednesday, .friday]),
                    ("Computer Networks", "R:64, G:0, B:255", [.monday, .thursday]),
                    ("Database System", "R:255, G:64, B:255", [.tuesday, .friday]),
                    ("Software Engineering", "R:0, G:170, B:255", [.wednesday]),
                    ("Artificial Intelligence", "R:255, G:53, B:0", [.thursday, .saturday]),
                    ("Artificial Intelligence", "R:255, G:53, B:0", [])
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
                            dailySubject.date = dateForDay
                            dailySubject.isCompleted = false
                        }
                    }
                }
            }
            
            try context.save()
        } catch {
            print("Failed to load or save demo data: \(error.localizedDescription)")
        }
    }

    
}

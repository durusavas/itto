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
            
            // Populate the demo data
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
    
    func populateDemoData() {
        deleteAllData(entity: "Subjects")
                deleteAllData(entity: "Report")
        let context = container.viewContext
        
        // Check if the data already exists to avoid duplicates
        let subjectRequest: NSFetchRequest<Subjects> = Subjects.fetchRequest()
        let reportRequest: NSFetchRequest<Report> = Report.fetchRequest()
        
        do {
            
            let subjectsCount = try context.count(for: subjectRequest)
            let reportsCount = try context.count(for: reportRequest)
            if subjectsCount == 0{
                // Creating demo Subjects
                let subject1 = Subjects(context: context)
                subject1.color = "R:204, G:0, B:102" // Neon pink
                subject1.id = UUID()
                subject1.name = "Introduction to Computer Science"

                let subject2 = Subjects(context: context)
                subject2.color = "R:255, G:110, B:64" // Neon orange
                subject2.id = UUID()
                subject2.name = "Data Structures and Algorithms"

                let subject3 = Subjects(context: context)
                subject3.color = "R:180, G:0, B:255" // Neon purple
                subject3.id = UUID()
                subject3.name = "Operating Systems"

                let subject4 = Subjects(context: context)
                subject4.color = "R:64, G:0, B:255" // Neon blue
                subject4.id = UUID()
                subject4.name = "Computer Networks"

                let subject5 = Subjects(context: context)
                subject5.color = "R:255, G:64, B:255" // Neon magenta
                subject5.id = UUID()
                subject5.name = "Database System"

                let subject6 = Subjects(context: context)
                subject6.color = "R:0, G:170, B:255" // Neon sky blue
                subject6.id = UUID()
                subject6.name = "Software Engineering"

                let subject7 = Subjects(context: context)
                subject7.color = "R:255, G:53, B:0" // Neon red
                subject7.id = UUID()
                subject7.name = "Artificial Intelligence"


            }
            if reportsCount == 0{
                // Creating demo Reports
                // Day 1 Reports
                let report1 = Report(context: context)
                report1.date = Calendar.current.date(byAdding: .day, value: -1, to: Date())
                report1.subjectName = "Artificial Intelligence"
                report1.totalTime = 60 * 60
                report1.desc = "Study session 1"

                let report2 = Report(context: context)
                report2.date = Calendar.current.date(byAdding: .day, value: -1, to: Date())
                report2.subjectName = "Software Engineering"
                report2.totalTime = 45 * 60
                report2.desc = "Study session 2"

                let report3 = Report(context: context)
                report3.date = Calendar.current.date(byAdding: .day, value: -1, to: Date())
                report3.subjectName = "Database System"
                report3.totalTime = 30 * 60
                report3.desc = "Study session 3"

                // Day 2 Reports
                let report4 = Report(context: context)
                report4.date = Calendar.current.date(byAdding: .day, value: -2, to: Date())
                report4.subjectName = "Data Structures and Algorithms"
                report4.totalTime = 50 * 60
                report4.desc = "Study session 4"

                let report5 = Report(context: context)
                report5.date = Calendar.current.date(byAdding: .day, value: -2, to: Date())
                report5.subjectName = "Artificial Intelligence"
                report5.totalTime = 35 * 60
                report5.desc = "Study session 5"

                let report6 = Report(context: context)
                report6.date = Calendar.current.date(byAdding: .day, value: -2, to: Date())
                report6.subjectName = "Introduction to Computer Science"
                report6.totalTime = 40 * 60
                report6.desc = "Study session 6"

                // Day 4 Reports
                let report7 = Report(context: context)
                report7.date = Calendar.current.date(byAdding: .day, value: -4, to: Date())
                report7.subjectName = "Data Structures and Algorithms"
                report7.totalTime = 50 * 60
                report7.desc = "Study session 7"

                let report8 = Report(context: context)
                report8.date = Calendar.current.date(byAdding: .day, value: -4, to: Date())
                report8.subjectName = "Artificial Intelligence"
                report8.totalTime = 35 * 60
                report8.desc = "Study session 8"

                let report9 = Report(context: context)
                report9.date = Calendar.current.date(byAdding: .day, value: -4, to: Date())
                report9.subjectName = "Introduction to Computer Science"
                report9.totalTime = 40 * 60
                report9.desc = "Study session 9"

                // Day 3 Reports
                let report10 = Report(context: context)
                report10.date = Calendar.current.date(byAdding: .day, value: 0, to: Date())
                report10.subjectName = "Computer Networks"
                report10.totalTime = 60 * 60
                report10.desc = "Study session 10"

                let report11 = Report(context: context)
                report11.date = Calendar.current.date(byAdding: .day, value: 0, to: Date())
                report11.subjectName = "Data Structures and Algorithms"
                report11.totalTime = 45 * 60
                report11.desc = "Study session 11"

                let report12 = Report(context: context)
                report12.date = Calendar.current.date(byAdding: .day, value: 0, to: Date())
                report12.subjectName = "Software Engineering"
                report12.totalTime = 30 * 60
                report12.desc = "Study session 12"

                // Day 5 Reports
                let report13 = Report(context: context)
                report13.date = Calendar.current.date(byAdding: .day, value: 2, to: Date())
                report13.subjectName = "Database Systems"
                report13.totalTime = 60 * 60
                report13.desc = "Study session 13"

                let report14 = Report(context: context)
                report14.date = Calendar.current.date(byAdding: .day, value: 2, to: Date())
                report14.subjectName = "Introduction to Computer Science"
                report14.totalTime = 45 * 60

                let report15 = Report(context: context)
                report15.date = Calendar.current.date(byAdding: .day, value: 2, to: Date())
                report15.subjectName = "Artificial Intelligence"
                report15.totalTime = 30 * 60 // Multiplied by 60
                report15.desc = "Study session 12"

                // Day 6 Reports
                let report16 = Report(context: context)
                report16.date = Calendar.current.date(byAdding: .day, value: 1, to: Date())
                report16.subjectName = "Operating Systems"
                report16.totalTime = 60 * 60 // Multiplied by 60
                report16.desc = "Study session 13"

                let report17 = Report(context: context)
                report17.date = Calendar.current.date(byAdding: .day, value: 1, to: Date())
                report17.subjectName = "Computer Networks"
                report17.totalTime = 45 * 60 // Multiplied by 60
                report17.desc = "Study session 14"

                let report18 = Report(context: context)
                report18.date = Calendar.current.date(byAdding: .day, value: 1, to: Date())
                report18.subjectName = "Data Structures and Algorithms"
                report18.totalTime = 30 * 60 // Multiplied by 60
                report18.desc = "Study session 15"

                // Day with value -3 Reports
                let report19 = Report(context: context)
                report19.date = Calendar.current.date(byAdding: .day, value: -3, to: Date())
                report19.subjectName = "Software Engineering"
                report19.totalTime = 50 * 60 // Multiplied by 60
                report19.desc = "Study session 16"

                let report20 = Report(context: context)
                report20.date = Calendar.current.date(byAdding: .day, value: -3, to: Date())
                report20.subjectName = "Artificial Intelligence"
                report20.totalTime = 40 * 60 // Multiplied by 60
                report20.desc = "Study session 17"

                let report21 = Report(context: context)
                report21.date = Calendar.current.date(byAdding: .day, value: -3, to: Date())
                report21.subjectName = "Database Systems"
                report21.totalTime = 45 * 60 // Multiplied by 60
                report21.desc = "Study session 18"

                // Day with value 3 Reports
                let report22 = Report(context: context)
                report22.date = Calendar.current.date(byAdding: .day, value: 3, to: Date())
                report22.subjectName = "Introduction to Computer Science"
                report22.totalTime = 55 * 60 // Multiplied by 60
                report22.desc = "Study session 19"

                let report23 = Report(context: context)
                report23.date = Calendar.current.date(byAdding: .day, value: 3, to: Date())
                report23.subjectName = "Operating Systems"
                report23.totalTime = 35 * 60 // Multiplied by 60
                report23.desc = "Study session 20"

                let report24 = Report(context: context)
                report24.date = Calendar.current.date(byAdding: .day, value: 3, to: Date())
                report24.subjectName = "Computer Networks"
                report24.totalTime = 60 * 60 // Multiplied by 60
                report24.desc = "Study session 21"

                let report25 = Report(context: context)
                report25.date = Calendar.current.date(byAdding: .day, value: -5, to: Date())
                report25.subjectName = "Artificial Intelligence"
                report25.totalTime = 60 * 60
                report25.desc = "Study session 1"

                let report26 = Report(context: context)
                report26.date = Calendar.current.date(byAdding: .day, value: -5, to: Date())
                report26.subjectName = "Software Engineering"
                report26.totalTime = 45 * 60
                report26.desc = "Study session 2"

                let report27 = Report(context: context)
                report27.date = Calendar.current.date(byAdding: .day, value: -5, to: Date())
                report27.subjectName = "Database System"
                report27.totalTime = 30 * 60
                report27.desc = "Study session 3"

          


           
            }
            
            if subjectsCount == 0 || reportsCount == 0 {
                try context.save()
            }
        } catch {
            print("Failed to load or save demo data: \(error.localizedDescription)")
        }
    }
    
}

//
//  DataController.swift
//  itto
//
//  Created by Duru SAVAŞ on 17/11/2023.
//
import Foundation
import CoreData

class DataController: ObservableObject {
    let container = NSPersistentContainer(name: "Itto") // the actual data being loaded from coredata

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
    
// MARK: DEMO DATA
    
    func populateDemoData() {
        let context = container.viewContext

        // Check if the data already exists to avoid duplicates
        let subjectRequest: NSFetchRequest<Subjects> = Subjects.fetchRequest()
        let reportRequest: NSFetchRequest<Report> = Report.fetchRequest()

        do {
            let subjectsCount = try context.count(for: subjectRequest)
            let reportsCount = try context.count(for: reportRequest)

            if subjectsCount == 0 && reportsCount == 0 {
                // Creating demo Subjects
                let subject1 = Subjects(context: context)
                subject1.color = "R:182, G:193, B:60"
                subject1.id = UUID()
                subject1.name = "Introduction to Computer Science"

                let subject2 = Subjects(context: context)
                subject2.color = "R:27, G:243, B:3"
                subject2.id = UUID()
                subject2.name = "Data Structures and Algorithms"

                let subject3 = Subjects(context: context)
                subject3.color = "R:118, G:196, B:113"
                subject3.id = UUID()
                subject3.name = "Operating Systems"

                let subject4 = Subjects(context: context)
                subject4.color = "R:238, G:3, B:212"
                subject4.id = UUID()
                subject4.name = "Computer Networks"

                let subject5 = Subjects(context: context)
                subject5.color = "R:209, G:99, B:197"
                subject5.id = UUID()
                subject5.name = "Database Systems"

                let subject6 = Subjects(context: context)
                subject6.color = "R:101, G:152, B:194"
                subject6.id = UUID()
                subject6.name = "Software Engineering"

                let subject7 = Subjects(context: context)
                subject7.color = "R:255, G:134, B:186"
                subject7.id = UUID()
                subject7.name = "Artificial Intelligence"



                // Creating demo Reports
                let report1 = Report(context: context)
                report1.date = Date()
                report1.subjectName = "Mathematics"
                report1.totalTime = 120

                let report2 = Report(context: context)
                report2.date = Date()
                report2.subjectName = "Science"
                report2.totalTime = 90

                // Save the context
                try context.save()
            }
        } catch {
            print("Failed to load or save demo data: \(error.localizedDescription)")
        }
    }
}

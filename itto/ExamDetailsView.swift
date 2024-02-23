//
//  ExamDetailsView.swift
//  itto
//
//  Created by Duru SAVAŞ on 19/02/2024.
//


import SwiftUI
import CoreData

struct ExamDetailsView: View {
    @ObservedObject var exam: Exams
    @State private var newTopic: String = ""

    var body: some View {
        VStack {
            // Display exam details
            Text(exam.examName ?? "")
                .font(.largeTitle)
                .lineLimit(1) // Limit text to a single line
                     .minimumScaleFactor(0.5)
                .padding()
            
            List {
                Section {
                    ForEach(exam.topicsArray, id: \.self) { topic in
                        Text(topic)
                    }
                    .onDelete(perform: deleteTopic)
                }
                Section {
                    HStack {
                        TextField("New Topic", text: $newTopic)
                            .padding(.horizontal)
                        Button(action: addTopic) {
                            Text("Save")
                        }
                        .padding()
                    }
                }
            }
          
            .padding()
        }
        .navigationTitle(exam.name ?? "Exam Details")
        
        
    }

    private func deleteTopic(at offsets: IndexSet) {
        if let topics = exam.topics as? NSMutableArray {
              topics.removeObjects(at: offsets)
              exam.topics = topics as NSObject
              saveChanges()

              // Delete corresponding DailySubjects
              deleteDailySubjects(topics: offsets.map { topics[$0] as! String })
          }
      }

    private func addTopic() {
        if !newTopic.isEmpty {
            // Add a new DailySubject for the added topic
            addDailySubject(topic: newTopic)

            // Now update the exam topics
            if var topics = exam.topics as? [String] {
                topics.append(newTopic)
                exam.topics = topics as NSObject
                saveChanges()
                newTopic = ""
            }
        }
    }




    private func saveChanges() {
        do {
            try exam.managedObjectContext?.save()
        } catch {
            print("Error saving changes: \(error)")
        }
    }

    private func deleteDailySubjects(topics: [String]) {
        guard let managedObjectContext = exam.managedObjectContext else { return }

        let fetchRequest: NSFetchRequest<DailySubjects> = DailySubjects.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "subjectName == %@ AND category == %@", exam.name ?? "", "Exam")

        do {
            let dailySubjects = try managedObjectContext.fetch(fetchRequest)
            for dailySubject in dailySubjects {
                if let dailyTopics = dailySubject.topics as? [String],
                   let remainingTopics = dailyTopics.filter({ !topics.contains($0) }) as NSObject? {
                    dailySubject.topics = remainingTopics
                }

                // If no topics remain, delete the entire DailySubject
                if let remainingTopics = dailySubject.topics as? [String], remainingTopics.isEmpty {
                    managedObjectContext.delete(dailySubject)
                }
            }
            try managedObjectContext.save()
        } catch {
            print("Error deleting DailySubjects: \(error)")
        }
    }



    private func addDailySubject(topic: String) {
        guard let managedObjectContext = exam.managedObjectContext else { return }

        let fetchRequest: NSFetchRequest<DailySubjects> = DailySubjects.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "subjectName == %@ AND category == %@", exam.examName ?? "", "Exam")

        do {
            let dailySubjects = try managedObjectContext.fetch(fetchRequest)

            if let existingDailySubject = dailySubjects.first {
                // DailySubject with the same subjectName and category already exists
                if var existingTopics = existingDailySubject.topics as? [String] {
                    // Append the new topic to the existing topics array
                    existingTopics.append(topic)
                    existingDailySubject.topics = existingTopics as NSObject
                } else {
                    // If topics is nil or not of the expected type, create a new array with the new topic
                    existingDailySubject.topics = [topic] as NSObject
                }
            } else {
                // Create a new DailySubject since one does not exist with the same subjectName and category
                let dailySubject = DailySubjects(context: managedObjectContext)
                dailySubject.subjectName = exam.examName
                dailySubject.date = Date() // Adjust as needed
                dailySubject.isCompleted = false
                dailySubject.category = "Exam"
                dailySubject.topics = [topic] as NSObject
            }

            saveChanges()
            printDailySubjects()
        } catch {
            print("Error adding DailySubject: \(error)")
        }
    }

    private func printDailySubjects() {
        guard let managedObjectContext = exam.managedObjectContext else { return }

        let fetchRequest: NSFetchRequest<DailySubjects> = DailySubjects.fetchRequest()

        do {
            let dailySubjects = try managedObjectContext.fetch(fetchRequest)
            print("DailySubjects:")
            for dailySubject in dailySubjects {
                print("Subject Name: \(dailySubject.subjectName ?? "Unknown"), Topics: \(dailySubject.topics as? [String] ?? ["No topics"]), Date: \(dailySubject.date ?? Date())")
            }
        } catch {
            print("Error fetching DailySubjects: \(error)")
        }
    }

}

extension Exams {
    var topicsArray: [String] {
        topics as? [String] ?? []
    }
}

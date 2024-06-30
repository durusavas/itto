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
                .lineLimit(1)
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
                        TextField(LocalizedStringKey("new_topic"), text: $newTopic)
                            .padding(.horizontal)
                        Button(action: addTopic) {
                            Text(LocalizedStringKey("save"))
                        }
                        .padding()
                    }
                }
            }
            .padding()
        }
        .navigationTitle(exam.name ?? NSLocalizedString("exam_details", comment: "Exam Details"))
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
            addDailySubject(topic: newTopic)

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
                if var existingTopics = existingDailySubject.topics as? [String] {
                    existingTopics.append(topic)
                    existingDailySubject.topics = existingTopics as NSObject
                } else {
                    existingDailySubject.topics = [topic] as NSObject
                }
            } else {
                let dailySubject = DailySubjects(context: managedObjectContext)
                dailySubject.subjectName = exam.examName
                dailySubject.date = Date()
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

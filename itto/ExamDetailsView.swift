//
//  ExamDetailsView.swift
//  itto
//
//  Created by Duru SAVAŞ on 19/02/2024.
//
import SwiftUI
import CoreData
struct ExamDetailsView: View {
    @ObservedObject var exam: Subjects
    @State private var newTopic: String = ""

    var body: some View {
        VStack {
            // Display exam details
            Text("Topics")
                .font(.largeTitle)
                .padding()
            
            List {
                Section {
                    ForEach(exam.topics ?? [], id: \.self) { topic in
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
            
            // Add new topic section
            
            // Button to add a new topic
            Button(action: addTopic) {
                Label("Add Topic", systemImage: "plus")
            }
            .padding()
        }
        .navigationTitle(exam.name ?? "Exam Details")
        .navigationBarItems(leading:
            Circle()
                .foregroundColor(exam.color?.toColor() ?? .blue)
                .frame(width: 30, height: 30),
            trailing:
            Text(exam.name ?? "Exam Details")
        )
    }

    private func deleteTopic(at offsets: IndexSet) {
        if var topics = exam.topics as? NSMutableArray {
            let deletedTopics = topics.objects(at: offsets) as! [String]
            topics.removeObjects(at: offsets)
            exam.topics = topics as? [String]
            saveChanges()

            // Delete corresponding DailySubjects
            deleteDailySubjects(topics: deletedTopics)
        }
    }

    private func addTopic() {
        if !newTopic.isEmpty {
            if var topics = exam.topics {
                topics.append(newTopic)
                exam.topics = topics as? [String]
                saveChanges()
                newTopic = ""

                // Add a new DailySubject for the added topic
                addDailySubject(topic: newTopic)
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
                if let dailyTopics = dailySubject.topics as? [String], dailyTopics.allSatisfy({ topics.contains($0) }) {
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

        let dailySubject = DailySubjects(context: managedObjectContext)
        dailySubject.subjectName = exam.name
        dailySubject.date = Date() // Adjust as needed
        dailySubject.isCompleted = false
        dailySubject.category = "Exam"
        dailySubject.topics = [topic] as NSObject
        saveChanges()
    }
}

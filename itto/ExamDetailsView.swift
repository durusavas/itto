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
    var color: Color
    @State private var newTopic: String = ""
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color("bg2"), Color("bg1")]),
                startPoint: .center,
                endPoint: .topTrailing
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack {
                List {
                    Section {
                        ForEach(exam.topicsArray, id: \.self) { topic in
                            HStack {
                                GradientCircleView(baseColor: color)
                                    .frame(width: 10, height: 10)
                                    .padding(5)
                                Text(topic)
                                    .font(.custom("Poppins-Regular", size: 17))
                            }
                        }
                        .onDelete(perform: deleteTopic)
                    }
                    .padding(5)
                    .listRowBackground(Color.gray.opacity(0.05))
                    
                    Section {
                        HStack {
                            TextField(LocalizedStringKey("new_topic"), text: $newTopic)
                                .textFieldStyle(PlainTextFieldStyle())
                            
                            Button(action: addTopic) {
                                Text(LocalizedStringKey("save"))
                                    .font(.custom("Poppins-Regular", size: 17))
                            }
                            .padding()
                        }
                    }
                  
                    .listRowBackground(Color.gray.opacity(0.05))
                }
                .scrollContentBackground(.hidden)
         
            }
            .background(Color.clear)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        Text(exam.examName ?? NSLocalizedString("exam_details", comment: "Exam Details"))
                            .font(.custom("Poppins-SemiBold", size: 20))
                    }
                }
            }
        }
    }
    
    private func deleteTopic(at offsets: IndexSet) {
        if let topics = exam.topics as? NSMutableArray {
            topics.removeObjects(at: offsets)
            exam.topics = topics as NSObject
            saveChanges()
            deleteDailySubjects(topics: offsets.map { topics[$0] as! String })
        }
    }
    
    private func addTopic() {
        if !newTopic.isEmpty {
            withAnimation {
                addDailySubject(topic: newTopic)
                
                if var topics = exam.topics as? [String] {
                    topics.append(newTopic)
                    exam.topics = topics as NSObject
                    saveChanges()
                    newTopic = ""
                }
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

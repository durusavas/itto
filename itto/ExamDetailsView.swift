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
                        HStack {
                            Text("\(exam.topicsArray.count) topics")
                                .font(.custom("Poppins-Regular", size: 16))
                            Spacer()
                            if !exam.topicsArray.isEmpty {
                                Text("100%")
                                    .font(.custom("Poppins-Regular", size: 14))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(Color.gray.opacity(0.05))
                    
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
                    
                    Section("Due Date") {
                        Toggle("Has due date", isOn: Binding(
                            get: { exam.dueDate != nil },
                            set: { enabled in
                                if enabled {
                                    exam.dueDate = Date().addingTimeInterval(86400 * 7)
                                } else {
                                    exam.dueDate = nil
                                }
                                saveChanges()
                            }
                        ))
                        if exam.dueDate != nil {
                            DatePicker("Due", selection: Binding(
                                get: { exam.dueDate ?? Date() },
                                set: { exam.dueDate = $0; saveChanges() }
                            ), displayedComponents: .date)
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
        if var topics = exam.topics as? [String] {
            // Capture the names to delete BEFORE mutating the array
            let deletedTopics = offsets.map { topics[$0] }
            topics.remove(atOffsets: offsets)
            exam.topics = topics as NSObject
            saveChanges()
            deleteDailySubjects(topics: deletedTopics)
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
        fetchRequest.predicate = NSPredicate(format: "subjectName == %@ AND category == %@", exam.examName ?? exam.name ?? "", "Exam")
        
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
        fetchRequest.predicate = NSPredicate(format: "subjectName == %@ AND category == %@", exam.examName ?? exam.name ?? "", "Exam")
        
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
        } catch {
            print("Error adding DailySubject: \(error)")
        }
    }
}

extension Exams {
    var topicsArray: [String] {
        topics as? [String] ?? []
    }
}

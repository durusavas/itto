//
//  ProjectDetailsView.swift
//  itto
//
//  Created by Duru SAVAŞ on 05/07/2024.
//

import SwiftUI
import CoreData

struct ProjectDetailsView: View {
    @ObservedObject var project: Projects
    var color: Color
    @State private var newTopic: String = ""
    var body: some View {
        VStack {
            List {
                Section {
                    ForEach(project.topicsArray, id: \.self) { topic in
                        Text(topic)
                    }
                    
                    .onDelete(perform: deleteTopic)
                }
                .listRowBackground(Color(red: 15/255, green: 20/255, blue: 33/255))
                Section {
                    HStack {
                        TextField(LocalizedStringKey("new_topic"), text: $newTopic)
                     
                        Button(action: addTopic) {
                            Text(LocalizedStringKey("save"))
                        }
                        .padding()
                    }
                
                }
            .listRowBackground(Color(red: 15/255, green: 20/255, blue: 33/255))
           
            }
            .padding()
        }
        
        .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        HStack {
                           GradientCircleView(baseColor: color)
                            .frame(width: 20, height: 20)
                            Text(project.name ?? NSLocalizedString("project_details", comment: "Project Details"))
                                .font(.system(size: 24, weight: .bold)) // Customize font size and weight here
                        }
                    }
                }
    }
    

    private func deleteTopic(at offsets: IndexSet) {
        if let topics = project.topics as? NSMutableArray {
            topics.removeObjects(at: offsets)
            project.topics = topics as NSObject
            saveChanges()

            // Delete corresponding DailySubjects
            deleteDailySubjects(topics: offsets.map { topics[$0] as! String })
        }
    }

    private func addTopic() {
           if !newTopic.isEmpty {
               withAnimation {
                   addDailySubject(topic: newTopic)

                   if var topics = project.topics as? [String] {
                       topics.append(newTopic)
                       project.topics = topics as NSObject
                       saveChanges()
                       newTopic = ""
                   } else {
                       project.topics = [newTopic] as NSObject
                       saveChanges()
                       newTopic = ""
                   }
               }
           }
       }

    private func saveChanges() {
        do {
            try project.managedObjectContext?.save()
        } catch {
            print("Error saving changes: \(error)")
        }
    }

    private func deleteDailySubjects(topics: [String]) {
        guard let managedObjectContext = project.managedObjectContext else { return }

        let fetchRequest: NSFetchRequest<DailySubjects> = DailySubjects.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "subjectName == %@ AND category == %@", project.name ?? "", "Project")

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
        guard let managedObjectContext = project.managedObjectContext else { return }

        let fetchRequest: NSFetchRequest<DailySubjects> = DailySubjects.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "subjectName == %@ AND category == %@", project.name ?? "", "Project")

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
                dailySubject.subjectName = project.name
                dailySubject.date = Date()
                dailySubject.isCompleted = false
                dailySubject.category = "Project"
                dailySubject.topics = [topic] as NSObject
            }

            saveChanges()
            printDailySubjects()
        } catch {
            print("Error adding DailySubject: \(error)")
        }
    }

    private func printDailySubjects() {
        guard let managedObjectContext = project.managedObjectContext else { return }

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

extension Projects {
    var topicsArray: [String] {
        topics as? [String] ?? []
    }
}




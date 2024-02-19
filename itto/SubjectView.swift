//
//  SubjectView.swift
//  itto
//
//  Created by Duru SAVAŞ on 17/11/2023.
//
// SubjectView.swift
import SwiftUI
import CoreData

struct SubjectView: View {
    @Environment(\.managedObjectContext) var moc
    @FetchRequest(sortDescriptors: []) var subjects: FetchedResults<Subjects>
    @State private var showAddScreen = false
    @State private var selectedExam: Subjects?

    var body: some View {
        NavigationView {
            VStack {
                // List for "My Subjects"
                List {
                    if !filteredSubjects(category: "Class").isEmpty {
                        Section(header: Text("My Subjects")) {
                            ForEach(filteredSubjects(category: "Class"), id: \.self) { item in
                                SubjectRowView(item: item)
                            }
                            .onDelete(perform: deleteSubject)
                        }
                        
                    }
                    // List for "My Exams"
                    if !filteredSubjects(category: "Exam").isEmpty {
                       
                        Section(header: Text("My Exams")) {
                                              ForEach(filteredSubjects(category: "Exam"), id: \.self) { item in
                                                  NavigationLink(
                                                      destination: ExamDetailsView(exam: item),
                                                      tag: item,
                                                      selection: $selectedExam
                                                  ) {
                                                      SubjectRowView(item: item)
                                                  }
                                              }
                                              .onDelete(perform: deleteSubject)
                                          }
                        
                    }
                    
                    // List for "My Projects"
                    if !filteredSubjects(category: "Project").isEmpty {
                   
                            Section(header: Text("My Projects")) {
                                ForEach(filteredSubjects(category: "Project"), id: \.self) { item in
                                    SubjectRowView(item: item)
                                }
                                .onDelete(perform: deleteSubject)
                            }
                        
                    }
                }
            }
            .navigationTitle("Subjects")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddScreen.toggle()
                    } label: {
                        Label("Add new", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddScreen) {
                AddSubjectView()
            }
        }
    }

    // Function to filter subjects based on category
    private func filteredSubjects(category: String) -> [Subjects] {
        return subjects.filter { $0.category == category }
    }

    // Function to handle the deletion of subjects
    private func deleteSubject(at offsets: IndexSet) {
        for index in offsets {
            let subjectToDelete = subjects[index]
            moc.delete(subjectToDelete)
        }

        // Save the context
        do {
            try moc.save()
        } catch {
            print("Error saving context after deletion: \(error)")
        }
    }

}

struct SubjectRowView: View {
    let item: Subjects

    var body: some View {
        HStack {
            Circle()
                .frame(width: 20, height: 20)
                .foregroundColor(item.color?.toColor() ?? Color.white)
            Text(item.name ?? "Unknown")
        }
    }
}

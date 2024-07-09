//
//  SubjectView.swift
//  itto
//
//  Created by Duru SAVAŞ on 17/11/2023.
//

import SwiftUI
import CoreData

struct SubjectView: View {
    @Environment(\.managedObjectContext) var moc
    @FetchRequest(sortDescriptors: []) var subjects: FetchedResults<Subjects>
    @FetchRequest(sortDescriptors: []) var exams: FetchedResults<Exams>
    @FetchRequest(sortDescriptors: []) var projects: FetchedResults<Projects>
    @State private var showAddScreen = false
    @State private var selectedExam: Subjects?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 1/255, green: 28/255, blue: 40/255)
                    .ignoresSafeArea()
                VStack {
                    List {
                        // "My Subjects" Section
                        if !subjects.isEmpty {
                            Section(header: Text(LocalizedStringKey("my_classes"))) {
                                ForEach(subjects, id: \.self) { item in
                                    HStack {
                                    GradientCircleView(baseColor: item.color?.toColor() ?? Color.white)
                                            .frame(width: 20, height: 20)
                                        Text(item.name ?? "Unknown")
                                    }
                                    .listRowBackground(Color(red: 15/255, green: 20/255, blue: 33/255))
                                }
                                .onDelete(perform: deleteSubject)
                            }
                        }
                        // "My Exams" Section
                        if !exams.isEmpty {
                            Section(header: Text(LocalizedStringKey("my_exams"))) {
                                ForEach(exams, id: \.self) { exam in
                                    NavigationLink(
                                        destination: ExamDetailsView(exam: exam, color:exam.color?.toColor() ?? Color.white),
                                        label: {
                                            HStack {
                                                GradientCircleView(baseColor: exam.color?.toColor() ?? Color.white)
                                                                                           .frame(width: 20, height: 20)
                                                Text(exam.examName ?? "Unknown")
                                            }
                                        }
                                    )
                                    .listRowBackground(Color(red: 15/255, green: 20/255, blue: 33/255))
                                }
                                .onDelete(perform: deleteSubject)
                            }
                        }
                        // "My Projects" Section
                        if !projects.isEmpty {
                            Section(header: Text(LocalizedStringKey("my_projects"))) {
                                ForEach(projects, id: \.self) { project in
                                    NavigationLink(
                                        destination: ProjectDetailsView(project: project, color:project.color?.toColor() ?? Color.white),
                                        label: {
                                            HStack {
                                                GradientCircleView(baseColor: project.color?.toColor() ?? Color.white)
                                                    .frame(width: 20, height: 20)
                                                Text(project.name ?? "Unknown")
                                            }
                                        }
                                        )
                                    .listRowBackground(Color(red: 15/255, green: 20/255, blue: 33/255))
                                }
                                .onDelete(perform: deleteSubject)
                            }
                           
                        }
                        
                    }
                }
                .navigationTitle(LocalizedStringKey("subjects"))
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showAddScreen.toggle()
                        } label: {
                            Label(LocalizedStringKey("add_new"), systemImage: "plus")
                        }
                    }
                }
                .sheet(isPresented: $showAddScreen) {
                    AddSubjectView()
                }
            }
        }
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



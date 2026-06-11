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
    @State private var searchText = ""
    
    private var filteredSubjectsList: [Subjects] {
        if searchText.isEmpty { return Array(subjects) }
        return subjects.filter { ($0.name ?? "").localizedCaseInsensitiveContains(searchText) }
    }
    
    private var filteredExamsList: [Exams] {
        if searchText.isEmpty { return Array(exams) }
        return exams.filter { ($0.examName ?? $0.name ?? "").localizedCaseInsensitiveContains(searchText) }
    }
    
    private var filteredProjectsList: [Projects] {
        if searchText.isEmpty { return Array(projects) }
        return projects.filter { ($0.name ?? "").localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color("bg2"), Color("bg1")]),
                    startPoint: .center,
                    endPoint: .topTrailing
                )
                .edgesIgnoringSafeArea(.all)
                
                VStack {
                    ScrollView {
                        VStack(spacing: 20) {
                            
                            if !filteredSubjectsList.isEmpty {
                                sectionView(title: "my_classes", items: filteredSubjectsList.map { item in
                                    subjectRow(item: item)
                                })
                            }
                            
                            if !filteredExamsList.isEmpty {
                                sectionView(title: "my_exams", items: filteredExamsList.map { exam in
                                    examRow(exam: exam)
                                })
                            }
                            
                            if !filteredProjectsList.isEmpty {
                                sectionView(title: "my_projects", items: filteredProjectsList.map { project in
                                    projectRow(project: project)
                                })
                            }
                            
                            if searchText.isEmpty == false &&
                               filteredSubjectsList.isEmpty &&
                               filteredExamsList.isEmpty &&
                               filteredProjectsList.isEmpty {
                                Text("No results for \"\(searchText)\"")
                                    .font(.custom("Poppins-Regular", size: 16))
                                    .foregroundColor(.secondary)
                                    .padding(.top, 40)
                            }
                            
                            // First-use empty state
                            if searchText.isEmpty &&
                               filteredSubjectsList.isEmpty &&
                               filteredExamsList.isEmpty &&
                               filteredProjectsList.isEmpty {
                                VStack(spacing: 12) {
                                    Text("Welcome to itto 👋")
                                        .font(.custom("Poppins-SemiBold", size: 20))
                                    Text("Tap the + button to add your first class, exam, or project.\n\nYour schedule will automatically appear in the Today tab.")
                                        .font(.custom("Poppins-Regular", size: 15))
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                }
                                .padding(.vertical, 40)
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                    .padding(.bottom, 80)
                }
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text(LocalizedStringKey("subjects"))
                            .font(.custom("Poppins-Regular", size: 23))
                    }
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
            .searchable(text: $searchText, prompt: LocalizedStringKey("Search"))
        }
    }
    
    private func sectionView(title: String, items: [AnyView]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
              
                Rectangle()
                    .fill(Color.white.opacity(0.5))
                    .frame(height: 0.7)
                Text(LocalizedStringKey(title))
                    .font(.custom("Poppins-Regular", size: 18))
                    .foregroundColor(.white.opacity(0.5))

            }
            .padding()
            
            VStack(alignment: .leading, spacing: 0) {
                ForEach(0..<items.count, id: \.self) { index in
                    items[index]
                        .padding(.vertical, 10)
                        .background(Color.clear)
                    if index != items.count - 1 {
                        Rectangle()
                            .fill(Color.gray.opacity(0.1))
                            .frame(height: 1)
                            .padding(.vertical, 5)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.gray.opacity(0.05))  // Match the background and corner radius
                    .frame(maxWidth: .infinity)
            )
            .animation(.easeInOut(duration: 0.3), value: items.count)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
    }

    
    private func subjectRow(item: Subjects) -> AnyView {
        AnyView(
            HStack {
                GradientCircleView(baseColor: item.color?.toColor() ?? Color.white)
                    .frame(width: 16, height: 16)
                Text(item.name ?? "Unknown")
                    .font(.custom("Poppins-Regular", size: 15))
                    .foregroundColor(.primary)
            }
            
        )
    }
    
    private func examRow(exam: Exams) -> AnyView {
        AnyView(
            NavigationLink(destination: ExamDetailsView(exam: exam, color: exam.color?.toColor() ?? Color.white)) {
                HStack {
                    GradientCircleView(baseColor: exam.color?.toColor() ?? Color.white)
                        .frame(width: 16, height: 16)
                    Text(exam.examName ?? "Unknown")
                        .font(.custom("Poppins-Regular", size: 15))
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
            }
        )
    }
    
    private func projectRow(project: Projects) -> AnyView {
        AnyView(
            NavigationLink(destination: ProjectDetailsView(project: project, color: project.color?.toColor() ?? Color.white)) {
                HStack {
                    GradientCircleView(baseColor: project.color?.toColor() ?? Color.white)
                        .frame(width: 16, height: 16)
                    Text(project.name ?? "Unknown")
                        .font(.custom("Poppins-Regular", size: 15))
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
            }
        )
    }
}

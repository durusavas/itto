//
//  SubjectView.swift
//  itto
//
//  Created by Duru SAVAŞ on 17/11/2023.
//

import SwiftUI
import CoreData
import Foundation

struct SubjectView: View {
    @Environment(\.managedObjectContext) var moc
    @FetchRequest(sortDescriptors: []) var subject: FetchedResults<Subjects>
    
    
    @State private var showAddScreen = false
    
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(subject, id: \.self) { item in
                        HStack {
                            Circle()
                                .frame(width: 20, height: 20)
                                .foregroundColor(item.color?.toColor() ?? Color.white)
                            Text(item.name ?? "Unknown")
                        }
                    }
                    .onDelete(perform: deleteSubject) // Enables swipe-to-delete
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showAddScreen.toggle()
                        } label: {
                            Label("Add new", systemImage: "plus")
                        }
                    }
                }
                .navigationTitle("My Subjects")
                .sheet(isPresented: $showAddScreen) {
                    AddSubjectView()
                }
            }
        }
    }

    // Function to handle the deletion of subjects
    private func deleteSubject(at offsets: IndexSet) {
        for index in offsets {
            let subjectToDelete = subject[index]
            moc.delete(subjectToDelete)
        }

        // Save the context
        try? moc.save()
    }

    
}



#Preview {
    SubjectView()
}

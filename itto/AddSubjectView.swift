//
//  AddSubjectView.swift
//  itto
//
//  Created by Duru SAVAŞ on 17/11/2023.
//
import SwiftUI
import CoreData

extension Color {
    func toRgbString() -> String {
        // Convert Color to UIColor
        let uiColor = UIColor(self)
        
        // Get RGB components
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // Format RGB components into a string
        return String(format: "R: %.0f, G: %.0f, B: %.0f", red * 255, green * 255, blue * 255)
    }
}
struct AddSubjectView: View {
    @Environment(\.managedObjectContext) var moc
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var color: Color = Color.red
    
    var body: some View {
        Form {
            Section {
                HStack {
                    TextField("Enter subject name", text: $name)
                        .padding()
                    ColorPicker("Choose Color", selection: $color)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: saveSubject) {
                    Label("Save", systemImage: "save")
                }
            }
        }
        .navigationTitle("Add Subject")
    }

    private func saveSubject() {
        let newSubject = Subjects(context: moc)
        newSubject.id = UUID()
        newSubject.name = name
        newSubject.color = color.toRgbString()
        
        do {
            try moc.save()
            dismiss()
        } catch {
            // Handle the error here, perhaps with an alert to the user
            print("Error saving subject: \(error.localizedDescription)")
        }
    }
}

// Preview
struct AddSubjectView_Previews: PreviewProvider {
    static var previews: some View {
        AddSubjectView()
    }
}

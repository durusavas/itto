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
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
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
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    private func saveSubject() {
        guard validateInput(name: name, color: color) else {
            alertMessage = "Invalid input: Name and color are required."
            showAlert = true
            return
        }
        
        let colorString = color.toRgbString()
        if isDuplicate(name: name, color: colorString) {
            alertMessage = "Duplicate name or color detected. Subject not saved."
            showAlert = true
            return
        }
        
        let newSubject = Subjects(context: moc)
        newSubject.id = UUID()
        newSubject.name = name
        newSubject.color = colorString
        
        do {
            try moc.save()
            dismiss()
        } catch {
            alertMessage = "Error saving subject: \(error.localizedDescription)"
            showAlert = true
        }
    }
    
    private func isDuplicate(name: String, color: String) -> Bool {
        let fetchRequest: NSFetchRequest<Subjects> = Subjects.fetchRequest()
        let predicate = NSPredicate(format: "name == %@ OR color == %@", name, color)
        fetchRequest.predicate = predicate
        
        do {
            let matchingSubjects = try moc.fetch(fetchRequest)
            return !matchingSubjects.isEmpty
        } catch {
            print("Error fetching subjects: \(error.localizedDescription)")
            return false
        }
    }
    
    private func validateInput(name: String, color: Color) -> Bool {
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// Preview
struct AddSubjectView_Previews: PreviewProvider {
    static var previews: some View {
        AddSubjectView()
    }
}

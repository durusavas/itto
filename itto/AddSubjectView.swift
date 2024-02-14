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
    @State private var categories = ["Project", "Class", "Exam"]
    @State private var chosenCategory = "Class"
    
    @State private var examSubjects: [String] = [""]
    
    @State private var selectedDays: [Weekday] = []
    @State private var selectedWeekdays: [Weekday] = []
    
    var body: some View {
        NavigationView {
            Form {
                
                Picker("category", selection: $chosenCategory){
                    ForEach(categories, id: \.self){ category in
                        Text("\(category )")
                        
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                Section {
                    HStack {
                        TextField("Calculus", text: $name)
                            .padding()
                        ColorPicker("", selection: $color)
                    }
                }
                Section {
                    if chosenCategory == "Class" {
                        Text("Choose the days you have this class in")
                            .font(.headline)
                        DaysPicker(selectedDays: $selectedWeekdays)
                    }
                    if chosenCategory == "Exam" {
                        Section {
                            Text("Write down the subjects you're going to study for this exam:")
                            
                            ForEach(0..<examSubjects.count, id: \.self) { index in
                                TextField("Subject \(index + 1)", text: $examSubjects[index])
                            }
                            
                            Button(action: addTextField) {
                                Label("Add Subject", systemImage: "plus")
                            }
                        }
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
    private func addTextField() {
        examSubjects.append("")
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
        newSubject.days = selectedWeekdays.map { $0.rawValue } as NSObject
        newSubject.category = chosenCategory
        newSubject.topics = examSubjects
        // Convert selected weekdays to actual dates and create DailySubjects
        for day in selectedWeekdays {
            if let dateForDay = getNextDate(for: day) {
                let dailySubject = DailySubjects(context: moc)
                dailySubject.subjectName = name
                dailySubject.date = dateForDay
                dailySubject.isCompleted = false
            }
        }
        
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
    private func getNextDate(for day: Weekday) -> Date?  {
        let today = Date()
        var dateComponent = DateComponents()
        let calendar = Calendar.current
        
        // Find the next date for the given day
        for i in 0..<7 {
            dateComponent.day = i
            if let nextDate = calendar.date(byAdding: dateComponent, to: today),
               calendar.component(.weekday, from: nextDate) == day.weekdayIndex {
                return nextDate
            }
        }
        return nil
    }
    
    private func validateInput(name: String, color: Color) -> Bool {
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

enum Weekday: String, CaseIterable {
    case monday = "Monday"
    case tuesday = "Tuesday"
    case wednesday = "Wednesday"
    case thursday = "Thursday"
    case friday = "Friday"
    case saturday = "Saturday"
    case sunday = "Sunday"
    
    var weekdayIndex: Int {
        switch self {
        case .sunday: return 1
        case .monday: return 2
        case .tuesday: return 3
        case .wednesday: return 4
        case .thursday: return 5
        case .friday: return 6
        case .saturday: return 7
        }
    }
}


struct DaysPicker: View {
    @Binding var selectedDays: [Weekday]
    
    var body: some View {
        VStack{
            
            HStack {
                ForEach(Weekday.allCases, id: \.self) { day in
                    Text(String(day.rawValue.first!))
                        .bold()
                        .foregroundColor(.white)
                        .frame(width: 30, height: 30)
                        .background(selectedDays.contains(day) ? Color.cyan.cornerRadius(10) : Color.gray.cornerRadius(10))
                        .onTapGesture {
                            if selectedDays.contains(day) {
                                selectedDays.removeAll(where: {$0 == day})
                            } else {
                                selectedDays.append(day)
                            }
                        }
                }
                
            }
            .padding()
        }
    }
}

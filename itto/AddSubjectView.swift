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
    @FetchRequest(sortDescriptors: []) var subject: FetchedResults<Subjects>
    @FetchRequest(sortDescriptors: []) var exams: FetchedResults<Exams>
    @State private var name = ""
    @State private var color: Color = Color.red
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var categories = ["Project", "Class", "Exam"]
    @State private var chosenCategory = "Class"
    @State private var examName: String = ""
    @State private var examSubjects: [String] = [""]
    
    @State private var selectedDays: [Weekday] = []
    @State private var selectedWeekdays: [Weekday] = []
    
    var body: some View {
        NavigationStack{
            Form {
                Picker("category", selection: $chosenCategory){
                    ForEach(categories, id: \.self){ category in
                        Text("\(category )")
                        
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                if chosenCategory == "Project"{
                    
                    Section {
                        HStack {
                            TextField("Project Name", text: $name)
                                .padding()
                            ColorPicker("", selection: $color)
                        }
                    }
                    
                }
                
                if chosenCategory == "Class" {
                    Section {
                        HStack {
                            TextField("Calculus", text: $name)
                                .padding()
                            ColorPicker("", selection: $color)
                        }
                    }
                    
                    Text("Choose the days you have this class in")
                        .font(.headline)
                    DaysPicker(selectedDays: $selectedWeekdays)
                }
                if chosenCategory == "Exam" {
                    Section{
                        TextField("Exam name", text:$examName)
                    }
                    Section {
                            Picker("Subject", selection: $name) {
                                ForEach(subject) { item in
                                    Text(item.name ?? "Unknown").tag(item.name ?? "Unknown")
                                }
                            }
                        }
                    Section {
                        Text("Topics for this exam:")
                            .font(.headline)
                        ForEach(0..<examSubjects.count, id: \.self) { index in
                            TextField("Topic \(index + 1)", text: $examSubjects[index])
                        }
                        
                        
                    }
                    Section{
                        Button(action: addTextField) {
                            Label("Add Topic", systemImage: "plus")
                        }
                    }
                }
                
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: saveSubject) {
                        Text("Save")
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
       /* if isDuplicate(name: name, color: colorString) {
            alertMessage = "Duplicate name or color detected. Subject not saved."
            showAlert = true
            return
        
        }
        */
        var newSubject: NSManagedObject
            if chosenCategory == "Project" {
                newSubject = Projects(context: moc)
                
            } else if chosenCategory == "Exam" {
                newSubject = Exams(context: moc)
               
                if let exam = newSubject as? Exams {
                    exam.topics = examSubjects as NSObject
                    exam.examName = examName
                }
            } else {
                newSubject = Subjects(context: moc)
                if let subject = newSubject as? Subjects {
                    subject.days = selectedWeekdays.map { $0.rawValue } as NSObject
                   
                }
            }
            
        newSubject.setValue(UUID(), forKey: "id")
        newSubject.setValue(name, forKey: "name")
        newSubject.setValue(colorString, forKey: "color")

        if chosenCategory == "Exam"{
            let dailySubject = DailySubjects(context: moc)
            dailySubject.subjectName = examName
            dailySubject.date = Date() // You might want to customize this based on your requirements
            dailySubject.isCompleted = false
            dailySubject.category = chosenCategory  // Add this line to set the category
            dailySubject.topics = examSubjects as NSObject
        }
        else if  chosenCategory == "Project" {
            let dailySubject = DailySubjects(context: moc)
            dailySubject.subjectName = name
            dailySubject.date = Date() // You might want to customize this based on your requirements
            dailySubject.isCompleted = false
            dailySubject.category = chosenCategory  // Add this line to set the categor
            
        }
        else {
            // If it's not an exam, save DailySubjects for each selected weekday
            for day in selectedWeekdays {
                if let dateForDay = getNextDate(for: day) {
                    let dailySubject = DailySubjects(context: moc)
                    dailySubject.subjectName = name
                    dailySubject.date = dateForDay
                    dailySubject.isCompleted = false
                    dailySubject.category = chosenCategory  // Add this line to set the category
                    dailySubject.topics = examSubjects as NSObject
                }
            }
        }
        
        if let matchingSubject = try? moc.fetch(fetchRequestForColor(name: name)) as? [Subjects],
           let subjectColor = matchingSubject.first?.color {
            newSubject.setValue(subjectColor, forKey: "color")
        }

        
        do {
            try moc.save()
            //printAllData()
            dismiss()
        } catch {
            alertMessage = "Error saving subject: \(error.localizedDescription)"
            showAlert = true
        }
    }
    
    private func fetchRequestForColor(name: String) -> NSFetchRequest<Subjects> {
        let fetchRequest: NSFetchRequest<Subjects> = Subjects.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", name)
        return fetchRequest
    }
    
    // Add this function inside your AddSubjectView struct
    private func printAllData() {
        print("Subjects:")
        printSubjects()
        
        print("\nDailySubjects:")
        printDailySubjects()
    }
    
    private func printSubjects() {
        let fetchRequest: NSFetchRequest<Subjects> = Subjects.fetchRequest()
        
        do {
            let subjects = try moc.fetch(fetchRequest)
            for subject in subjects {
                print("Name: \(subject.name ?? "Unknown"), Color: \(subject.color ?? "Unknown")")
                
                if let days = subject.days as? [String] {
                    print("Days: \(days.joined(separator: ", "))")
                }
                print("----")
            }
        } catch {
            print("Error fetching subjects: \(error.localizedDescription)")
        }
    }
    
    private func printDailySubjects() {
        let fetchRequest: NSFetchRequest<DailySubjects> = DailySubjects.fetchRequest()
        
        do {
            let dailySubjects = try moc.fetch(fetchRequest)
            for dailySubject in dailySubjects {
                print("Subject Name: \(dailySubject.subjectName ?? "Unknown"), Date: \(dailySubject.date ?? Date()), Completed: \(dailySubject.isCompleted), category: \(dailySubject.category ?? "None")")
                if let topics = dailySubject.topics as? [String] {
                    print("Topics: \(topics)")
                }
                print("----")
            }
        } catch {
            print("Error fetching daily subjects: \(error.localizedDescription)")
        }
    }
    
    
    
    /*
    private func isDuplicate(name: String, color: String) -> Bool {
        let fetchRequest: NSFetchRequest<Subjects> = Subjects.fetchRequest()
        let predicate = NSPredicate(format: "name == %@ AND color == %@", name, color)
        fetchRequest.predicate = predicate
        
        do {
            let matchingSubjects = try moc.fetch(fetchRequest)
            return !matchingSubjects.isEmpty
        } catch {
            print("Error fetching subjects: \(error.localizedDescription)")
            return false
        }
    }
     */
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

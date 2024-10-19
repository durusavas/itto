//
//  AddSubjectView.swift
//  itto
//
//  Created by Duru SAVAŞ on 17/11/2023.
//
import SwiftUI
import CoreData

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
    @FocusState private var isNameFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.bg2
                    .ignoresSafeArea()
                Form {
                    Picker("category", selection: $chosenCategory) {
                        ForEach(categories, id: \.self) { category in
                            Text(LocalizedStringKey(category.lowercased()))
                                .font(.custom("Poppins-Regular", size: 18))
                                .foregroundColor(.white)
                        }
                    }
                    .listRowBackground(Color.gray.opacity(0.1))
                    .pickerStyle(.segmented)
                    .padding()

                    if chosenCategory == "Project" {
                        Section {
                            HStack {
                                TextField(LocalizedStringKey("project_name"), text: $name)
                                    .font(.custom("Poppins-Regular", size: 16))
                                    .foregroundColor(.white)
                                    .padding()
                                    .focused($isNameFieldFocused)
                                ColorPicker("", selection: $color)
                            }
                        }
                        .listRowBackground(Color.gray.opacity(0.1))
                    }

                    if chosenCategory == "Class" {
                        Section {
                            HStack {
                                TextField(LocalizedStringKey("class_name"), text: $name)
                                    .font(.custom("Poppins-Regular", size: 18))
                                    .foregroundColor(.white)
                                    .padding()
                                    .focused($isNameFieldFocused)
                                ColorPicker("", selection: $color)
                            }
                        }
                        .listRowBackground(Color.gray.opacity(0.1))

                        Text(LocalizedStringKey("choose_days"))
                            .font(.custom("Poppins-Regular", size: 18))
                            .foregroundColor(.white)
                            .listRowBackground(Color.gray.opacity(0.1))
                        
                        DaysPicker(selectedDays: $selectedWeekdays)
                            .listRowBackground(Color.gray.opacity(0.1))
                    }

                    if chosenCategory == "Exam" {
                        Section {
                            TextField(LocalizedStringKey("exam_name"), text: $examName)
                                .font(.custom("Poppins-Regular", size: 18))
                                .foregroundColor(.white)
                                .focused($isNameFieldFocused)
                        }
                        .listRowBackground(Color.gray.opacity(0.1))

                        Section {
                            Picker(LocalizedStringKey("Subject"), selection: $name) {
                                Text(LocalizedStringKey("choose_subject")).tag("")
                                ForEach(subject) { item in
                                    Text(item.name ?? "Unknown")
                                        .font(.custom("Poppins-Regular", size: 18))
                                        .foregroundColor(.white)
                                        .tag(item.name ?? "Unknown")
                                }
                            }
                            .onAppear {
                                if let firstSubject = subject.first {
                                    name = firstSubject.name ?? ""
                                }
                            }
                        }
                        .listRowBackground(Color.gray.opacity(0.1))

                        Section {
                            Text(LocalizedStringKey("topics_for_exam"))
                                .font(.custom("Poppins-Regular", size: 18))
                                .foregroundColor(.white)
                            ForEach(0..<examSubjects.count, id: \.self) { index in
                                TextField(LocalizedStringKey(String(format: NSLocalizedString("Topic %d", comment: ""), index + 1)), text: $examSubjects[index])
                                    .font(.custom("Poppins-Regular", size: 18))
                                    .foregroundColor(.white)
                                    .focused($isNameFieldFocused)
                            }
                        }
                        .listRowBackground(Color.gray.opacity(0.1))
                        
                        Section {
                            Button(action: addTextField) {
                                Label(LocalizedStringKey("add_topic"), systemImage: "plus")
                                    .font(.custom("Poppins-Regular", size: 18))
                                    .foregroundColor(.white)
                            }
                        }
                        .listRowBackground(Color.gray.opacity(0.1))
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: saveSubject) {
                        Text(LocalizedStringKey("save"))
                            .font(.custom("Poppins-Regular", size: 15))
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text(NSLocalizedString("add_subject", comment: ""))
                        .padding()
                        .font(.custom("Poppins-Regular", size: 23))
                        .foregroundColor(.white)
                }
            }
            .onAppear {
              
                isNameFieldFocused = true
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text(LocalizedStringKey("error")).font(.custom("Poppins-Regular", size: 18)),
                      message: Text(alertMessage).font(.custom("Poppins-Regular", size: 18)),
                      dismissButton: .default(Text(LocalizedStringKey("ok")).font(.custom("Poppins-Regular", size: 18))))
            }
        }
    }
    
    private func addTextField() {
        examSubjects.append("")
    }

    private func saveSubject() {
        if name.isEmpty && chosenCategory != "Exam" {
            alertMessage = "The name cannot be empty."
            showAlert = true
            return
        }

        if examName.isEmpty && chosenCategory == "Exam" {
            alertMessage = "The exam name cannot be empty."
            showAlert = true
            return
        }

        let colorString = color.toRgbString()
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

        if chosenCategory == "Exam" {
            let dailySubject = DailySubjects(context: moc)
            dailySubject.subjectName = examName
            dailySubject.date = Date()
            dailySubject.isCompleted = false
            dailySubject.category = chosenCategory
            dailySubject.topics = examSubjects as NSObject
            dailySubject.color = colorString
        } else if chosenCategory == "Project" {
            let dailySubject = DailySubjects(context: moc)
            dailySubject.subjectName = name
            dailySubject.date = Date()
            dailySubject.isCompleted = false
            dailySubject.category = chosenCategory
            dailySubject.color = colorString  // Set color
        } else {
            for day in selectedWeekdays {
                if let dateForDay = getNextDate(for: day) {
                    let dailySubject = DailySubjects(context: moc)
                    dailySubject.subjectName = name
                    dailySubject.date = dateForDay
                    dailySubject.isCompleted = false
                    dailySubject.category = chosenCategory
                    dailySubject.color = colorString  // Set color
                }
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

    private func getNextDate(for day: Weekday) -> Date? {
        let today = Date()
        var dateComponent = DateComponents()
        let calendar = Calendar.current

        for i in 0..<7 {
            dateComponent.day = i
            if let nextDate = calendar.date(byAdding: dateComponent, to: today),
               calendar.component(.weekday, from: nextDate) == day.weekdayIndex {
                return nextDate
            }
        }
        return nil
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
        VStack {
            HStack {
                ForEach(Weekday.allCases, id: \.self) { day in
                    Text(String(day.rawValue.first!))
                        .font(.custom("Poppins-Regular", size: 18))
                        .bold()
                        .foregroundColor( Color.white)
                        .frame(width: 35, height: 35)
                        .background(selectedDays.contains(day) ? Color.bg1 : Color.gray.opacity(0.1))
                        .cornerRadius(28)
                        .onTapGesture {
                            if selectedDays.contains(day) {
                                selectedDays.removeAll(where: { $0 == day })
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

extension Color {
    func toRgbString() -> String {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return String(format: "R: %.0f, G: %.0f, B: %.0f", red * 255, green * 255, blue * 255)
    }
}

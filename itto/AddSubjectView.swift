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
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
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
        NavigationStack {
            Form {
                Picker("category", selection: $chosenCategory) {
                    ForEach(categories, id: \.self) { category in
                        Text(LocalizedStringKey(category.lowercased()))
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                if chosenCategory == "Project" {
                    Section {
                        HStack {
                            TextField(LocalizedStringKey("project_name"), text: $name)
                                .padding()
                            ColorPicker("", selection: $color)
                        }
                    }
                }

                if chosenCategory == "Class" {
                    Section {
                        HStack {
                            TextField(LocalizedStringKey("class_name"), text: $name)
                                .padding()
                            ColorPicker("", selection: $color)
                        }
                    }

                    Text(LocalizedStringKey("choose_days"))
                        .font(.headline)
                    DaysPicker(selectedDays: $selectedWeekdays)
                }

                if chosenCategory == "Exam" {
                    Section {
                        TextField(LocalizedStringKey("exam_name"), text: $examName)
                    }
                    Section {
                        Picker(LocalizedStringKey("Subject"), selection: $name) {
                            ForEach(subject) { item in
                                Text(item.name ?? "Unknown")
                            }
                        }
                    }
                    Section {
                        Text(LocalizedStringKey("topics_for_exam"))
                            .font(.headline)
                        ForEach(0..<examSubjects.count, id: \.self) { index in
                            TextField(LocalizedStringKey("Topic \(index + 1)"), text: $examSubjects[index])
                        }
                    }
                    Section {
                        Button(action: addTextField) {
                            Label(LocalizedStringKey("add_topic"), systemImage: "plus")
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: saveSubject) {
                        Text(LocalizedStringKey("save"))
                    }
                }
            }
            .navigationTitle(LocalizedStringKey("add_subject"))
            .alert(isPresented: $showAlert) {
                Alert(title: Text(LocalizedStringKey("error")), message: Text(alertMessage), dismissButton: .default(Text(LocalizedStringKey("ok"))))
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
            dailySubject.color = colorString  // Set color
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
        VStack {
            HStack {
                ForEach(Weekday.allCases, id: \.self) { day in
                    Text(String(day.rawValue.first!))
                        .bold()
                        .foregroundColor(.white)
                        .frame(width: 30, height: 30)
                        .background(selectedDays.contains(day) ? Color.cyan.cornerRadius(10) : Color.gray.cornerRadius(10))
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

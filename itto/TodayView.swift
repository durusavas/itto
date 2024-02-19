//
//  TodayView.swift
//  itto
//
//  Created by Duru SAVAŞ on 06/02/2024.
//

import SwiftUI
import CoreData

struct TodayView: View {
    
    @State private var showReselectSubjectsPopup = false
    @Environment(\.managedObjectContext) private var moc
    @FetchRequest var dailySubjects: FetchedResults<DailySubjects>
    
    // Custom initializer to setup fetch request
    init() {
        // Setup fetch request dynamically
        let fetchRequest: NSFetchRequest<DailySubjects> = DailySubjects.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \DailySubjects.date, ascending: true)]
        fetchRequest.predicate = TodayView.todayPredicate()
        
        // Initialize _dailySubjects with the dynamic fetch request
        _dailySubjects = FetchRequest<DailySubjects>(fetchRequest: fetchRequest)
    }
    var body: some View {
            NavigationView {
                VStack {
                    List {
                        ForEach(dailySubjects, id: \.self) { dailySubject in
                            if let subjectCategory = dailySubject.category {
                                // Check if the subject belongs to the "Exam" category
                                if subjectCategory == "Exam" {
                                    // Display exam and its topics with checkmarks
                                    Section(header: Text(dailySubject.category ?? "")) {
                                        
                                        Text(dailySubject.subjectName ?? "")
                                            .font(.headline)
                                        ForEach(dailySubject.topics as? [String] ?? [], id: \.self) { topic in
                                            HStack {
                                                CheckboxView(isChecked: dailySubject.isCompleted) { checked in
                                                    updateCompletionStatus(for: dailySubject, isCompleted: checked)
                                                }
                                                Text(topic)
                                                    .foregroundColor(dailySubject.isCompleted ? .gray : .primary)
                                            }
                                        }
                                    }
                                    if subjectCategory == "Project" {
                                        Section(header: Text(dailySubject.category ?? "")) {
                                            NavigationLink(
                                                destination: ContentView(chosenSubject: dailySubject.subjectName ?? ""),
                                                label: {
                                                    HStack {
                                                        CheckboxView(isChecked: dailySubject.isCompleted) { checked in
                                                            updateCompletionStatus(for: dailySubject, isCompleted: checked)
                                                        }
                                                        Text(dailySubject.subjectName ?? "Unknown Subject")
                                                            .foregroundColor(dailySubject.isCompleted ? .gray : .primary)
                                                    }
                                                }
                                            )
                                        }
                                        
                                    }
                                } else {
                                    // Display other subjects
                                    Section(header: Text(dailySubject.category ?? "")) {
                                        NavigationLink(
                                            destination: ContentView(chosenSubject: dailySubject.subjectName ?? ""),
                                            label: {
                                                HStack {
                                                    CheckboxView(isChecked: dailySubject.isCompleted) { checked in
                                                        updateCompletionStatus(for: dailySubject, isCompleted: checked)
                                                    }
                                                    Text(dailySubject.subjectName ?? "Unknown Subject")
                                                        .foregroundColor(dailySubject.isCompleted ? .gray : .primary)
                                                }
                                            }
                                        )
                                    }
                                }
                            }
                        }
                    }
                    .navigationTitle("Tod(o)ay")
                    .onAppear {
                        checkForWeeklyReset()
                        deleteCompletedSubjectsAtEndOfWeek(managedObjectContext: moc)
                    }
                }
                .sheet(isPresented: $showReselectSubjectsPopup) {
                    ReselectSubjectsView(isPresented: $showReselectSubjectsPopup)
                }
            }
        }
  
    
    private static func todayPredicate() -> NSPredicate {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        return NSCompoundPredicate(orPredicateWithSubpredicates: [
            NSPredicate(format: "date >= %@ AND date < %@", argumentArray: [today, tomorrow]),
            NSPredicate(format: "date < %@ AND isCompleted == %@", argumentArray: [today, NSNumber(value: false)])
        ])
    }
    
    
    private func checkForWeeklyReset() {
        let calendar = Calendar.current
        if calendar.component(.weekday, from: Date()) == 2 { // Checks if today is Monday
            showReselectSubjectsPopup = true
        }
    }
    
    private func updateCompletionStatus(for dailySubject: DailySubjects, isCompleted: Bool) {
        moc.performAndWait {
            dailySubject.isCompleted = isCompleted
            try? moc.save()
        }
    }
    private func deleteCompletedSubjectsAtEndOfWeek(managedObjectContext: NSManagedObjectContext) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let endOfWeekDay = 1 // Set to 1 for Sunday, 2 for Monday, etc., according to your week start day
        
        // Check if today is the end of the week day
        guard weekday == endOfWeekDay else { return }
        
        let fetchRequest: NSFetchRequest<DailySubjects> = DailySubjects.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isCompleted == %@", NSNumber(value: true))
        
        do {
            let completedSubjects = try managedObjectContext.fetch(fetchRequest)
            for completedSubject in completedSubjects {
                managedObjectContext.delete(completedSubject)
            }
            try managedObjectContext.save()
        } catch let error as NSError {
            print("Error deleting completed subjects: \(error), \(error.userInfo)")
        }
    }
    
    
}

struct CheckboxView: View {
    @State var isChecked: Bool
    let onChanged: (Bool) -> Void
    
    var body: some View {
        Image(systemName: isChecked ? "checkmark.square" : "square")
            .resizable()
            .frame(width: 24, height: 24)
            .foregroundColor(isChecked ? .blue : .gray)
            .onTapGesture {
                self.isChecked.toggle()
                self.onChanged(self.isChecked)
            }
    }
}

struct ReselectSubjectsView: View {
    @Environment(\.managedObjectContext) private var moc
    @Binding var isPresented: Bool
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Subjects.name, ascending: true)],
                  predicate: NSPredicate(format: "category == %@", "Class")) var subjects: FetchedResults<Subjects>

    var body: some View {
        NavigationView {
            List {
                ForEach(subjects) { subject in
                    Section(header: Text(subject.name ?? "Unknown")) {
                        DaysPicker(selectedDays: Binding(
                            get: {
                                (subject.days as? [String])?.compactMap { Weekday(rawValue: $0) } ?? []
                            },
                            set: { newValue in
                                subject.days = newValue.map { $0.rawValue } as NSObject
                                try? moc.save()
                            }
                        ))
                    }
                }
            }
            .navigationTitle("Reselect Days")
            .navigationBarItems(trailing: Button("Done") {
                isPresented = false
            })
        }
    }
}

private func updateDailySubjectsFor(subject: Subjects, with newDays: [Weekday], moc: NSManagedObjectContext) {
    guard subject.category == "Class" else {
        // Skip updating DailySubjects for subjects with categories other than "Class"
        return
    }

    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())

    // Fetch existing DailySubjects for the subject
    let fetchRequest: NSFetchRequest<DailySubjects> = DailySubjects.fetchRequest()
    fetchRequest.predicate = NSPredicate(format: "subjectName == %@", subject.name ?? "")

    do {
        let existingDailySubjects = try moc.fetch(fetchRequest)

        for day in newDays {
            if let nextDate = getNextDate(for: day) {
                // Check if there is already a DailySubject for the selected day
                if let dailySubject = existingDailySubjects.first(where: { $0.date == nextDate }) {
                    // Update the existing DailySubject
                    dailySubject.isCompleted = false // Reset completion status for the new day
                    // You might want to update other properties as needed
                } else {
                    // Create a new DailySubject for the selected day
                    let dailySubject = DailySubjects(context: moc)
                    dailySubject.subjectName = subject.name
                    dailySubject.date = nextDate
                    dailySubject.isCompleted = false
                    dailySubject.category = "Class" // Set the category accordingly
                    // Set other properties as needed
                }
            }
        }

        // Delete DailySubjects for days that are no longer selected
        let daysToRemove = existingDailySubjects.filter { dailySubject in
            !newDays.contains(Weekday(rawValue: dailySubject.date?.weekdayString ?? "") ?? .monday)
        }


        for dailySubject in daysToRemove {
            moc.delete(dailySubject)
        }

        try moc.save()

    } catch {
        print("Error updating DailySubjects: \(error.localizedDescription)")
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

extension Date {
    var weekdayString: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"
        return dateFormatter.string(from: self)
    }
}


enum Day: String, CaseIterable, Hashable {
    case sunday = "Sunday"
    case monday = "Monday"
    case tuesday = "Tuesday"
    case wednesday = "Wednesday"
    case thursday = "Thursday"
    case friday = "Friday"
    case saturday = "Saturday"
}

struct DayPicker: View {
    @Binding var selectedDays: [Day]
    
    var body: some View {
        VStack {
            ForEach(Day.allCases, id: \.self) { day in
                Button(action: {
                    if selectedDays.contains(day) {
                        selectedDays.removeAll { $0 == day }
                    } else {
                        selectedDays.append(day)
                    }
                }) {
                    HStack {
                        Text(day.rawValue)
                            .foregroundColor(selectedDays.contains(day) ? .white : .black)
                            .padding()
                            .background(selectedDays.contains(day) ? Color.blue : Color.clear)
                            .cornerRadius(5)
                    }
                }
            }
        }
    }
}


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
    
    @State private var showContentView = false
    
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
            List {
                
                ForEach(dailySubjects, id: \.self) { dailySubject in
                    HStack {
                        Text(dailySubject.subjectName ?? "Unknown Subject")
                            .foregroundColor(dailySubject.isCompleted ? .gray : .primary)
                    // MARK: FIX 
                            /*.sheet(isPresented: $showContentView) {
                                ContentView(chosenSubject: dailySubject.subjectName ?? "")
                                }
                             */
                        Spacer()
                        CheckboxView(isChecked: dailySubject.isCompleted, onChanged: { checked in
                            updateCompletionStatus(for: dailySubject, isCompleted: checked)
                        })
                    }
                }
            }
            .navigationTitle("Today's Subjects")
            .onAppear {
                checkForWeeklyReset()
                deleteCompletedSubjectsAtEndOfWeek(managedObjectContext: moc) // Add this line
            }
        }
        .sheet(isPresented: $showReselectSubjectsPopup) {
            ReselectSubjectsView(isPresented: $showReselectSubjectsPopup)
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
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Subjects.name, ascending: true)]) var subjects: FetchedResults<Subjects>
    
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


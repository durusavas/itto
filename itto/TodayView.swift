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
    
    init() {
        let fetchRequest: NSFetchRequest<DailySubjects> = DailySubjects.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \DailySubjects.date, ascending: true)]
        fetchRequest.predicate = TodayView.todayPredicate()
        _dailySubjects = FetchRequest<DailySubjects>(fetchRequest: fetchRequest)
    }
    private let categoryOrder = ["exam", "project", "class"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color("bg2"), Color("bg1")]),
                    startPoint: .center,
                    endPoint: .topTrailing
                )
                .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    HStack {
                        Rectangle()
                            .fill(Color.white)
                            .frame(height: 0.8)
                            .padding(.trailing, 5)
                        Text(currentDateString())
                            .font(.custom("Poppins-Regular", size: 25))
                            .foregroundColor(.white)
                            .padding(.leading, 5)
                        
                        Spacer()
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            if let classes = groupedDailySubjects["class"], !classes.isEmpty {
                                sectionView(title: "class", content: classes.map { classSection(dailySubject: $0) as! AnyView })
                            }
                            if let exams = groupedDailySubjects["exam"], !exams.isEmpty {
                                sectionView(title: "exam", content: exams.map { examSection(dailySubject: $0) as! AnyView })
                            }
                            if let projects = groupedDailySubjects["project"], !projects.isEmpty {
                                sectionView(title: "project", content: projects.map { projectSection(dailySubject: $0) as! AnyView })
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                    .padding(.bottom, 80)
                }
                .onAppear {
                    checkForWeeklyReset()
                    deleteCompletedSubjectsAtEndOfWeek(managedObjectContext: moc)
                }
                .sheet(isPresented: $showReselectSubjectsPopup) {
                    ReselectSubjectsView(isPresented: $showReselectSubjectsPopup)
                }
            }
        }
    }
    
    private func sectionView(title: String, content: [AnyView]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(0..<content.count, id: \.self) { index in
                    content[index]
                        .padding(.vertical, 10)
                        .background(Color.clear)
                    if index != content.count - 1 {
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
                    .fill(Color.gray.opacity(0.05))
                    .frame(maxWidth: .infinity)
            )
            .animation(.easeInOut(duration: 0.3), value: content.count)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
    }
    
    private func currentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM"
        return formatter.string(from: Date())
    }
    
    private func sortedGroupedDailySubjects() -> [(String, [DailySubjects])] {
        let groupedSubjects = groupedDailySubjects
        return groupedSubjects.sorted {
            guard let firstIndex = categoryOrder.firstIndex(of: $0.key.lowercased()),
                  let secondIndex = categoryOrder.firstIndex(of: $1.key.lowercased()) else {
                return false
            }
            return firstIndex < secondIndex
        }
    }
    
    private func isTopicCompleted(dailySubject: DailySubjects, topic: String) -> Bool {
        guard let completedTopics = dailySubject.topicsCompleted as? [String] else { return false }
        return completedTopics.contains(topic)
    }
    
    private func updateCompletionStatus(for dailySubject: DailySubjects, topic: String, isCompleted: Bool) {
        moc.performAndWait {
            withAnimation {
                var completedTopics = dailySubject.topicsCompleted as? [String] ?? []
                if isCompleted {
                    completedTopics.append(topic)
                } else {
                    completedTopics.removeAll { $0 == topic }
                }
                dailySubject.topicsCompleted = completedTopics as NSObject
                let allTopicsCompleted = Set(completedTopics) == Set(dailySubject.topics as? [String] ?? [])
                dailySubject.isCompleted = allTopicsCompleted
                if allTopicsCompleted {
                    moc.delete(dailySubject)
                }
                try? moc.save()
            }
        }
    }
    
    private func examSection(dailySubject: DailySubjects) -> some View {
        VStack(alignment: .leading) {
            Text(dailySubject.subjectName ?? "")
                .font(.custom("Poppins-SemiBold", size: 20))
            ForEach(dailySubject.topics as? [String] ?? [], id: \.self) { topic in
                HStack {
                    CheckboxView(isChecked: isTopicCompleted(dailySubject: dailySubject, topic: topic), color: dailySubject.color?.toColor() ?? .blue) { checked in
                        updateCompletionStatus(for: dailySubject, topic: topic, isCompleted: checked)
                    }
                    .padding(.leading, 10)
                    Text(topic)
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(isTopicCompleted(dailySubject: dailySubject, topic: topic) ? .gray : .primary)
                }
            }
        }
    }
    
    private func projectSection(dailySubject: DailySubjects) -> some View {
        VStack(alignment: .leading) {
            Text(dailySubject.subjectName ?? "")
                .font(.custom("Poppins-SemiBold", size: 20))
            ForEach(dailySubject.topics as? [String] ?? [], id: \.self) { topic in
                HStack {
                    CheckboxView(isChecked: isTopicCompleted(dailySubject: dailySubject, topic: topic), color: dailySubject.color?.toColor() ?? .blue) { checked in
                        updateCompletionStatus(for: dailySubject, topic: topic, isCompleted: checked)
                    }
                    .padding(.leading, 10)
                    Text(topic)
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(isTopicCompleted(dailySubject: dailySubject, topic: topic) ? .gray : .primary)
                }
            }
        }
    }
    
    private func classSection(dailySubject: DailySubjects) -> some View {
        HStack {
            CheckboxView(isChecked: dailySubject.isCompleted, color: dailySubject.color?.toColor() ?? .blue) { checked in
                updateCompletionStatus(for: dailySubject, isCompleted: checked)
            }
            .padding(.leading, 10)
            Text(dailySubject.subjectName ?? "Unknown Subject")
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundColor(dailySubject.isCompleted ? .gray : .primary)
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
    
    private var groupedDailySubjects: [String: [DailySubjects]] {
        Dictionary(grouping: dailySubjects, by: { $0.category?.lowercased() ?? "" })
    }
    
    private static let lastReselectKey = "LastReselectDate"
    
    private func checkForWeeklyReset() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        if calendar.component(.weekday, from: Date()) == 2 {
            if let lastReselectDate = UserDefaults.standard.value(forKey: TodayView.lastReselectKey) as? Date {
                if calendar.dateComponents([.weekOfYear], from: lastReselectDate, to: today).weekOfYear ?? 0 >= 1 {
                    showReselectSubjectsPopup = true
                    UserDefaults.standard.set(today, forKey: TodayView.lastReselectKey)
                }
            } else {
                showReselectSubjectsPopup = true
                UserDefaults.standard.set(today, forKey: TodayView.lastReselectKey)
            }
        }
    }
    
    private func updateCompletionStatus(for dailySubject: DailySubjects, topic: String? = nil, isCompleted: Bool) {
        moc.performAndWait {
            withAnimation {
                var completedTopics = dailySubject.topicsCompleted as? [String] ?? []
                if isCompleted {
                    completedTopics.append(topic ?? "")
                } else {
                    completedTopics.removeAll { $0 == topic }
                }
                dailySubject.topicsCompleted = completedTopics as NSObject
                let allTopicsCompleted = Set(completedTopics) == Set(dailySubject.topics as? [String] ?? [])
                dailySubject.isCompleted = allTopicsCompleted
                if isCompleted {
                    moc.delete(dailySubject)
                }
                try? moc.save()
            }
        }
    }
    
    private func deleteCompletedSubjectsAtEndOfWeek(managedObjectContext: NSManagedObjectContext) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let endOfWeekDay = 1
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
    let color: Color
    let onChanged: (Bool) -> Void
    
    var body: some View {
        Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
            .resizable()
            .frame(width: 20, height: 20)
            .foregroundColor(color)
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
            ZStack {
                Color("bg2")
                    .ignoresSafeArea()
                List {
                    ForEach(subjects) { subject in
                        Section(header: Text(subject.name ?? "Unknown")
                            .font(.custom("Poppins-Regular", size: 15))) {
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
                    .listRowBackground(Color.clear)
                }
                .scrollContentBackground(.hidden)
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(LocalizedStringKey("reselect_days"))
                        .font(.custom("Poppins-Regular", size: 18))
                        .foregroundColor(.white)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button(LocalizedStringKey("done")) {
                isPresented = false
            }
                .font(.custom("Poppins-Regular", size: 18))) // Apply Poppins to the done button
        }
    }
}


private func updateDailySubjectsFor(subject: Subjects, with newDays: [Weekday], moc: NSManagedObjectContext) {
    let calendar = Calendar.current
    _ = calendar.startOfDay(for: Date())
    let fetchRequest: NSFetchRequest<DailySubjects> = DailySubjects.fetchRequest()
    fetchRequest.predicate = NSPredicate(format: "subjectName == %@", subject.name ?? "")
    do {
        let existingDailySubjects = try moc.fetch(fetchRequest)
        for day in newDays {
            if let nextDate = getNextDate(for: day) {
                if let dailySubject = existingDailySubjects.first(where: { $0.date == nextDate }) {
                    dailySubject.isCompleted = false
                } else {
                    let dailySubject = DailySubjects(context: moc)
                    dailySubject.subjectName = subject.name
                    dailySubject.date = nextDate
                    dailySubject.isCompleted = false
                    dailySubject.category = "Class"
                }
            }
        }
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

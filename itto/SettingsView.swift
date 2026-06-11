//
//  SettingsView.swift
//  itto
//
//  Created by Duru SAVAŞ on 17/11/2023.
//

import SwiftUI
import CoreData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var moc
    @Environment(\.dismiss) private var dismiss
    
    @State private var defaultInterval = 25
    @State private var defaultBreak = 5
    @State private var showExportSuccess = false
    @State private var showResetAlert = false
    @State private var exportURL: URL?
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Timer Defaults").font(.custom("Poppins-Regular", size: 14))) {
                    Stepper(value: $defaultInterval, in: 5...60, step: 5) {
                        Text("Work interval: \(defaultInterval) min")
                            .font(.custom("Poppins-Regular", size: 16))
                    }
                    Stepper(value: $defaultBreak, in: 1...20, step: 1) {
                        Text("Break: \(defaultBreak) min")
                            .font(.custom("Poppins-Regular", size: 16))
                    }
                    
                    Button("Save Defaults") {
                        UserDefaults.standard.set(defaultInterval, forKey: "defaultInterval")
                        UserDefaults.standard.set(defaultBreak, forKey: "defaultBreak")
                        dismiss()
                    }
                    .font(.custom("Poppins-Regular", size: 16))
                }
                
                Section(header: Text("Data").font(.custom("Poppins-Regular", size: 14))) {
                    Button("Export All Data (JSON)") {
                        exportData()
                    }
                    .font(.custom("Poppins-Regular", size: 16))
                    
                    Button("Export Deadlines to Calendar (.ics)") {
                        exportDeadlinesToICS()
                    }
                    .font(.custom("Poppins-Regular", size: 16))
                    
                    if let url = exportURL {
                        ShareLink(item: url) {
                            Label("Share Exported File", systemImage: "square.and.arrow.up")
                                .font(.custom("Poppins-Regular", size: 16))
                        }
                    }
                    
                    Button(role: .destructive) {
                        showResetAlert = true
                    } label: {
                        Text("Reset All Data")
                            .font(.custom("Poppins-Regular", size: 16))
                    }
                }
                
                Section {
                    Text("itto v1.0 • Academic organization made simple")
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(.secondary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color("bg2"), Color("bg1")]),
                    startPoint: .center,
                    endPoint: .topTrailing
                )
                .ignoresSafeArea()
            )
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Settings")
                        .font(.custom("Poppins-SemiBold", size: 20))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.custom("Poppins-Regular", size: 16))
                }
            }
            .onAppear {
                defaultInterval = UserDefaults.standard.integer(forKey: "defaultInterval")
                if defaultInterval == 0 { defaultInterval = 25 }
                defaultBreak = UserDefaults.standard.integer(forKey: "defaultBreak")
                if defaultBreak == 0 { defaultBreak = 5 }
            }
            .alert("Reset all data?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    resetAllData()
                }
            } message: {
                Text("This will permanently delete all your classes, exams, projects, reports, and schedules. This action cannot be undone.")
            }
            .alert("Export complete", isPresented: $showExportSuccess) {
                Button("OK") {}
            }
        }
    }
    
    private func exportData() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        var export: [String: Any] = [:]
        
        // Subjects
        let subjectsFetch: NSFetchRequest<Subjects> = Subjects.fetchRequest()
        if let subjects = try? moc.fetch(subjectsFetch) {
            export["subjects"] = subjects.map { s in
                [
                    "id": s.id?.uuidString ?? "",
                    "name": s.name ?? "",
                    "color": s.color ?? "",
                    "days": s.days as? [String] ?? []
                ]
            }
        }
        
        // Exams
        let examsFetch: NSFetchRequest<Exams> = Exams.fetchRequest()
        if let exams = try? moc.fetch(examsFetch) {
            export["exams"] = exams.map { e in
                [
                    "id": e.id?.uuidString ?? "",
                    "name": e.name ?? "",
                    "examName": e.examName ?? "",
                    "color": e.color ?? "",
                    "topics": e.topics as? [String] ?? [],
                    "dueDate": e.dueDate?.ISO8601Format() ?? ""
                ]
            }
        }
        
        // Projects
        let projectsFetch: NSFetchRequest<Projects> = Projects.fetchRequest()
        if let projects = try? moc.fetch(projectsFetch) {
            export["projects"] = projects.map { p in
                [
                    "id": p.id?.uuidString ?? "",
                    "name": p.name ?? "",
                    "color": p.color ?? "",
                    "topics": p.topics as? [String] ?? [],
                    "dueDate": p.dueDate?.ISO8601Format() ?? ""
                ]
            }
        }
        
        // Reports
        let reportsFetch: NSFetchRequest<Report> = Report.fetchRequest()
        if let reports = try? moc.fetch(reportsFetch) {
            export["reports"] = reports.map { r in
                [
                    "date": r.date?.ISO8601Format() ?? "",
                    "subjectName": r.subjectName ?? "",
                    "totalTime": r.totalTime,
                    "desc": r.desc ?? ""
                ]
            }
        }
        
        // DailySubjects (optional)
        let dailyFetch: NSFetchRequest<DailySubjects> = DailySubjects.fetchRequest()
        if let dailies = try? moc.fetch(dailyFetch) {
            export["dailySubjects"] = dailies.map { d in
                [
                    "subjectName": d.subjectName ?? "",
                    "category": d.category ?? "",
                    "date": d.date?.ISO8601Format() ?? "",
                    "color": d.color ?? "",
                    "topics": d.topics as? [String] ?? []
                ]
            }
        }
        
        do {
            let data = try JSONSerialization.data(withJSONObject: export, options: .prettyPrinted)
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("itto_export_\(Date().timeIntervalSince1970).json")
            try data.write(to: url)
            exportURL = url
            showExportSuccess = true
        } catch {
            print("Export failed: \(error)")
        }
    }
    
    private func resetAllData() {
        let entities = ["Subjects", "Exams", "Projects", "Report", "DailySubjects"]
        for entity in entities {
            let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
            let delete = NSBatchDeleteRequest(fetchRequest: fetch)
            _ = try? moc.execute(delete)
        }
        try? moc.save()
        dismiss()
    }
    
    private func exportDeadlinesToICS() {
        var ics = """
        BEGIN:VCALENDAR
        VERSION:2.0
        PRODID:-//itto//Academic Deadlines//EN
        CALSCALE:GREGORIAN
        METHOD:PUBLISH
        """
        
        // Exams with due dates
        let examsFetch: NSFetchRequest<Exams> = Exams.fetchRequest()
        if let exams = try? moc.fetch(examsFetch) {
            for exam in exams where exam.dueDate != nil {
                let uid = exam.id?.uuidString ?? UUID().uuidString
                let summary = exam.examName ?? exam.name ?? "Exam"
                let due = exam.dueDate!
                let dateStr = due.icsDateString
                ics += """
                
                BEGIN:VEVENT
                UID:\(uid)-exam@itto.app
                DTSTAMP:\(Date().icsDateString)T000000Z
                DTSTART;VALUE=DATE:\(dateStr)
                DTEND;VALUE=DATE:\(dateStr)
                SUMMARY:\(summary) (Exam)
                DESCRIPTION:Deadline for exam: \(summary)
                END:VEVENT
                """
            }
        }
        
        // Projects with due dates
        let projectsFetch: NSFetchRequest<Projects> = Projects.fetchRequest()
        if let projects = try? moc.fetch(projectsFetch) {
            for project in projects where project.dueDate != nil {
                let uid = project.id?.uuidString ?? UUID().uuidString
                let summary = project.name ?? "Project"
                let due = project.dueDate!
                let dateStr = due.icsDateString
                ics += """
                
                BEGIN:VEVENT
                UID:\(uid)-project@itto.app
                DTSTAMP:\(Date().icsDateString)T000000Z
                DTSTART;VALUE=DATE:\(dateStr)
                DTEND;VALUE=DATE:\(dateStr)
                SUMMARY:\(summary) (Project)
                DESCRIPTION:Deadline for project: \(summary)
                END:VEVENT
                """
            }
        }
        
        ics += "\nEND:VCALENDAR"
        
        do {
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("itto_deadlines_\(Date().timeIntervalSince1970).ics")
            try ics.write(to: url, atomically: true, encoding: .utf8)
            exportURL = url
            showExportSuccess = true
        } catch {
            print("ICS export failed: \(error)")
        }
    }
}

extension Date {
    var icsDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter.string(from: self)
    }
}

#Preview {
    SettingsView()
}
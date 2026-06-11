//
//  SettingsView.swift
//  itto
//
//  Created by Duru SAVAŞ on 17/11/2023.
//

import SwiftUI
import CoreData
import UserNotifications

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var moc
    @Environment(\.dismiss) private var dismiss

    @FetchRequest(sortDescriptors: []) var exams: FetchedResults<Exams>
    @FetchRequest(sortDescriptors: []) var projects: FetchedResults<Projects>
    @FetchRequest(sortDescriptors: []) var subjects: FetchedResults<Subjects>
    @FetchRequest(sortDescriptors: []) var reports: FetchedResults<Report>

    @AppStorage("defaultInterval") private var defaultInterval = 25
    @AppStorage("defaultBreak") private var defaultBreak = 5

    @State private var showResetConfirmation = false
    @State private var exportedURL: URL?
    @State private var showExportSheet = false
    @State private var icsURL: URL?
    @State private var showICSExportSheet = false

    let intervals = [15, 20, 25, 30, 35, 40, 45, 50, 55, 60]
    let breaks = [5, 10, 15, 20]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bg2.ignoresSafeArea()

                Form {
                    Section("Timer Defaults") {
                        Picker("Default interval", selection: $defaultInterval) {
                            ForEach(intervals, id: \.self) { min in
                                Text("\(min) min").tag(min)
                            }
                        }
                        .listRowBackground(Color.gray.opacity(0.1))

                        Picker("Default break", selection: $defaultBreak) {
                            ForEach(breaks, id: \.self) { min in
                                Text("\(min) min").tag(min)
                            }
                        }
                        .listRowBackground(Color.gray.opacity(0.1))
                    }

                    Section("Export") {
                        Button("Export data as JSON") {
                            if let url = buildJSONExport() {
                                exportedURL = url
                                showExportSheet = true
                            }
                        }
                        .listRowBackground(Color.gray.opacity(0.1))

                        Button("Export deadlines as .ics") {
                            if let url = buildICSExport() {
                                icsURL = url
                                showICSExportSheet = true
                            }
                        }
                        .listRowBackground(Color.gray.opacity(0.1))
                    }

                    Section {
                        Button("Reset all data", role: .destructive) {
                            showResetConfirmation = true
                        }
                        .listRowBackground(Color.gray.opacity(0.1))
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Settings")
                        .font(.custom("Poppins-Regular", size: 23))
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.custom("Poppins-Regular", size: 16))
                }
            }
            .confirmationDialog(
                "Reset all data?",
                isPresented: $showResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Reset", role: .destructive) { resetAllData() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all subjects, exams, projects, and reports.")
            }
            .sheet(isPresented: $showExportSheet) {
                if let url = exportedURL {
                    ShareSheet(activityItems: [url])
                }
            }
            .sheet(isPresented: $showICSExportSheet) {
                if let url = icsURL {
                    ShareSheet(activityItems: [url])
                }
            }
        }
    }

    // MARK: - Export

    private func buildJSONExport() -> URL? {
        let subjectData: [[String: Any]] = subjects.compactMap { s in
            guard let name = s.name else { return nil }
            return ["name": name, "color": s.color ?? "", "days": (s.days as? [String]) ?? []]
        }
        let examData: [[String: Any]] = exams.compactMap { e in
            guard let name = e.examName else { return nil }
            var dict: [String: Any] = [
                "examName": name,
                "color": e.color ?? "",
                "topics": (e.topics as? [String]) ?? []
            ]
            if let due = e.dueDate {
                dict["dueDate"] = due.formatted(date: .long, time: .omitted)
            }
            return dict
        }
        let projectData: [[String: Any]] = projects.compactMap { p in
            guard let name = p.name else { return nil }
            var dict: [String: Any] = [
                "name": name,
                "color": p.color ?? "",
                "topics": (p.topics as? [String]) ?? []
            ]
            if let due = p.dueDate {
                dict["dueDate"] = due.formatted(date: .long, time: .omitted)
            }
            return dict
        }
        let reportData: [[String: Any]] = reports.compactMap { r in
            guard let name = r.subjectName else { return nil }
            return [
                "subjectName": name,
                "totalTime": Int(r.totalTime),
                "date": r.date?.formatted() ?? "",
                "desc": r.desc ?? ""
            ]
        }

        let payload: [String: Any] = [
            "subjects": subjectData,
            "exams": examData,
            "projects": projectData,
            "reports": reportData
        ]

        guard let data = try? JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted) else { return nil }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("itto_export.json")
        try? data.write(to: url)
        return url
    }

    private func buildICSExport() -> URL? {
        var lines = ["BEGIN:VCALENDAR", "VERSION:2.0", "PRODID:-//itto//itto//EN"]

        for exam in exams {
            guard let due = exam.dueDate, let name = exam.examName else { continue }
            lines += [
                "BEGIN:VEVENT",
                "DTSTART;VALUE=DATE:\(due.icsDateString)",
                "DTEND;VALUE=DATE:\(due.icsDateString)",
                "SUMMARY:\(name) Exam Due",
                "END:VEVENT"
            ]
        }
        for project in projects {
            guard let due = project.dueDate, let name = project.name else { continue }
            lines += [
                "BEGIN:VEVENT",
                "DTSTART;VALUE=DATE:\(due.icsDateString)",
                "DTEND;VALUE=DATE:\(due.icsDateString)",
                "SUMMARY:\(name) Project Due",
                "END:VEVENT"
            ]
        }

        lines.append("END:VCALENDAR")
        let content = lines.joined(separator: "\r\n")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("itto_deadlines.ics")
        try? content.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    // MARK: - Reset

    private func resetAllData() {
        for entity in ["Report", "DailySubjects", "Exams", "Projects", "Subjects"] {
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
            _ = try? moc.execute(deleteRequest)
        }
        try? moc.save()
        moc.reset()
    }
}

// MARK: - Helpers

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

extension Date {
    var icsDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter.string(from: self)
    }
}

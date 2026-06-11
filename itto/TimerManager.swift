//
//  TimerManager.swift
//  itto
//
//  Basic extracted timer state and logic for better maintainability.
//  ContentView can observe this in future iterations.
//

import Foundation
import SwiftUI
import UserNotifications

@Observable
final class TimerManager {
    var intervalNumber = 4
    var intervalTime = 30
    var breakTime = 5
    
    var countdownTime = 0
    var timerIsPaused = true
    var onBreak = false
    var currentInterval = 1
    var totalWorkTime = 0
    var timerStarted = false
    var chosenSubject: String?
    var timerStartDate: Date?
    
    private var timer: Timer?
    
    // Persistence keys (shared with previous implementation)
    private let stateKey = "itto_timer_state_v1"
    
    init() {
        loadDefaults()
        restoreState()
    }
    
    func loadDefaults() {
        let ud = UserDefaults.standard
        if ud.integer(forKey: "defaultInterval") > 0 {
            intervalTime = ud.integer(forKey: "defaultInterval")
        }
        if ud.integer(forKey: "defaultBreak") > 0 {
            breakTime = ud.integer(forKey: "defaultBreak")
        }
    }
    
    func start() {
        timerStartDate = Date()
        timer?.invalidate()
        currentInterval = 1
        onBreak = false
        countdownTime = intervalTime * 60
        timerIsPaused = false
        timerStarted = true
        totalWorkTime = 0
        
        scheduleNextNotification()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.tick()
            }
        }
        
        saveState()
    }
    
    func pause() {
        timer?.invalidate()
        timerIsPaused = true
        saveState()
    }
    
    func resume() {
        timerIsPaused = false
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.tick()
            }
        }
        saveState()
    }
    
    func stop() {
        timer?.invalidate()
        timerStarted = false
        timerIsPaused = true
        countdownTime = 0
        clearState()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    private func tick() {
        if countdownTime > 0 {
            countdownTime -= 1
            if !onBreak {
                totalWorkTime += 1
            }
            if countdownTime % 5 == 0 {
                saveState()
            }
        } else {
            handleEndOfInterval()
        }
    }
    
    private func handleEndOfInterval() {
        if onBreak {
            currentInterval += 1
            if currentInterval <= intervalNumber {
                onBreak = false
                countdownTime = intervalTime * 60
                scheduleNextNotification()
            } else {
                stop()
                scheduleNotification(message: "timer_is_over_message", delay: 1)
                return
            }
        } else {
            onBreak = true
            countdownTime = breakTime * 60
            scheduleNotification(message: "time_for_break_message", delay: 2)
            scheduleNotification(message: "starting_next_interval_message", delay: TimeInterval(breakTime * 60))
        }
        saveState()
    }
    
    // Notification helpers (simplified from previous)
    private func scheduleNextNotification() {
        scheduleNotification(message: "time_for_break_message", delay: TimeInterval(intervalTime * 60))
    }
    
    private func scheduleNotification(message: String, delay: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("timer_notification_title", comment: "Timer Notification")
        content.body = NSLocalizedString(message, comment: "Notification message")
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(delay, 0.5), repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
    
    // Persistence (kept compatible)
    func saveState() {
        let state: [String: Any] = [
            "intervalNumber": intervalNumber,
            "intervalTime": intervalTime,
            "breakTime": breakTime,
            "chosenSubject": chosenSubject ?? "",
            "timerStarted": timerStarted,
            "timerIsPaused": timerIsPaused,
            "onBreak": onBreak,
            "currentInterval": currentInterval,
            "totalWorkTime": totalWorkTime,
            "timerStartDate": timerStartDate?.timeIntervalSince1970 ?? 0,
            "countdownTime": countdownTime
        ]
        if let data = try? JSONSerialization.data(withJSONObject: state) {
            UserDefaults.standard.set(data, forKey: stateKey)
        }
    }
    
    private func restoreState() {
        guard let data = UserDefaults.standard.data(forKey: stateKey),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
        
        if let startTs = dict["timerStartDate"] as? TimeInterval, startTs > 0 {
            let start = Date(timeIntervalSince1970: startTs)
            if Date().timeIntervalSince(start) > 3 * 3600 {
                clearState()
                return
            }
        }
        
        intervalNumber = dict["intervalNumber"] as? Int ?? 4
        intervalTime = dict["intervalTime"] as? Int ?? 30
        breakTime = dict["breakTime"] as? Int ?? 5
        let subj = dict["chosenSubject"] as? String ?? ""
        chosenSubject = subj.isEmpty ? nil : subj
        timerStarted = dict["timerStarted"] as? Bool ?? false
        timerIsPaused = dict["timerIsPaused"] as? Bool ?? true
        onBreak = dict["onBreak"] as? Bool ?? false
        currentInterval = dict["currentInterval"] as? Int ?? 1
        totalWorkTime = dict["totalWorkTime"] as? Int ?? 0
        countdownTime = dict["countdownTime"] as? Int ?? 0
        
        if let startTs = dict["timerStartDate"] as? TimeInterval, startTs > 0 {
            timerStartDate = Date(timeIntervalSince1970: startTs)
        }
    }
    
    private func clearState() {
        UserDefaults.standard.removeObject(forKey: stateKey)
    }
}
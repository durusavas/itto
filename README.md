# 📚 itto

### Your Academic Organization Simplified

Moving to France for college introduced me to a challenging and unfamiliar school system. With constantly changing class schedules, staying organized was a significant hurdle. This inspired me to develop itto, an app crafted to simplify academic organization for students facing similar challenges.

**itto** is a minimalist, user-focused app designed to streamline academic management. From scheduling classes to tracking exams and managing projects, **itto** has all the tools you need to stay organized and excel in your studies. 🎓 

---

## ✨ Features

- 🗓️ **Schedule Management**  
  Organize your classes, projects, and exams with ease. Customize each item with unique colors and plan your academic week effortlessly.

- 📅 **Today View**  
  Get a personalized daily overview of your tasks. Stay on top of what to study, review, or prepare for with ease.

- 🔄 **Weekly Updates**  
  Adjust your class schedule on the fly with weekly updates, ensuring your timetable is always accurate.

- ⏱️ **Customizable Study Timer**  
  Boost productivity with a Pomodoro-style timer and track your time with intuitive bar chart reports.

- 📊 **Visual Reports & Analytics**  
  Analyze your study patterns and project hours with clean and insightful charts.

- 🌐 **Core Data Integration**  
  All your information is safely stored locally using Core Data, with real-time sync across your Apple devices.

---

## 📸 Screenshots

![Frame 7](https://github.com/user-attachments/assets/a4a4434f-ea1a-45a1-ac1d-1a96eedb981f)

![Frame 8](https://github.com/user-attachments/assets/31062c89-a52b-42ec-85f5-2e2d0fb16b6a)

![Frame 9](https://github.com/user-attachments/assets/7b1f6cd8-ab0d-4ee1-9aad-191552ae659b)

---

## 🖼️ Views Overview

### **🏠 MainView**
- Acts as the central hub for navigation.
- Contains four primary tabs:
  1. **Today**: View your daily academic priorities.
  2. **Timer**: Manage your study sessions and track focus time.
  3. **Subjects**: Add, edit, and organize your classes, exams, and projects.
  4. **Reports**: Analyze your time usage with detailed visualizations.

---

### **🌟 TodayView**
- Your daily academic assistant.
- **What it Shows**:
  - Classes, projects, and exams scheduled for the day.
  - Checkbox-style tracking for completed tasks.

---

### **⏳ ContentView**
- A Pomodoro-inspired timer helps you focus on studying or working on projects.
- **Features**:
  - 🔔 Notifications to remind you of breaks.
  - 📊 Track progress and sync with your reports.

---

### **📋 SubjectView**
- Displays a list of all active classes, projects, and exams.  
- **Features**:
  - 🖌️ **Customization**: Add colors to differentiate between tasks.
  - 📝 **Quick Management**: Add or edit subjects with ease.

---

### **➕ AddSubjectView**
- Add new classes, exams, or projects.
- **Steps**:
  1. 🏷️ **Set the Name**: Define the subject or activity.
  2. 🎨 **Pick a Color**: Choose a color to organize visually.
  3. 🗓️ **Schedule**: Select the days and deadlines as needed.

---

### **📈 ReportView**
- Gain insights into your time management.
- **Visual Charts**:
  - Bar charts display time spent on tasks across a week.
  - Filter by subject, project, or exam for a deeper dive into your efforts.

---

## 🏛️ Architecture

### **📦 Models**
- **Subjects**: Represents classes with properties like name, color, and schedule.
- **Exams**: Stores exam-related information, including topics and deadlines.
- **Projects**: Tracks ongoing projects with progress and deadlines.
- **DailySubjects**: A dynamic entity for tracking day-to-day academic activities.

### **📂 Data Persistence**
itto uses **Core Data** for efficient and reliable data management. Core Data enables local data storage, offline availability, and seamless integration with SwiftUI’s declarative approach.

### Key Features of Core Data in itto:
- **Seamless Integration**: Directly fetch and update data in SwiftUI views using `@FetchRequest`.
- **Lazy Loading**: Only fetches data when needed, improving performance.
- **Offline Support**: All data is stored locally, ensuring itto works even without an internet connection.
  
## 🚀 Installation

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/durusavas/itto.git
   cd itto
---

## 📜 License

This project is licensed under the **MIT License**. See the `LICENSE` file for details.

---

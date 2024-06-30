//
//  DailySubjects+CoreDataProperties.swift
//  
//
//  Created by Duru SAVAŞ on 30/06/2024.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension DailySubjects {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DailySubjects> {
        return NSFetchRequest<DailySubjects>(entityName: "DailySubjects")
    }

    @NSManaged public var category: String?
    @NSManaged public var date: Date?
    @NSManaged public var isCompleted: Bool
    @NSManaged public var subjectName: String?
    @NSManaged public var topics: NSObject?
    @NSManaged public var topicsCompleted: NSObject?

}

extension DailySubjects : Identifiable {

}

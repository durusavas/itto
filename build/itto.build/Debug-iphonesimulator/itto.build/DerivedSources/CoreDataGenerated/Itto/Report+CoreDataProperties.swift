//
//  Report+CoreDataProperties.swift
//  
//
//  Created by Duru SAVAŞ on 21/01/2024.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension Report {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Report> {
        return NSFetchRequest<Report>(entityName: "Report")
    }

    @NSManaged public var date: Date?
    @NSManaged public var subjectName: String?
    @NSManaged public var totalTime: Int16

}

extension Report : Identifiable {

}

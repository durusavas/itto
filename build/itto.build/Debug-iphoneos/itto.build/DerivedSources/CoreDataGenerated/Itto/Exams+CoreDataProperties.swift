//
//  Exams+CoreDataProperties.swift
//  
//
//  Created by Duru SAVAŞ on 19/10/2024.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension Exams {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Exams> {
        return NSFetchRequest<Exams>(entityName: "Exams")
    }

    @NSManaged public var color: String?
    @NSManaged public var examName: String?
    @NSManaged public var id: UUID?
    @NSManaged public var importance: String?
    @NSManaged public var name: String?
    @NSManaged public var topics: NSObject?

}

extension Exams : Identifiable {

}

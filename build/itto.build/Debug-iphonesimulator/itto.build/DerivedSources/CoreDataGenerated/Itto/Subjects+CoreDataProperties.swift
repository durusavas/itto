//
//  Subjects+CoreDataProperties.swift
//  
//
//  Created by Duru SAVAŞ on 24/02/2024.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension Subjects {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Subjects> {
        return NSFetchRequest<Subjects>(entityName: "Subjects")
    }

    @NSManaged public var color: String?
    @NSManaged public var days: NSObject?
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?

}

extension Subjects : Identifiable {

}

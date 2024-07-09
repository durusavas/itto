//
//  Projects+CoreDataProperties.swift
//  
//
//  Created by Duru SAVAŞ on 09/07/2024.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension Projects {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Projects> {
        return NSFetchRequest<Projects>(entityName: "Projects")
    }

    @NSManaged public var color: String?
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var topics: NSObject?

}

extension Projects : Identifiable {

}

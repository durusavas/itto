//
//  DataController.swift
//  itto
//
//  Created by Duru SAVAŞ on 17/11/2023.
//

import Foundation
import CoreData


class DataController: ObservableObject{
    let container = NSPersistentContainer(name: "Itto") // the actual data being loaded from coredata
    init(){
        container.loadPersistentStores{ description, error in
            if let error = error{
                print("Core data load has failed \(error.localizedDescription)")
                return
            }
            self.container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        }
    }
    
    
}

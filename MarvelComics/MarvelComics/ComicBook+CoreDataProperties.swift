//
//  ComicBook+CoreDataProperties.swift
//  
//
//  Created by Administrator on 06/03/2016.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension ComicBook {

    @NSManaged var bookUrl: String?
    @NSManaged var bookImage: NSData?

}

//
//  ReadingBook+CoreDataProperties.swift
//  
//
//  Created by Leo Lo on 27/5/2021.
//
//

import Foundation
import CoreData


extension ReadingBook {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ReadingBook> {
        return NSFetchRequest<ReadingBook>(entityName: "ReadingBook")
    }

    @NSManaged public var bookName: String?
    @NSManaged public var bookAuthor: String?
    @NSManaged public var bookContent: String?
    @NSManaged public var remainingText: String?

}

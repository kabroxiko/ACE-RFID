//
//  FilamentEntity+CoreDataProperties.swift
//  
//
//  Created by Hugo Araya on 04-07-25.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension FilamentEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<FilamentEntity> {
        return NSFetchRequest<FilamentEntity>(entityName: "FilamentEntity")
    }

    @NSManaged public var bedTemperature: Int32
    @NSManaged public var brand: String?
    @NSManaged public var color: String?
    @NSManaged public var dateAdded: Date?
    @NSManaged public var diameter: Double
    @NSManaged public var fanSpeed: Int32
    @NSManaged public var id: String?
    @NSManaged public var isFinished: Bool
    @NSManaged public var lastUsed: Date?
    @NSManaged public var material: String?
    @NSManaged public var notes: String?
    @NSManaged public var printSpeed: Int32
    @NSManaged public var printTemperature: Int32
    @NSManaged public var remainingWeight: Double
    @NSManaged public var weight: Double

}

extension FilamentEntity : Identifiable {

}

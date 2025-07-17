//
//  CoreDataManager.swift
//  ACE-RFID
//
//  Created by Copilot on 07/03/2025.
//

import Foundation
import CoreData
import UIKit

class CoreDataManager {
    static let shared = CoreDataManager()

    private init() {}

    // MARK: - Core Data Stack

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "FilamentDataModel")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data failed to load store: \(error)")
            }
        }
        return container
    }()

    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    // MARK: - Core Data Operations

    func save() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Failed to save context: \(error)")
            }
        }
    }

    // MARK: - Filament CRUD Operations

    func saveFilament(_ filament: Filament) {
        let entity = NSEntityDescription.entity(forEntityName: "FilamentEntity", in: context)!
        let filamentEntity = NSManagedObject(entity: entity, insertInto: context)

        filamentEntity.setValue(filament.id, forKey: "id")
        filamentEntity.setValue(filament.sku, forKey: "sku")
        filamentEntity.setValue(filament.brand, forKey: "brand")
        filamentEntity.setValue(filament.material, forKey: "material")
        filamentEntity.setValue(filament.color, forKey: "color")
        filamentEntity.setValue(filament.weight, forKey: "weight")
        filamentEntity.setValue(filament.diameter, forKey: "diameter")
        filamentEntity.setValue(Int32(filament.printMinTemperature), forKey: "printMinTemperature")
        filamentEntity.setValue(Int32(filament.printMaxTemperature), forKey: "printMaxTemperature")
        filamentEntity.setValue(Int32(filament.bedMinTemperature), forKey: "bedMinTemperature")
        filamentEntity.setValue(Int32(filament.bedMaxTemperature), forKey: "bedMaxTemperature")
        filamentEntity.setValue(Int32(filament.fanSpeed), forKey: "fanSpeed")
        filamentEntity.setValue(Int32(filament.printSpeed), forKey: "printSpeed")
        filamentEntity.setValue(filament.dateAdded, forKey: "dateAdded")
        filamentEntity.setValue(filament.lastUsed, forKey: "lastUsed")
        filamentEntity.setValue(filament.remainingWeight, forKey: "remainingWeight")
        filamentEntity.setValue(filament.isFinished, forKey: "isFinished")
        filamentEntity.setValue(filament.notes, forKey: "notes")

        save()
    }

    func fetchAllFilaments() -> [Filament] {
        let request = NSFetchRequest<NSManagedObject>(entityName: "FilamentEntity")

        do {
            let entities = try context.fetch(request)
            return entities.compactMap { entity in
                convertEntityToFilament(entity)
            }
        } catch {
            print("Failed to fetch filaments: \(error)")
            return []
        }
    }

    func fetchFilament(by id: String) -> Filament? {
        let request = NSFetchRequest<NSManagedObject>(entityName: "FilamentEntity")
        request.predicate = NSPredicate(format: "id == %@", id)

        do {
            let entities = try context.fetch(request)
            guard let entity = entities.first else { return nil }
            return convertEntityToFilament(entity)
        } catch {
            print("Failed to fetch filament: \(error)")
            return nil
        }
    }

    func updateFilament(_ filament: Filament) {
        let request = NSFetchRequest<NSManagedObject>(entityName: "FilamentEntity")
        request.predicate = NSPredicate(format: "id == %@", filament.id)

        do {
            let entities = try context.fetch(request)
            guard let entity = entities.first else { return }

            entity.setValue(filament.sku, forKey: "sku")
            entity.setValue(filament.brand, forKey: "brand")
            entity.setValue(filament.material, forKey: "material")
            entity.setValue(filament.color, forKey: "color")
            entity.setValue(filament.weight, forKey: "weight")
            entity.setValue(filament.diameter, forKey: "diameter")
            entity.setValue(Int32(filament.printMinTemperature), forKey: "printMaxTemperature")
            entity.setValue(Int32(filament.printMaxTemperature), forKey: "printMaxTemperature")
            entity.setValue(Int32(filament.bedMinTemperature), forKey: "bedMinTemperature")
            entity.setValue(Int32(filament.bedMaxTemperature), forKey: "bedMaxTemperature")
            entity.setValue(Int32(filament.fanSpeed), forKey: "fanSpeed")
            entity.setValue(Int32(filament.printSpeed), forKey: "printSpeed")
            entity.setValue(filament.lastUsed, forKey: "lastUsed")
            entity.setValue(filament.remainingWeight, forKey: "remainingWeight")
            entity.setValue(filament.isFinished, forKey: "isFinished")
            entity.setValue(filament.notes, forKey: "notes")

            save()
        } catch {
            print("Failed to update filament: \(error)")
        }
    }

    func deleteFilament(by id: String) {
        let request = NSFetchRequest<NSManagedObject>(entityName: "FilamentEntity")
        request.predicate = NSPredicate(format: "id == %@", id)

        do {
            let entities = try context.fetch(request)
            for entity in entities {
                context.delete(entity)
            }
            save()
        } catch {
            print("Failed to delete filament: \(error)")
        }
    }

    // MARK: - Helper Methods

    private func convertEntityToFilament(_ entity: NSManagedObject) -> Filament? {
        guard let id = entity.value(forKey: "id") as? String,
              let sku = entity.value(forKey: "sku") as? String,
              let brand = entity.value(forKey: "brand") as? String,
              let material = entity.value(forKey: "material") as? String,
              let color = entity.value(forKey: "color") as? String,
              let dateAdded = entity.value(forKey: "dateAdded") as? Date else {
            return nil
        }

        let weight = entity.value(forKey: "weight") as? Double ?? 0.0
        let diameter = entity.value(forKey: "diameter") as? Double ?? 1.75
        let printMinTemperature = entity.value(forKey: "printMinTemperature") as? Int32 ?? 180
        let printMaxTemperature = entity.value(forKey: "printMaxTemperature") as? Int32 ?? 210
        let bedMinTemperature = entity.value(forKey: "bedMinTemperature") as? Int32 ?? 50
        let bedMaxTemperature = entity.value(forKey: "bedMaxTemperature") as? Int32 ?? 60
        let fanSpeed = entity.value(forKey: "fanSpeed") as? Int32 ?? 100
        let printSpeed = entity.value(forKey: "printSpeed") as? Int32 ?? 50
        let lastUsed = entity.value(forKey: "lastUsed") as? Date
        let remainingWeight = entity.value(forKey: "remainingWeight") as? Double ?? weight
        let isFinished = entity.value(forKey: "isFinished") as? Bool ?? false
        let notes = entity.value(forKey: "notes") as? String

        return Filament(
            id: id,
            sku: sku,
            brand: brand,
            material: material,
            color: color,
            weight: weight,
            diameter: diameter,
            printMinTemperature: Int(printMinTemperature),
            printMaxTemperature: Int(printMaxTemperature),
            bedMinTemperature: Int(bedMinTemperature),
            bedMaxTemperature: Int(bedMaxTemperature),
            fanSpeed: Int(fanSpeed),
            printSpeed: Int(printSpeed),
            dateAdded: dateAdded,
            lastUsed: lastUsed,
            remainingWeight: remainingWeight,
            isFinished: isFinished,
            notes: notes
        )
    }
}

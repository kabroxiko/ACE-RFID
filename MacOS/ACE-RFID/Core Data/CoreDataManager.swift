
import Foundation
import CoreData
import UIKit

class CoreDataManager {
    static let shared = CoreDataManager()

    private init() {}


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


    func save() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Failed to save context: \(error)")
            }
        }
    }


    func saveFilament(_ filament: Filament) {
        let entity = NSEntityDescription.entity(forEntityName: "FilamentEntity", in: context)!
        let filamentEntity = NSManagedObject(entity: entity, insertInto: context)

        filamentEntity.setValue(filament.id, forKey: "id")
        filamentEntity.setValue(filament.sku, forKey: "sku")
        filamentEntity.setValue(filament.brand, forKey: "brand")
        filamentEntity.setValue(filament.material, forKey: "material")
        filamentEntity.setValue(filament.color.name, forKey: "colorName")
        filamentEntity.setValue(filament.color.hex, forKey: "colorHex")
        filamentEntity.setValue(filament.length, forKey: "length")
        filamentEntity.setValue(filament.diameter, forKey: "diameter")
        filamentEntity.setValue(Int32(filament.printMinTemperature), forKey: "printMinTemperature")
        filamentEntity.setValue(Int32(filament.printMaxTemperature), forKey: "printMaxTemperature")
        filamentEntity.setValue(Int32(filament.bedMinTemperature), forKey: "bedMinTemperature")
        filamentEntity.setValue(Int32(filament.bedMaxTemperature), forKey: "bedMaxTemperature")
        filamentEntity.setValue(Int32(filament.fanSpeed), forKey: "fanSpeed")
        filamentEntity.setValue(Int32(filament.printSpeed), forKey: "printSpeed")
        filamentEntity.setValue(filament.dateAdded, forKey: "dateAdded")
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
            entity.setValue(filament.color.name, forKey: "colorName")
            entity.setValue(filament.color.hex, forKey: "colorHex")
            entity.setValue(filament.length, forKey: "length")
            entity.setValue(filament.diameter, forKey: "diameter")
            entity.setValue(Int32(filament.printMinTemperature), forKey: "printMinTemperature")
            entity.setValue(Int32(filament.printMaxTemperature), forKey: "printMaxTemperature")
            entity.setValue(Int32(filament.bedMinTemperature), forKey: "bedMinTemperature")
            entity.setValue(Int32(filament.bedMaxTemperature), forKey: "bedMaxTemperature")
            entity.setValue(Int32(filament.fanSpeed), forKey: "fanSpeed")
            entity.setValue(Int32(filament.printSpeed), forKey: "printSpeed")
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


    private func convertEntityToFilament(_ entity: NSManagedObject) -> Filament? {
        guard let id = entity.value(forKey: "id") as? String,
              let sku = entity.value(forKey: "sku") as? String,
              let brand = entity.value(forKey: "brand") as? String,
              let material = entity.value(forKey: "material") as? String,
              let colorName = entity.value(forKey: "colorName") as? String,
              let colorHex = entity.value(forKey: "colorHex") as? String,
              let dateAdded = entity.value(forKey: "dateAdded") as? Date else {
            return nil
        }

        let length = entity.value(forKey: "length") as? Double ?? 0.0
        let diameter = entity.value(forKey: "diameter") as? Double ?? 1.75
        let printMinTemperature = entity.value(forKey: "printMinTemperature") as? Int32 ?? 180
        let printMaxTemperature = entity.value(forKey: "printMaxTemperature") as? Int32 ?? 210
        let bedMinTemperature = entity.value(forKey: "bedMinTemperature") as? Int32 ?? 50
        let bedMaxTemperature = entity.value(forKey: "bedMaxTemperature") as? Int32 ?? 60
        let fanSpeed = entity.value(forKey: "fanSpeed") as? Int32 ?? 100
        let printSpeed = entity.value(forKey: "printSpeed") as? Int32 ?? 50
        let notes = entity.value(forKey: "notes") as? String

        return Filament(
            id: id,
            sku: sku,
            brand: brand,
            material: material,
            color: Color(name: colorName, hex: colorHex),
            length: length,
            diameter: diameter,
            printMinTemperature: Int(printMinTemperature),
            printMaxTemperature: Int(printMaxTemperature),
            bedMinTemperature: Int(bedMinTemperature),
            bedMaxTemperature: Int(bedMaxTemperature),
            fanSpeed: Int(fanSpeed),
            printSpeed: Int(printSpeed),
            dateAdded: dateAdded,
            notes: notes
        )
    }
}

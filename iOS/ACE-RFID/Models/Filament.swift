//
//  Filament.swift
//  ACE-RFID
//
//  Created by Copilot on 07/03/2025.
//

import Foundation

/// Represents a 3D printing filament with all its properties
struct Filament {
    let id: String
    var brand: String
    var material: String
    var color: String
    var weight: Double // in grams
    var diameter: Double // in mm (typically 1.75 or 3.0)
    var printTemperature: Int // in Celsius
    var bedTemperature: Int // in Celsius
    var fanSpeed: Int // percentage (0-100)
    var printSpeed: Int // in mm/s
    var dateAdded: Date
    var lastUsed: Date?
    var remainingWeight: Double // in grams
    var isFinished: Bool
    var notes: String?

    init(id: String = UUID().uuidString,
         brand: String,
         material: String,
         color: String,
         weight: Double,
         diameter: Double = 1.75,
         printTemperature: Int,
         bedTemperature: Int,
         fanSpeed: Int = 100,
         printSpeed: Int = 50,
         dateAdded: Date = Date(),
         lastUsed: Date? = nil,
         remainingWeight: Double? = nil,
         isFinished: Bool = false,
         notes: String? = nil) {

        self.id = id
        self.brand = brand
        self.material = material
        self.color = color
        self.weight = weight
        self.diameter = diameter
        self.printTemperature = printTemperature
        self.bedTemperature = bedTemperature
        self.fanSpeed = fanSpeed
        self.printSpeed = printSpeed
        self.dateAdded = dateAdded
        self.lastUsed = lastUsed
        self.remainingWeight = remainingWeight ?? weight
        self.isFinished = isFinished
        self.notes = notes
    }
}

// MARK: - Filament Material Types
extension Filament {
    enum Material: String, CaseIterable {
        case pla = "PLA"
        case abs = "ABS"
        case petg = "PETG"
        case tpu = "TPU"
        case wood = "Wood"
        case metal = "Metal"
        case carbon = "Carbon Fiber"
        case glow = "Glow in the Dark"
        case water = "Water Soluble"
        case other = "Other"

        var defaultPrintTemperature: Int {
            switch self {
            case .pla: return 200
            case .abs: return 240
            case .petg: return 230
            case .tpu: return 220
            case .wood: return 200
            case .metal: return 210
            case .carbon: return 250
            case .glow: return 200
            case .water: return 200
            case .other: return 200
            }
        }

        var defaultBedTemperature: Int {
            switch self {
            case .pla: return 60
            case .abs: return 80
            case .petg: return 70
            case .tpu: return 50
            case .wood: return 60
            case .metal: return 60
            case .carbon: return 80
            case .glow: return 60
            case .water: return 60
            case .other: return 60
            }
        }
    }
}

// MARK: - Filament Brand Types
extension Filament {
    enum Brand: String, CaseIterable {
        case anycubic = "Anycubic"
        case hatchbox = "Hatchbox"
        case overture = "Overture"
        case sunlu = "SUNLU"
        case esun = "eSUN"
        case polymaker = "Polymaker"
        case prusament = "Prusament"
        case other = "Other"
    }
}

// MARK: - JSON Conversion for NFC Storage
extension Filament: Codable {
    /// Convert filament data to JSON string for NFC tag storage
    func toJSONString() -> String? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        do {
            let data = try encoder.encode(self)
            return String(data: data, encoding: .utf8)
        } catch {
            print("Error encoding filament to JSON: \(error)")
            return nil
        }
    }

    /// Create filament from JSON string read from NFC tag
    static func fromJSONString(_ jsonString: String) -> Filament? {
        guard let data = jsonString.data(using: .utf8) else { return nil }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            return try decoder.decode(Filament.self, from: data)
        } catch {
            print("Error decoding filament from JSON: \(error)")
            return nil
        }
    }
}

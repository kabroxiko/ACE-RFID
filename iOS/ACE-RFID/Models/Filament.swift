//
//  Filament.swift
//  ACE-RFID
//
//  Created by Copilot on 07/03/2025.
//

import Foundation
import UIKit

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

        var defaultFanSpeed: Int {
            switch self {
            case .pla: return 100
            case .abs: return 0
            case .petg: return 50
            case .tpu: return 30
            case .wood: return 100
            case .metal: return 80
            case .carbon: return 50
            case .glow: return 100
            case .water: return 100
            case .other: return 50
            }
        }

        var defaultPrintSpeed: Int {
            switch self {
            case .pla: return 60
            case .abs: return 50
            case .petg: return 50
            case .tpu: return 25
            case .wood: return 40
            case .metal: return 45
            case .carbon: return 40
            case .glow: return 50
            case .water: return 40
            case .other: return 50
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
        case bambu = "Bambu Lab"
        case creality = "Creality"
        case amazon = "Amazon Basics"
        case geeetech = "GEEETECH"
        case jayo = "JAYO"
        case tecbears = "TECBEARS"
        case solutech = "SOLUTECH"
        case inland = "Inland"
        case tianse = "TIANSE"
        case reprapper = "RepRapper"
        case generic = "Generic"
        case other = "Other"

        var defaultWeight: Double {
            return 1000.0 // 1kg standard
        }

        var defaultDiameter: Double {
            return 1.75 // Most common diameter
        }

        /// Returns brands sorted alphabetically by display name
        static var sortedCases: [Brand] {
            return allCases.sorted { $0.rawValue.localizedCaseInsensitiveCompare($1.rawValue) == .orderedAscending }
        }
    }
}

// MARK: - Filament Color Types
extension Filament {
    enum Color: String, CaseIterable {
        case black = "Black"
        case white = "White"
        case red = "Red"
        case blue = "Blue"
        case green = "Green"
        case yellow = "Yellow"
        case orange = "Orange"
        case purple = "Purple"
        case pink = "Pink"
        case gray = "Gray"
        case brown = "Brown"
        case transparent = "Transparent"
        case translucent = "Translucent"
        case silver = "Silver"
        case gold = "Gold"
        case bronze = "Bronze"
        case copper = "Copper"
        case rainbow = "Rainbow"
        case glow = "Glow"
        case marble = "Marble"
        case wood = "Wood"
        case carbon = "Carbon"
        case other = "Other"

        var displayColor: UIColor {
            switch self {
            case .black: return UIColor.black
            case .white: return UIColor.white
            case .red: return UIColor.red
            case .blue: return UIColor.blue
            case .green: return UIColor.green
            case .yellow: return UIColor.yellow
            case .orange: return UIColor.orange
            case .purple: return UIColor.purple
            case .pink: return UIColor.systemPink
            case .gray: return UIColor.gray
            case .brown: return UIColor.brown
            case .transparent: return UIColor.clear
            case .translucent: return UIColor.systemGray6
            case .silver: return UIColor.lightGray
            case .gold: return UIColor.systemYellow
            case .bronze: return UIColor.brown
            case .copper: return UIColor.systemOrange
            case .rainbow: return UIColor.systemIndigo
            case .glow: return UIColor.systemGreen
            case .marble: return UIColor.systemGray
            case .wood: return UIColor.brown
            case .carbon: return UIColor.darkGray
            case .other: return UIColor.systemGray
            }
        }
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

// MARK: - Predefined Values
extension Filament {
    /// Temperature values in multiples of 5 (160-300°C)
    static var temperatureOptions: [Int] {
        return Array(stride(from: 160, through: 300, by: 5))
    }

    /// Bed temperature values in multiples of 5 (0-120°C)
    static var bedTemperatureOptions: [Int] {
        return Array(stride(from: 0, through: 120, by: 5))
    }

    /// Fan speed values in multiples of 5 (0-100%)
    static var fanSpeedOptions: [Int] {
        return Array(stride(from: 0, through: 100, by: 5))
    }

    /// Print speed values in multiples of 5 (10-150 mm/s)
    static var printSpeedOptions: [Int] {
        return Array(stride(from: 10, through: 150, by: 5))
    }

    /// Common weight values in grams
    static var weightOptions: [Double] {
        return [250, 500, 750, 1000, 1200, 1500, 2000, 2300, 2500, 3000, 5000, 10000]
    }

    /// Common diameter values in mm
    static var diameterOptions: [Double] {
        return [1.75, 2.85, 3.0]
    }
}

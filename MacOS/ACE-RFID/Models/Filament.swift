
import Foundation
import UIKit

/// Represents a 3D printing filament with all its properties
struct Filament {
    let id: String
    var sku: String
    var brand: String
    var material: String
    var color: Color
    var length: Double // in meters
    var diameter: Double // in mm (typically 1.75 or 3.0)
    var printMinTemperature: Int // in Celsius
    var printMaxTemperature: Int // in Celsius
    var bedMinTemperature: Int // in Celsius
    var bedMaxTemperature: Int // in Celsius
    var fanSpeed: Int // percentage (0-100)
    var printSpeed: Int // in mm/s
    var dateAdded: Date
    var notes: String?

    /// Converts length (meters) to weight (grams) using a lookup table
    var convertedWeight: Int {
        // Example table: 330m = 1000g, 165m = 500g, etc
        let table: [(length: Double, weight: Int)] = [
            (330, 1000),
            (165, 500),
            (82.5, 250),
            (66, 200),
            (33, 100)
        ]
        for entry in table {
            if length >= entry.length {
                return entry.weight
            }
        }
        // Fallback: proportional conversion (default 330m = 1000g)
        return Int(round(length * (1000.0 / 330.0)))
    }

    init(id: String = UUID().uuidString,
         sku: String,
         brand: String,
         material: String,
         color: Color,
         length: Double,
         diameter: Double = 1.75,
         printMinTemperature: Int,
         printMaxTemperature: Int,
         bedMinTemperature: Int,
         bedMaxTemperature: Int,
         fanSpeed: Int = 100,
         printSpeed: Int = 50,
         dateAdded: Date = Date(),
         notes: String? = nil) {

        self.id = id
        self.sku = sku
        self.brand = brand
        self.material = material
        self.color = color
        self.length = length
        self.diameter = diameter
        self.printMinTemperature = printMinTemperature
        self.printMaxTemperature = printMaxTemperature
        self.bedMinTemperature = bedMinTemperature
        self.bedMaxTemperature = bedMaxTemperature
        self.fanSpeed = fanSpeed
        self.printSpeed = printSpeed
        self.dateAdded = dateAdded
        self.notes = notes
    }
}

/// Represents a color with both name and hex value
struct Color: Codable, Equatable {
    var name: String
    var hex: String

    init(name: String, hex: String) {
        self.name = name
        self.hex = hex
    }

    init(name: String, uiColor: UIColor) {
        self.name = name
        self.hex = uiColor.toHexString
    }

    init(hex: String) {
        self.name = hex
        self.hex = hex
    }

    var uiColor: UIColor? {
        return UIColor(hex: self.hex)
    }
}

// MARK: - Filament Material Types
extension Filament {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(sku, forKey: .sku)
        try container.encode(brand, forKey: .brand)
        try container.encode(material, forKey: .material)
        try container.encode(color, forKey: .color)
        try container.encode(length, forKey: .length)
        try container.encode(diameter, forKey: .diameter)
        try container.encode(printMinTemperature, forKey: .printMinTemperature)
        try container.encode(printMaxTemperature, forKey: .printMaxTemperature)
        try container.encode(bedMinTemperature, forKey: .bedMinTemperature)
        try container.encode(bedMaxTemperature, forKey: .bedMaxTemperature)
        try container.encode(fanSpeed, forKey: .fanSpeed)
        try container.encode(printSpeed, forKey: .printSpeed)
        try container.encode(dateAdded, forKey: .dateAdded)
        try container.encode(notes, forKey: .notes)
    }
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

        var defaultMinPrintTemperature: Int {
            switch self {
            case .pla: return 180
            case .abs: return 220
            case .petg: return 210
            case .tpu: return 200
            case .wood: return 180
            case .metal: return 190
            case .carbon: return 230
            case .glow: return 180
            case .water: return 180
            case .other: return 180
            }
        }

        var defaultMaxPrintTemperature: Int {
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

        var defaultMinBedTemperature: Int {
            switch self {
            case .pla: return 50
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

        var defaultMaxBedTemperature: Int {
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

        static var sortedCases: [Brand] {
            let brands = allCases.filter { $0 != .generic }
            let sortedBrands = brands.sorted { $0.rawValue.localizedCaseInsensitiveCompare($1.rawValue) == .orderedAscending }
            return sortedBrands + [.generic]
        }
    }
}

// MARK: - Filament Color Types
extension Filament {
    enum FilamentColorType: String, CaseIterable {
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
        case custom = "Add Custom Color..."

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
            case .custom: return UIColor.systemBlue // Default for custom, will be overridden
            }
        }

        var colorObject: Color {
            switch self {
            case .black: return Color(name: self.rawValue, hex: "#000000")
            case .white: return Color(name: self.rawValue, hex: "#FFFFFF")
            case .red: return Color(name: self.rawValue, hex: "#FF0000")
            case .blue: return Color(name: self.rawValue, hex: "#0000FF")
            case .green: return Color(name: self.rawValue, hex: "#00FF00")
            case .yellow: return Color(name: self.rawValue, hex: "#FFFF00")
            case .orange: return Color(name: self.rawValue, hex: "#FFA500")
            case .purple: return Color(name: self.rawValue, hex: "#800080")
            case .pink: return Color(name: self.rawValue, hex: "#FF69B4")
            case .gray: return Color(name: self.rawValue, hex: "#808080")
            case .brown: return Color(name: self.rawValue, hex: "#A52A2A")
            case .transparent: return Color(name: self.rawValue, hex: "#00000000")
            case .translucent: return Color(name: self.rawValue, hex: "#F5F5F5")
            case .silver: return Color(name: self.rawValue, hex: "#C0C0C0")
            case .gold: return Color(name: self.rawValue, hex: "#FFD700")
            case .bronze: return Color(name: self.rawValue, hex: "#CD7F32")
            case .copper: return Color(name: self.rawValue, hex: "#B87333")
            case .rainbow: return Color(name: self.rawValue, hex: "#6F00FF")
            case .glow: return Color(name: self.rawValue, hex: "#39FF14")
            case .marble: return Color(name: self.rawValue, hex: "#E0DFDB")
            case .wood: return Color(name: self.rawValue, hex: "#C19A6B")
            case .carbon: return Color(name: self.rawValue, hex: "#2D2D2D")
            case .custom: return Color(name: self.rawValue, hex: "#0000FF") // Default for custom
            }
        }

        static var allAvailableColors: [(name: String, color: UIColor)] {
            var colors: [(name: String, color: UIColor)] = []

            for color in FilamentColorType.allCases.filter({ $0 != .custom }) {
                colors.append((color.rawValue, color.displayColor))
            }

            return colors
        }
    }
}

// MARK: - JSON Conversion for NFC Storage
extension Filament: Codable {
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
    static var temperatureMinOptions: [Int] {
        return Array(stride(from: 160, through: 300, by: 5))
    }
    static var temperatureMaxOptions: [Int] {
        return Array(stride(from: 160, through: 300, by: 5))
    }

    static var bedMinTemperatureOptions: [Int] {
        return Array(stride(from: 0, through: 120, by: 5))
    }
    static var bedMaxTemperatureOptions: [Int] {
        return Array(stride(from: 0, through: 120, by: 5))
    }

    static var fanSpeedOptions: [Int] {
        return Array(stride(from: 0, through: 100, by: 5))
    }

    static var printSpeedOptions: [Int] {
        return Array(stride(from: 10, through: 150, by: 5))
    }


    static var weightOptions: [Double] {
        return [250, 500, 750, 1000, 1200, 1500, 2000, 2300, 2500, 3000, 5000, 10000]
    }

    static var diameterOptions: [Double] {
        return [1.75, 2.85, 3.0]
    }
}

extension Filament {
    enum CodingKeys: String, CodingKey {
        case id, sku, brand, material, color, length, diameter, printMinTemperature, printMaxTemperature, bedMinTemperature, bedMaxTemperature, fanSpeed, printSpeed, dateAdded, notes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        sku = try container.decode(String.self, forKey: .sku)
        brand = try container.decode(String.self, forKey: .brand)
        material = try container.decode(String.self, forKey: .material)
        color = try container.decode(Color.self, forKey: .color)
        length = try container.decode(Double.self, forKey: .length)
        diameter = try container.decode(Double.self, forKey: .diameter)
        printMinTemperature = try container.decode(Int.self, forKey: .printMinTemperature)
        printMaxTemperature = try container.decode(Int.self, forKey: .printMaxTemperature)
        bedMinTemperature = try container.decode(Int.self, forKey: .bedMinTemperature)
        bedMaxTemperature = try container.decode(Int.self, forKey: .bedMaxTemperature)
        fanSpeed = try container.decode(Int.self, forKey: .fanSpeed)
        printSpeed = try container.decode(Int.self, forKey: .printSpeed)
        dateAdded = try container.decode(Date.self, forKey: .dateAdded)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
    }
}

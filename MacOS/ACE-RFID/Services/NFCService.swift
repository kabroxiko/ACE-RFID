// Unified NFC interface for iOS (Core NFC) and Mac Catalyst (Serial Port)
import Foundation

#if canImport(CoreNFC)
import CoreNFC
#endif

protocol NFCServiceDelegate: AnyObject {
    func nfcService(didRead data: Data)
    func nfcService(didWrite success: Bool)
    func nfcService(didFail error: Error)
}


class NFCService: NSObject {
    weak var delegate: NFCServiceDelegate?

#if targetEnvironment(macCatalyst)
    // Optionally store port info for future use
    private var port: String?
#endif
    // Set port for macCatalyst (no-op for now, but can be used for device selection)
    func setPort(_ port: String) {
#if targetEnvironment(macCatalyst)
        self.port = port
        let connectionString = "pn532_uart:\(port):115200"
        nfcManager.setConnectionString(connectionString)
#endif
    }


    #if targetEnvironment(macCatalyst)
    let nfcManager = NFCManager()
    #else
    private var session: NFCNDEFReaderSession?
#endif


    func readTag() {
#if targetEnvironment(macCatalyst)
        print("[DEBUG] NFCService.readTag called. port: \(port ?? "nil")")
        print("[DEBUG] NFCService.readTag connectionString: \(nfcManager.debugConnectionString)")
        // Use NFCManager to read UID and card content
        guard nfcManager.isNFCAvailable() else {
            delegate?.nfcService(didFail: NSError(domain: "NFC", code: 0, userInfo: [NSLocalizedDescriptionKey: "NFC not available"]))
            return
        }
        // Read card content (expect 128 bytes for Ultralight)
        if let content = nfcManager.readCardContent(length: 128) {
            delegate?.nfcService(didRead: content)
        } else {
            delegate?.nfcService(didFail: NSError(domain: "NFC", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to read card content"]))
        }
#else
        guard NFCNDEFReaderSession.readingAvailable else {
            delegate?.nfcService(didFail: NSError(domain: "NFC", code: 0, userInfo: [NSLocalizedDescriptionKey: "NFC not available"]))
            return
        }
        session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: true)
        session?.begin()
#endif
    }


    func writeTag(data: Data) {
#if targetEnvironment(macCatalyst)
        guard nfcManager.isNFCAvailable() else {
            delegate?.nfcService(didFail: NSError(domain: "NFC", code: 0, userInfo: [NSLocalizedDescriptionKey: "NFC not available"]))
            return
        }
        let success = nfcManager.writeCardContent(data: data)
        delegate?.nfcService(didWrite: success)
#else
        // Core NFC: writing is limited, but for NTAG21x you can use NFCMiFareTag
        // This is a placeholder for actual implementation
        delegate?.nfcService(didFail: NSError(domain: "NFC", code: 1, userInfo: [NSLocalizedDescriptionKey: "NFC write not implemented"]))
#endif
    }

    // Helper to encode Filament to Data (match Android logic)
    static func encodeFilament(_ filament: Filament) -> Data {
        var buffer = [UInt8](repeating: 0, count: 256)
        // Magic/data len (page 4, offset 16)
        buffer[16] = 0x7B
        buffer[17] = 0x00
        buffer[18] = 0x65
        buffer[19] = 0x00
        // SKU (page 5-8, offset 20, 16 bytes)
        let skuBytes = Array((filament.sku).prefix(16).utf8)
        for i in 0..<skuBytes.count { buffer[20+i] = skuBytes[i] }
        // Brand (page 10-13, offset 40, 16 bytes)
        let brandBytes = Array(filament.brand.prefix(16).utf8)
        for i in 0..<brandBytes.count { buffer[40+i] = brandBytes[i] }
        // Type (page 15-18, offset 60, 16 bytes)
        let typeBytes = Array(filament.material.prefix(16).utf8)
        for i in 0..<typeBytes.count { buffer[60+i] = typeBytes[i] }
        // Color (BGR,  page 20, offset 80, 3 bytes)
        let bgr = colorStringToBGR(filament.color)
        print("[DEBUG] encodeFilament color string: \(filament.color)")
        print("[DEBUG] encodeFilament BGR: \(bgr.0), \(bgr.1), \(bgr.2)")
        buffer[80] = 0xFF // reserved
        buffer[81] = bgr.0
        buffer[82] = bgr.1
        buffer[83] = bgr.2
        print(String(format: "[DEBUG] encodeFilament buffer[80-82]: %02X %02X %02X", buffer[80], buffer[81], buffer[82]))
        // Extruder temp (page 24, offset 96, min/max, 2 bytes each, little-endian)
        let printMinTemp = Int(filament.printMinTemperature)
        buffer[96] = UInt8(printMinTemp & 0xFF)
        buffer[97] = UInt8((printMinTemp >> 8) & 0xFF)
        let printMaxTemp = Int(filament.printMaxTemperature)
        buffer[98] = UInt8(printMaxTemp & 0xFF)
        buffer[99] = UInt8((printMaxTemp >> 8) & 0xFF)
        // Hotbed temp (page 29, offset 116, min/max, 2 bytes each, little-endian)
        let bedMinTemp = Int(filament.bedMinTemperature)
        buffer[116] = UInt8(bedMinTemp & 0xFF)
        buffer[117] = UInt8((bedMinTemp >> 8) & 0xFF)
        let bedMaxTemp = Int(filament.bedMaxTemperature)
        buffer[118] = UInt8(bedMaxTemp & 0xFF)
        buffer[119] = UInt8((bedMaxTemp >> 8) & 0xFF)
        // Filament param (page 30, offset 120, diameter/weight, 2 bytes each, little-endian)
        let diameter = Int(filament.diameter * 100) // e.g. 1.75 -> 175
        buffer[120] = UInt8(diameter & 0xFF)
        buffer[121] = UInt8((diameter >> 8) & 0xFF)
        let weight = Int(filament.weight)
        buffer[122] = UInt8(weight & 0xFF)
        buffer[123] = UInt8((weight >> 8) & 0xFF)
        // Unknown (page 31, offset 124, 4 bytes)
        buffer[124] = 0xE8
        buffer[125] = 0x03
        buffer[126] = 0x00
        buffer[127] = 0x00
        // Debug: print only blocks 16-127 (pages 4-35)
        print("[DEBUG] encodeFilament buffer (blocks of 4 bytes, pages 4-35):")
        for i in stride(from: 16, to: 128, by: 4) {
            let block = buffer[i..<i+4]
            let hexBlock = block.map { String(format: "%02X", $0) }.joined(separator: " ")
            print(String(format: "[%02d-%02d]: %@", i, i+3, hexBlock))
        }
        // Return only pages 4-35 (offsets 16-127, 128 bytes)
        return Data(buffer[16..<128])
    }

    // Helper: Convert color string (e.g. "#00FF00" or "Black") to BGR tuple
    private static func colorStringToBGR(_ color: String) -> (UInt8, UInt8, UInt8) {
        // Hex format: #RRGGBB
        if color.hasPrefix("#") && color.count == 7 {
            let r = UInt8(color[color.index(color.startIndex, offsetBy: 1)...color.index(color.startIndex, offsetBy: 2)], radix: 16) ?? 0
            let g = UInt8(color[color.index(color.startIndex, offsetBy: 3)...color.index(color.startIndex, offsetBy: 4)], radix: 16) ?? 0
            let b = UInt8(color[color.index(color.startIndex, offsetBy: 5)...color.index(color.startIndex, offsetBy: 6)], radix: 16) ?? 0
            return (b, g, r)
        }
        // Named colors (add more as needed)
        switch color.lowercased() {
        case "black": return (0, 0, 0)
        case "white": return (255, 255, 255)
        case "red": return (0, 0, 255)
        case "green": return (0, 255, 0)
        case "blue": return (255, 0, 0)
        default: return (0, 0, 0)
        }
    }

    static func decodeFilament(_ data: Data) -> Filament {
        let buffer = [UInt8](data)
        // Debug: print raw bytes for key fields
        print("[DEBUG] Raw bytes for SKU: ", buffer[4..<20].map { String(format: "%02X", $0) }.joined(separator: " "))
        print("[DEBUG] Raw bytes for Brand: ", buffer[20..<44].map { String(format: "%02X", $0) }.joined(separator: " "))
        print("[DEBUG] Raw bytes for Material: ", buffer[44..<60].map { String(format: "%02X", $0) }.joined(separator: " "))
        print("[DEBUG] Raw bytes for Color: ", buffer[65..<68].map { String(format: "%02X", $0) }.joined(separator: " "))
        print("[DEBUG] Extruder Min bytes: %02X %02X", buffer[80], buffer[81])
        print("[DEBUG] Extruder Max bytes: %02X %02X", buffer[82], buffer[83])
        print("[DEBUG] Bed Min bytes: %02X %02X", buffer[100], buffer[101])
        print("[DEBUG] Bed Max bytes: %02X %02X", buffer[102], buffer[103])
        print("[DEBUG] Weight bytes: %02X %02X", buffer[106], buffer[107])

        func cleanField(_ str: String?) -> String {
            guard let s = str else { return "" }
            return s.replacingOccurrences(of: "\0", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        }
        // SKU: bytes 4..19 (16 bytes)
        let sku = cleanField(String(bytes: buffer[4..<20], encoding: .utf8))
        // Brand: bytes 20..43 (24 bytes)
        let brand = cleanField(String(bytes: buffer[20..<44], encoding: .utf8))
        // Material Name: bytes 44..59 (16 bytes)
        let materialName = cleanField(String(bytes: buffer[44..<60], encoding: .utf8))
        // Color: bytes 65..67 (3 bytes, hex)
        let colorHex = buffer[65..<68].map { String(format: "%02X", $0) }.joined()
        // Extruder Min/Max: bytes 80..81, 82..83 (little-endian, scale 1)
        let extMin = Int(buffer[80]) | (Int(buffer[81]) << 8)
        let extMax = Int(buffer[82]) | (Int(buffer[83]) << 8)
        // Bed Min/Max: bytes 100..101, 102..103 (little-endian, scale 1)
        let bedMin = Int(buffer[100]) | (Int(buffer[101]) << 8)
        let bedMax = Int(buffer[102]) | (Int(buffer[103]) << 8)
        // Weight: bytes 106..107 (little-endian, scale 0.001)
        let weightRaw = Int(buffer[107]) << 8 | Int(buffer[106])
        // Diameter: bytes 120..121 (little-endian, scale 0.01)
        let diameterRaw = Int(buffer[121]) << 8 | Int(buffer[120])
        let diameter = Double(diameterRaw) / 100.0

        // Construct Filament object
        let filament = Filament(
            id: UUID().uuidString,
            sku: sku,
            brand: brand,
            material: materialName,
            color: "#" + colorHex,
            weight: Double(weightRaw),
            diameter: diameter,
            printMinTemperature: extMin,
            printMaxTemperature: extMax,
            bedMinTemperature: bedMin,
            bedMaxTemperature: bedMax,
            lastUsed: nil
        )
        return filament
    }
}

private extension Array where Element == UInt8 {
    func padding(toLength length: Int) -> [UInt8] {
        if count >= length { return Array(self[0..<length]) }
        return self + Array(repeating: 0, count: length - count)
    }
}

// No longer needed: NFCSerialManagerDelegate
@available(iOS 13.0, *)
extension NFCService: NFCNDEFReaderSessionDelegate {
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        delegate?.nfcService(didFail: error)
    }
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        for message in messages {
            for record in message.records {
                delegate?.nfcService(didRead: record.payload)
            }
        }
    }
}

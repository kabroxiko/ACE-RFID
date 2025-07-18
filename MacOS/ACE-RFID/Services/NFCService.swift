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
    private var port: String?
#endif
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
        guard nfcManager.isNFCAvailable() else {
            delegate?.nfcService(didFail: NSError(domain: "NFC", code: 0, userInfo: [NSLocalizedDescriptionKey: "NFC not available"]))
            return
        }
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
        delegate?.nfcService(didFail: NSError(domain: "NFC", code: 1, userInfo: [NSLocalizedDescriptionKey: "NFC write not implemented"]))
#endif
    }

    static func encodeFilament(_ filament: Filament) -> Data {
        var buffer = [UInt8](repeating: 0, count: 256)
        buffer[16] = 0x7B
        buffer[17] = 0x00
        buffer[18] = 0x65
        buffer[19] = 0x00
        let skuBytes = Array((filament.sku).prefix(16).utf8)
        for i in 0..<skuBytes.count { buffer[20+i] = skuBytes[i] }
        let brandBytes = Array(filament.brand.prefix(16).utf8)
        for i in 0..<brandBytes.count { buffer[40+i] = brandBytes[i] }
        let typeBytes = Array(filament.material.prefix(16).utf8)
        for i in 0..<typeBytes.count { buffer[60+i] = typeBytes[i] }
        let bgr = colorStringToBGR(filament.color)
        buffer[80] = 0xFF // reserved
        buffer[81] = bgr.0
        buffer[82] = bgr.1
        buffer[83] = bgr.2
        let printMinTemp = Int(filament.printMinTemperature)
        buffer[96] = UInt8(printMinTemp & 0xFF)
        buffer[97] = UInt8((printMinTemp >> 8) & 0xFF)
        let printMaxTemp = Int(filament.printMaxTemperature)
        buffer[98] = UInt8(printMaxTemp & 0xFF)
        buffer[99] = UInt8((printMaxTemp >> 8) & 0xFF)
        let bedMinTemp = Int(filament.bedMinTemperature)
        buffer[116] = UInt8(bedMinTemp & 0xFF)
        buffer[117] = UInt8((bedMinTemp >> 8) & 0xFF)
        let bedMaxTemp = Int(filament.bedMaxTemperature)
        buffer[118] = UInt8(bedMaxTemp & 0xFF)
        buffer[119] = UInt8((bedMaxTemp >> 8) & 0xFF)
        let diameter = Int(filament.diameter * 100) // e.g. 1.75 -> 175
        buffer[120] = UInt8(diameter & 0xFF)
        buffer[121] = UInt8((diameter >> 8) & 0xFF)
        let length = Int(filament.length * 100) // e.g. 1.75 -> 175
        buffer[122] = UInt8(length & 0xFF)
        buffer[123] = UInt8((length >> 8) & 0xFF)
        buffer[124] = 0xE8
        buffer[125] = 0x03
        buffer[126] = 0x00
        buffer[127] = 0x00
        for i in stride(from: 16, to: 128, by: 4) {
            let block = buffer[i..<i+4]
            let hexBlock = block.map { String(format: "%02X", $0) }.joined(separator: " ")
            print(String(format: "[%02d-%02d]: %@", i, i+3, hexBlock))
        }
        return Data(buffer[16..<128])
    }

    private static func colorStringToBGR(_ color: Color) -> (UInt8, UInt8, UInt8) {
        let hex = color.hex
        if hex.hasPrefix("#") && hex.count == 7 {
            let r = UInt8(hex[hex.index(hex.startIndex, offsetBy: 1)...hex.index(hex.startIndex, offsetBy: 2)], radix: 16) ?? 0
            let g = UInt8(hex[hex.index(hex.startIndex, offsetBy: 3)...hex.index(hex.startIndex, offsetBy: 4)], radix: 16) ?? 0
            let b = UInt8(hex[hex.index(hex.startIndex, offsetBy: 5)...hex.index(hex.startIndex, offsetBy: 6)], radix: 16) ?? 0
            return (b, g, r)
        }
        switch color.name.lowercased() {
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

        func cleanField(_ str: String?) -> String {
            guard let s = str else { return "" }
            return s.replacingOccurrences(of: "\0", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        }
        let sku = cleanField(String(bytes: buffer[4..<20], encoding: .utf8))
        let brand = cleanField(String(bytes: buffer[20..<44], encoding: .utf8))
        let materialName = cleanField(String(bytes: buffer[44..<60], encoding: .utf8))
        let colorHex = buffer[65..<68].map { String(format: "%02X", $0) }.joined()
        let extMin = Int(buffer[80]) | (Int(buffer[81]) << 8)
        let extMax = Int(buffer[82]) | (Int(buffer[83]) << 8)
        let bedMin = Int(buffer[100]) | (Int(buffer[101]) << 8)
        let bedMax = Int(buffer[102]) | (Int(buffer[103]) << 8)
        let lengthRaw = Int(buffer[107]) << 8 | Int(buffer[106])
        let diameterRaw = Int(buffer[121]) << 8 | Int(buffer[120])
        let diameter = Double(diameterRaw) / 100.0

        let filament = Filament(
            id: UUID().uuidString,
            sku: sku,
            brand: brand,
            material: materialName,
            color: Color(name: "Custom", hex: "#" + colorHex),
            length: Double(lengthRaw),
            diameter: diameter,
            printMinTemperature: extMin,
            printMaxTemperature: extMax,
            bedMinTemperature: bedMin,
            bedMaxTemperature: bedMax
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

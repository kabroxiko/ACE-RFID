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
        var bytes = [UInt8]()
        // Example: encode brand, material, color, etc. as fixed-length fields
        let brandBytes = Array(filament.brand.utf8.prefix(20)).padding(toLength: 20)
        let materialBytes = Array(filament.material.utf8.prefix(20)).padding(toLength: 20)
        let colorBytes = Array(filament.color.utf8.prefix(8)).padding(toLength: 8)
        let weightBytes = withUnsafeBytes(of: filament.weight.bitPattern.bigEndian, Array.init)
        bytes += brandBytes + materialBytes + colorBytes + weightBytes
        // Add more fields as needed, matching Android's structure
        return Data(bytes)
    }

    // Helper to decode Data to Filament (match Android logic)
    static func decodeFilament(_ data: Data) -> Filament? {
        // Example: decode fixed-length fields
        guard data.count >= 48 else { return nil }
        let brand = String(bytes: data[0..<20], encoding: .utf8)?.trimmingCharacters(in: .controlCharacters.union(.whitespaces)) ?? ""
        let material = String(bytes: data[20..<40], encoding: .utf8)?.trimmingCharacters(in: .controlCharacters.union(.whitespaces)) ?? ""
        let color = String(bytes: data[40..<48], encoding: .utf8)?.trimmingCharacters(in: .controlCharacters.union(.whitespaces)) ?? ""
        let weightBits = data[48..<56].withUnsafeBytes { $0.load(as: UInt64.self).bigEndian }
        let weight = Double(bitPattern: weightBits)
        // Add more fields as needed
        return Filament(brand: brand, material: material, color: color, weight: weight, printTemperature: 0, bedTemperature: 0)
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

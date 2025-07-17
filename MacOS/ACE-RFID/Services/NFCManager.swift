import Foundation




class NFCManager {
    private var connectionString: String = ""
    var debugConnectionString: String { connectionString }

    func setConnectionString(_ conn: String) {
        print("[DEBUG] NFCManager setConnectionString: \(conn)")
        self.connectionString = conn
    }

    func isNFCAvailable() -> Bool {
        #if targetEnvironment(macCatalyst)
        print("[DEBUG] NFCManager isNFCAvailable, connectionString: \(connectionString)")
        // Optionally, check with connection string if needed
        return nfc_is_available(connectionString) == 1
        #else
        return false
        #endif
    }

    func getFirmwareVersion() -> String? {
        #if targetEnvironment(macCatalyst)
        print("[DEBUG] NFCManager getFirmwareVersion, connectionString: \(connectionString)")
        var buffer = [CChar](repeating: 0, count: 128)
        let result = nfc_get_firmware_version(connectionString, &buffer, 128)
        if result == 1 {
            return String(cString: buffer)
        }
        return nil
        #else
        return nil
        #endif
    }

    func readUID() -> String? {
        #if targetEnvironment(macCatalyst)
        print("[DEBUG] NFCManager readUID, connectionString: \(connectionString)")
        var buffer = [UInt8](repeating: 0, count: 64)
        let result = nfc_read_uid(connectionString, &buffer, 64)
        print("[DEBUG] nfc_read_uid result: \(result)")
        if result > 0 {
            let hexString = buffer.prefix(Int(result)).map { String(format: "%02X", $0) }.joined(separator: " ")
            print("[DEBUG] UID hex string: \(hexString)")
            return hexString
        }
        return nil
        #else
        return nil
        #endif
    }

    func readCardContent(length: Int = 256) -> Data? {
        #if targetEnvironment(macCatalyst)
        print("[DEBUG] NFCManager readCardContent, connectionString: \(connectionString)")
        var buffer = [CChar](repeating: 0, count: length)
        let result = nfc_read_card_content(connectionString, &buffer, length)
        print("[DEBUG] nfc_read_card_content result: \(result)")
        if result > 0 {
            let data = Data(buffer.prefix(Int(result)).map { UInt8(bitPattern: $0) })
            // Save hex dump in blocks of 4 bytes
            let hexLines = stride(from: 0, to: data.count, by: 4).map { i -> String in
                let block = data[i..<min(i+4, data.count)]
                return block.map { String(format: "%02X", $0) }.joined(separator: " ")
            }
            let hexDump = hexLines.joined(separator: "\n")
            let fileURL = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("rfid_card_dump.txt")
            do {
                try hexDump.write(to: fileURL, atomically: true, encoding: .utf8)
            } catch {
                print("Failed to write hex dump: \(error)")
            }
            print("[DEBUG] Card content hex: \(data.map { String(format: "%02X", $0) }.joined(separator: " "))")
            return data
        }
        return nil
        #else
        return nil
        #endif
    }

    func writeCardContent(data: Data) -> Bool {
        #if targetEnvironment(macCatalyst)
        print("[DEBUG] NFCManager writeCardContent, connectionString: \(connectionString)")
        print("[DEBUG] Data to write, length: \(data.count)")
        print("[DEBUG] Data hex: \(data.map { String(format: "%02X", $0) }.joined(separator: " "))")
        // Pad data to 256 bytes
        var paddedData = data
        if paddedData.count < 256 {
            paddedData.append(contentsOf: Array(repeating: 0, count: 256 - paddedData.count))
        }
        // Convert buffer to hex string
        let hexString = paddedData.map { String(format: "%02X", $0) }.joined(separator: " ")
        print("[DEBUG] Final hex string (256 bytes): \(hexString)")
        let result = nfc_write_card_content(connectionString, hexString)
        print("[DEBUG] nfc_write_card_content result: \(result)")
        return result == 1
        #else
        return false
        #endif
    }
}

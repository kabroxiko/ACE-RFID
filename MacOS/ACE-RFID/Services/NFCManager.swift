import Foundation




class NFCManager {
    private var connectionString: String = ""

    func setConnectionString(_ conn: String) {
        self.connectionString = conn
    }

    func isNFCAvailable() -> Bool {
        #if os(macOS)
        // Optionally, check with connection string if needed
        return nfc_is_available() == 1
        #else
        return false
        #endif
    }

    func getFirmwareVersion() -> String? {
        #if os(macOS)
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
        #if os(macOS)
        var buffer = [CChar](repeating: 0, count: 64)
        let result = nfc_read_uid(connectionString, &buffer, 64)
        if result == 1 {
            return String(cString: buffer)
        }
        return nil
        #else
        return nil
        #endif
    }

    func readCardContent(length: Int = 256) -> Data? {
        #if os(macOS)
        var buffer = [UInt8](repeating: 0, count: length)
        let result = nfc_read_card_content(connectionString, &buffer, Int32(length))
        if result > 0 {
            return Data(buffer[0..<Int(result)])
        }
        return nil
        #else
        return nil
        #endif
    }

    func writeCardContent(data: Data) -> Bool {
        #if os(macOS)
        var buffer = [UInt8](repeating: 0, count: 256)
        let count = min(data.count, 256)
        data.copyBytes(to: &buffer, count: count)
        let result = nfc_write_card_content(connectionString, buffer, Int32(count))
        return result == 1
        #else
        return false
        #endif
    }
}

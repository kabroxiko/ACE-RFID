import Foundation

class NFCManager {
    static func isNFCAvailable() -> Bool {
        #if os(macOS)
        return nfc_is_available() == 1
        #else
        // For iOS, use CoreNFC or return false
        return false
        #endif
    }
}

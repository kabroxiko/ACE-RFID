//
//  NFCService.swift
//  ACE-RFID
//
//  Created by Copilot on 07/03/2025.
//

import Foundation
import CoreNFC

protocol NFCServiceDelegate: AnyObject {
    func nfcDidReadFilament(_ filament: Filament)
    func nfcDidWriteFilament(_ filament: Filament)
    func nfcDidFailWithError(_ error: Error)
}

class NFCService: NSObject {

    weak var delegate: NFCServiceDelegate?

    private var nfcSession: NFCNDEFReaderSession?
    private var nfcWriteSession: NFCNDEFReaderSession?
    private var filamentToWrite: Filament?

    // MARK: - Public Methods

    /// Check if NFC is available on this device
    static var isNFCAvailable: Bool {
        #if targetEnvironment(simulator)
        // NFC is not available in simulator
        return false
        #else
        return NFCNDEFReaderSession.readingAvailable
        #endif
    }

    /// Start reading NFC tags for filament data
    func startReading() {
        guard NFCNDEFReaderSession.readingAvailable else {
            delegate?.nfcDidFailWithError(NFCError.notAvailable)
            return
        }

        nfcSession = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: true)
        nfcSession?.alertMessage = "Hold your iPhone near the RFID tag to read filament information."
        nfcSession?.begin()
    }

    /// Start writing filament data to NFC tag
    func writeFilament(_ filament: Filament) {
        guard NFCNDEFReaderSession.readingAvailable else {
            delegate?.nfcDidFailWithError(NFCError.notAvailable)
            return
        }

        filamentToWrite = filament
        nfcWriteSession = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
        nfcWriteSession?.alertMessage = "Hold your iPhone near the RFID tag to write filament information."
        nfcWriteSession?.begin()
    }

    /// Stop any active NFC session
    func stopSession() {
        nfcSession?.invalidate()
        nfcWriteSession?.invalidate()
        nfcSession = nil
        nfcWriteSession = nil
        filamentToWrite = nil
    }
}

// MARK: - NFCNDEFReaderSessionDelegate

extension NFCService: NFCNDEFReaderSessionDelegate {

    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        DispatchQueue.main.async {
            if let nfcError = error as? NFCReaderError {
                switch nfcError.code {
                case .readerSessionInvalidationErrorUserCanceled:
                    // User canceled, don't show error
                    break
                default:
                    self.delegate?.nfcDidFailWithError(nfcError)
                }
            } else {
                self.delegate?.nfcDidFailWithError(error)
            }
        }

        // Clean up
        if session == nfcSession {
            nfcSession = nil
        } else if session == nfcWriteSession {
            nfcWriteSession = nil
            filamentToWrite = nil
        }
    }

    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        guard let message = messages.first,
              let record = message.records.first,
              let payload = String(data: record.payload, encoding: .utf8) else {
            DispatchQueue.main.async {
                self.delegate?.nfcDidFailWithError(NFCError.invalidData)
            }
            return
        }

        // Remove NDEF text record language prefix if present
        let cleanPayload = payload.hasPrefix("\u{02}en") ? String(payload.dropFirst(3)) : payload

        guard let filament = Filament.fromJSONString(cleanPayload) else {
            DispatchQueue.main.async {
                self.delegate?.nfcDidFailWithError(NFCError.invalidData)
            }
            return
        }

        DispatchQueue.main.async {
            self.delegate?.nfcDidReadFilament(filament)
        }

        session.invalidate()
    }

    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        // This is called when we're in write mode
        guard let filament = filamentToWrite,
              let tag = tags.first else {
            session.invalidate(errorMessage: "Unable to write to tag.")
            return
        }

        session.connect(to: tag) { error in
            if let error = error {
                session.invalidate(errorMessage: "Connection failed: \(error.localizedDescription)")
                return
            }

            tag.queryNDEFStatus { status, capacity, error in
                if let error = error {
                    session.invalidate(errorMessage: "Query failed: \(error.localizedDescription)")
                    return
                }

                guard status == .readWrite else {
                    session.invalidate(errorMessage: "Tag is not writable.")
                    return
                }

                // Create NDEF message with filament data
                guard let jsonString = filament.toJSONString(),
                      let _ = jsonString.data(using: .utf8) else {
                    session.invalidate(errorMessage: "Failed to encode filament data.")
                    return
                }

                // Add language prefix for NDEF text record
                let languagePrefix = "\u{02}en"
                let payloadData = (languagePrefix + jsonString).data(using: .utf8)!

                let record = NFCNDEFPayload(format: .nfcWellKnown,
                                          type: "T".data(using: .utf8)!,
                                          identifier: Data(),
                                          payload: payloadData)

                let message = NFCNDEFMessage(records: [record])

                tag.writeNDEF(message) { error in
                    if let error = error {
                        session.invalidate(errorMessage: "Write failed: \(error.localizedDescription)")
                    } else {
                        session.alertMessage = "Filament data written successfully!"
                        DispatchQueue.main.async {
                            self.delegate?.nfcDidWriteFilament(filament)
                        }
                        session.invalidate()
                    }
                }
            }
        }
    }
}

// MARK: - NFCError

enum NFCError: LocalizedError {
    case notAvailable
    case invalidData
    case writeFailed

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "NFC is not available on this device."
        case .invalidData:
            return "Invalid filament data on the tag."
        case .writeFailed:
            return "Failed to write data to the tag."
        }
    }
}

// MARK: - Testing Support

#if targetEnvironment(simulator)
extension NFCService {
    /// Simulate reading an NFC tag with mock filament data (Simulator only)
    func simulateReadTag() {
        let mockFilament = Filament(
            id: UUID().uuidString,
            brand: "Simulation Brand",
            material: "PLA",
            color: "Blue",
            weight: 1000.0,
            diameter: 1.75,
            printTemperature: 200,
            bedTemperature: 60,
            fanSpeed: 100,
            printSpeed: 50,
            dateAdded: Date(),
            lastUsed: nil,
            remainingWeight: 1000.0,
            isFinished: false,
            notes: "Mock filament data from simulator"
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.delegate?.nfcDidReadFilament(mockFilament)
        }
    }

    /// Simulate writing to an NFC tag (Simulator only)
    func simulateWriteTag(_ filament: Filament) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.delegate?.nfcDidWriteFilament(filament)
        }
    }
}
#endif

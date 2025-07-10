// Serial port NFC manager for Mac Catalyst
import Foundation

#if targetEnvironment(macCatalyst)
import IOKit.serial
import Darwin // <-- Add this for POSIX write/read/close/open

protocol NFCSerialManagerDelegate: AnyObject {
    func serialManager(didRead data: Data)
    func serialManager(didWrite success: Bool)
    func serialManager(didFail error: Error)
}

class NFCSerialManager {
    weak var delegate: NFCSerialManagerDelegate?
    private var fileDescriptor: Int32 = -1
    private var serialPath: String? = nil

    func setSerialPath(_ path: String) {
        print("[DEBUG] Serial path set to: \(path)")
        serialPath = path
        // Persist the selected serial port path
        UserDefaults.standard.set(path, forKey: "ACE_RFID_SelectedSerialPort")
    }

    func loadSerialPath() {
        if let saved = UserDefaults.standard.string(forKey: "ACE_RFID_SelectedSerialPort") {
            serialPath = saved
            print("[DEBUG] Loaded saved serial port: \(saved)")
        }
    }

    func openSerialPort() {
        if serialPath == nil {
            loadSerialPath()
        }
        guard let path = serialPath else {
            print("[DEBUG] No serial port selected. Please configure the serial port.")
            delegate?.serialManager(didFail: NSError(domain: "Serial", code: 3, userInfo: [NSLocalizedDescriptionKey: "No serial port selected. Please configure the serial port."]))
            return
        }
        // Print current process euid/gid for permission debugging
        print("[DEBUG] Running as UID: \(getuid()), EUID: \(geteuid()), GID: \(getgid()), EGID: \(getegid())")
        // Print serial port path and check file existence/permissions
        let fileManager = FileManager.default
        let exists = fileManager.fileExists(atPath: path)
        print("[DEBUG] Serial port exists: \(exists), path: \(path)")
        if exists {
            do {
                let attrs = try fileManager.attributesOfItem(atPath: path)
                print("[DEBUG] Serial port attributes: \(attrs)")
            } catch {
                print("[DEBUG] Could not get serial port attributes: \(error)")
            }
        }
        print("[DEBUG] Attempting to open serial port at path: \(path)")
        fileDescriptor = open(path, O_RDWR | O_NOCTTY | O_NONBLOCK)
        if fileDescriptor < 0 {
            let errStr = String(cString: strerror(errno))
            print("[DEBUG] Failed to open serial port: \(path), errno=\(errno) (\(errStr))")
            delegate?.serialManager(didFail: NSError(domain: "Serial", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to open serial port: \(errStr)"]))
            return
        }
        print("[DEBUG] Serial port opened, fileDescriptor: \(fileDescriptor)")

        // --- Configure serial port for 115200 8N1 ---
        var options = termios()
        if tcgetattr(fileDescriptor, &options) == 0 {
            cfsetispeed(&options, speed_t(B115200))
            cfsetospeed(&options, speed_t(B115200))
            options.c_cflag |= tcflag_t(CLOCAL)
            options.c_cflag |= tcflag_t(CREAD)
            options.c_cflag &= ~tcflag_t(CSIZE)
            options.c_cflag |= tcflag_t(CS8)
            options.c_cflag &= ~tcflag_t(PARENB)
            options.c_cflag &= ~tcflag_t(CSTOPB)
            options.c_cflag &= ~tcflag_t(CRTSCTS)
            options.c_lflag = 0
            options.c_oflag = 0
            options.c_iflag = 0
            // Set VMIN/VTIME using correct indexes (platform constants)
            // Use hardcoded indexes for VMIN/VTIME for all platforms (POSIX standard: 16/17)
            let VMIN = 16
            let VTIME = 17
            // c_cc is a tuple, not an array, so we must access by index directly
            if VMIN < 20 && VTIME < 20 {
                withUnsafeMutablePointer(to: &options.c_cc) { ptr in
                    let ccPtr = UnsafeMutableRawPointer(ptr).assumingMemoryBound(to: UInt8.self)
                    ccPtr[VMIN] = 1
                    ccPtr[VTIME] = 0
                    print("[DEBUG] termios after config: c_cflag=0x\(String(options.c_cflag, radix: 16)), c_lflag=0x\(String(options.c_lflag, radix: 16)), c_oflag=0x\(String(options.c_oflag, radix: 16)), c_iflag=0x\(String(options.c_iflag, radix: 16)), VMIN=\(ccPtr[VMIN]), VTIME=\(ccPtr[VTIME])")
                }
            }
            if tcsetattr(fileDescriptor, TCSANOW, &options) != 0 {
                let errStr = String(cString: strerror(errno))
                print("[DEBUG] Failed to set serial port attributes: errno=\(errno) (\(errStr))")
            } else {
                print("[DEBUG] Serial port configured: 115200 8N1, raw mode")
            }
        } else {
            let errStr = String(cString: strerror(errno))
            print("[DEBUG] Failed to get serial port attributes: errno=\(errno) (\(errStr))")
        }

        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.readLoop()
        }
    }

    func write(data: Data) {
        print("[DEBUG] Attempting to write to serial port, fileDescriptor: \(fileDescriptor), data: \(data as NSData)")
        guard fileDescriptor >= 0 else {
            print("[DEBUG] Write failed: fileDescriptor invalid")
            delegate?.serialManager(didWrite: false)
            return
        }
        let result = data.withUnsafeBytes { ptr in
            Darwin.write(fileDescriptor, ptr.baseAddress, data.count)
        }
        print("[DEBUG] Write result: \(result), expected: \(data.count)")
        delegate?.serialManager(didWrite: result == data.count)
    }

    private func readLoop() {
        var buffer = [UInt8](repeating: 0, count: 256)
        while fileDescriptor >= 0 {
            let bytesRead = read(fileDescriptor, &buffer, buffer.count)
            print("[DEBUG] Serial read bytes: \(bytesRead)")
            if bytesRead > 0 {
                let data = Data(buffer[0..<bytesRead])
                print("[DEBUG] Serial data received: \(data as NSData)")
                DispatchQueue.main.async {
                    self.delegate?.serialManager(didRead: data)
                }
            } else if bytesRead < 0 {
                if errno != EAGAIN { // 35 is EAGAIN (Resource temporarily unavailable)
                    print("[DEBUG] Serial read error: \(errno)")
                }
            }
            usleep(10000)
        }
    }

    func closeSerialPort() {
        print("[DEBUG] Closing serial port, fileDescriptor: \(fileDescriptor)")
        if fileDescriptor >= 0 {
            close(fileDescriptor)
            fileDescriptor = -1
            print("[DEBUG] Serial port closed")
        }
    }
}
#endif

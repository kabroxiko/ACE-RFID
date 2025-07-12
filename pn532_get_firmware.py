import serial
import time
import serial.tools.list_ports

ports = serial.tools.list_ports.comports()
for port in ports:
    print(f"{port.device}: {port.description}")

PORT = "/dev/cu.usbserial-14340"  # Change to your serial port
BAUD = 115200  # Match Arduino's Serial.begin(115200)

# PN532 protocol constants
PN532_PREAMBLE = 0x00
PN532_STARTCODE1 = 0x00
PN532_STARTCODE2 = 0xFF
PN532_POSTAMBLE = 0x00
PN532_HOSTTOPN532 = 0xD4

def build_pn532_frame(command):
    frame = []
    len_byte = len(command) + 1  # +1 for TFI
    lcs = (~len_byte) & 0xFF
    frame += [PN532_PREAMBLE, PN532_STARTCODE1, PN532_STARTCODE2, len_byte, lcs, PN532_HOSTTOPN532]
    dcs = PN532_HOSTTOPN532
    for b in command:
        frame.append(b)
        dcs = (dcs + b) & 0xFF
    dcs = (~dcs) & 0xFF
    frame += [dcs, PN532_POSTAMBLE]
    return bytes(frame)

def parse_firmware_response(data):
    # Look for response frame header
    for i in range(len(data) - 7):
        if data[i:i+3] == b'\x00\x00\xff':
            len_byte = data[i+3]
            lcs = data[i+4]
            if (len_byte + lcs) & 0xFF != 0:
                continue
            tfi = data[i+5]
            if tfi != 0xD5:
                continue
            if len(data) < i + 6 + len_byte:
                continue
            frame_data = data[i+6:i+6+len_byte-1]
            if frame_data[0] == 0x03:  # GetFirmwareVersion response
                ic = frame_data[1]
                ver = frame_data[2]
                rev = frame_data[3]
                print(f"PN532 Firmware Version: IC={ic}, Ver={ver}, Rev={rev}")
                return True
    return False

with serial.Serial(PORT, BAUD, timeout=1) as ser:
    print(f"Opened {PORT} at {BAUD} baud")
    # Send Get Firmware Version command
    get_fw_cmd = [0x02]  # Command code for GetFirmwareVersion
    frame = build_pn532_frame(get_fw_cmd)
    print(f"Sending GetFirmwareVersion frame: {frame.hex(' ')}")
    ser.write(frame)
    time.sleep(0.1)
    # Read response
    response = ser.read(64)
    print(f"Received: {response.hex(' ')}")
    if not parse_firmware_response(response):
        print("No valid firmware response found.")

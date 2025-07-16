const { SerialPort } = require('serialport');

// PN532 protocol constants
const PN532_PREAMBLE = 0x00;
const PN532_STARTCODE1 = 0x00;
const PN532_STARTCODE2 = 0xFF;
const PN532_POSTAMBLE = 0x00;
const PN532_HOSTTOPN532 = 0xD4;
const PN532_ACK_FRAME = Buffer.from([0x00, 0x00, 0xFF, 0x00, 0xFF, 0x00]);
class Reader {
  constructor(port, baudRate = 115200) {
    this.port = new SerialPort({ path: port, baudRate, autoOpen: false });
    this.debug = true;
    this.buffer = Buffer.alloc(0);
    this.ackReceived = false;
    this.responseReceived = false;
  }
  async open() {
    if (this.debug) console.log(`[Reader] Opening port: ${this.port.path} @ ${this.port.baudRate}`);
    return new Promise((resolve, reject) => {
      this.port.open(async err => {
        if (err) {
          if (this.debug) console.error(`[Reader] Error opening port:`, err);
          reject(err);
        } else {
          if (this.debug) console.log(`[Reader] Port opened.`);
          // Wakeup sequence: send 0x55 and wait 100ms (per NFCToolsGUI)
          this.port.write(Buffer.from([0x55]), err2 => {
            if (err2) {
              if (this.debug) console.error(`[Reader] Error sending wakeup:`, err2);
              reject(err2);
            } else {
              setTimeout(resolve, 100);
            }
          });
        }
      });
    });
  }
  async close() {
    if (this.debug) console.log(`[Reader] Closing port: ${this.port.path}`);
    return new Promise((resolve, reject) => {
      this.port.close(err => {
        if (err) {
          if (this.debug) console.error(`[Reader] Error closing port:`, err);
          reject(err);
        } else {
          if (this.debug) console.log(`[Reader] Port closed.`);
          resolve();
        }
      });
    });
  }
  buildFrame(command) {
    // Build PN532 frame for a given command array
    let len_byte = command.length + 1; // +1 for TFI
    let lcs = (~len_byte) & 0xFF;
    let frame = [PN532_PREAMBLE, PN532_STARTCODE1, PN532_STARTCODE2, len_byte, lcs, PN532_HOSTTOPN532];
    let dcs = PN532_HOSTTOPN532;
    for (const b of command) {
      frame.push(b);
      dcs = (dcs + b) & 0xFF;
    }
    dcs = (~dcs) & 0xFF;
    frame.push(dcs, PN532_POSTAMBLE);
    return Buffer.from(frame);
  }

  async getFirmwareVersion(timeoutMs = 2000) {
    // PN532 GetFirmwareVersion command
    const get_fw_cmd = [0x02];
    const frame = this.buildFrame(get_fw_cmd);
    if (this.debug) {
      console.log(`[Reader] Sending frame:`, Array.from(frame).map(b => b.toString(16).padStart(2, '0')).join(' '));
    }
    this.buffer = Buffer.alloc(0);
    this.ackReceived = false;
    this.responseReceived = false;
    return new Promise((resolve, reject) => {
      let timer = setTimeout(() => {
        if (this.debug) console.error(`[Reader] Timeout waiting for response`);
        this.port.removeAllListeners('data');
        reject(new Error('Timeout waiting for response'));
      }, timeoutMs);
      this.port.on('data', data => {
        this.buffer = Buffer.concat([this.buffer, data]);
        if (this.debug) console.log(`[Reader] Buffer:`, Array.from(this.buffer).map(b => b.toString(16).padStart(2, '0')).join(' '));
        // Check for ACK frame
        if (!this.ackReceived && this.buffer.length >= PN532_ACK_FRAME.length) {
          for (let i = 0; i <= this.buffer.length - PN532_ACK_FRAME.length; i++) {
            if (this.buffer.slice(i, i+PN532_ACK_FRAME.length).equals(PN532_ACK_FRAME)) {
              this.ackReceived = true;
              if (this.debug) console.log(`[Reader] ACK received`);
              this.buffer = this.buffer.slice(i+PN532_ACK_FRAME.length);
              break;
            }
          }
        }
        // After ACK, look for response frame
        if (this.ackReceived && this.buffer.length >= 10) {
          for (let i = 0; i < this.buffer.length - 7; i++) {
            if (this.buffer[i] === 0x00 && this.buffer[i+1] === 0x00 && this.buffer[i+2] === 0xFF) {
              let len_byte = this.buffer[i+3];
              let lcs = this.buffer[i+4];
              if (((len_byte + lcs) & 0xFF) !== 0) continue;
              let tfi = this.buffer[i+5];
              if (tfi !== 0xD5) continue;
              if (this.buffer.length < i + 6 + len_byte) continue;
              let frame_data = this.buffer.slice(i+6, i+6+len_byte-1);
              if (this.debug) {
                console.log(`[Reader] Frame data:`, Array.from(frame_data).map(b => b.toString(16).padStart(2, '0')).join(' '));
              }
              if (frame_data[0] === 0x03) {
                let ic = frame_data[1];
                let ver = frame_data[2];
                let rev = frame_data[3];
                clearTimeout(timer);
                this.port.removeAllListeners('data');
                if (this.debug) console.log(`[Reader] Firmware response: IC=${ic}, Ver=${ver}, Rev=${rev}`);
                return resolve({ ic, ver, rev });
              }
            }
          }
        }
      });
      this.port.write(frame, err => {
        if (err) {
          clearTimeout(timer);
          this.port.removeAllListeners('data');
          if (this.debug) console.error(`[Reader] Error writing frame:`, err);
          return reject(err);
        }
        this.port.drain(() => {
          // Wait for ACK and response
        });
      });
    });
  }
}

module.exports = Reader;

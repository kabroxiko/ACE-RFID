// Placeholder for PN532 reader logic using serialport
const { SerialPort } = require('serialport');

class Reader {
  constructor(port, baudRate = 115200) {
    this.port = new SerialPort({ path: port, baudRate, autoOpen: false });
    this.debug = true;
  }
  async open() {
    if (this.debug) console.log(`[Reader] Opening port: ${this.port.path} @ ${this.port.baudRate}`);
    return new Promise((resolve, reject) => {
      this.port.open(err => {
        if (err) {
          if (this.debug) console.error(`[Reader] Error opening port:`, err);
          reject(err);
        } else {
          if (this.debug) console.log(`[Reader] Port opened.`);
          resolve();
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
  async getFirmwareVersion() {
    // PN532 GetFirmwareVersion command
    const PN532_PREAMBLE = 0x00;
    const PN532_STARTCODE1 = 0x00;
    const PN532_STARTCODE2 = 0xFF;
    const PN532_POSTAMBLE = 0x00;
    const PN532_HOSTTOPN532 = 0xD4;
    const get_fw_cmd = [0x02];
    let frame = [];
    let len_byte = get_fw_cmd.length + 1;
    let lcs = (~len_byte) & 0xFF;
    frame = [PN532_PREAMBLE, PN532_STARTCODE1, PN532_STARTCODE2, len_byte, lcs, PN532_HOSTTOPN532];
    let dcs = PN532_HOSTTOPN532;
    for (const b of get_fw_cmd) {
      frame.push(b);
      dcs = (dcs + b) & 0xFF;
    }
    dcs = (~dcs) & 0xFF;
    frame.push(dcs, PN532_POSTAMBLE);
    if (this.debug) {
      console.log(`[Reader] Sending frame:`, frame.map(b => b.toString(16).padStart(2, '0')).join(' '));
    }
    return new Promise((resolve, reject) => {
      this.port.write(Buffer.from(frame), err => {
        if (err) {
          if (this.debug) console.error(`[Reader] Error writing frame:`, err);
          return reject(err);
        }
        this.port.drain(() => {
          this.port.once('data', data => {
            if (this.debug) {
              console.log(`[Reader] Received data:`, Array.from(data).map(b => b.toString(16).padStart(2, '0')).join(' '));
            }
            // Parse response
            for (let i = 0; i < data.length - 7; i++) {
              if (data[i] === 0x00 && data[i+1] === 0x00 && data[i+2] === 0xFF) {
                let len_byte = data[i+3];
                let lcs = data[i+4];
                if (((len_byte + lcs) & 0xFF) !== 0) continue;
                let tfi = data[i+5];
                if (tfi !== 0xD5) continue;
                if (data.length < i + 6 + len_byte) continue;
                let frame_data = data.slice(i+6, i+6+len_byte-1);
                if (this.debug) {
                  console.log(`[Reader] Frame data:`, Array.from(frame_data).map(b => b.toString(16).padStart(2, '0')).join(' '));
                }
                if (frame_data[0] === 0x03) {
                  let ic = frame_data[1];
                  let ver = frame_data[2];
                  let rev = frame_data[3];
                  if (this.debug) console.log(`[Reader] Firmware response: IC=${ic}, Ver=${ver}, Rev=${rev}`);
                  return resolve({ ic, ver, rev });
                }
              }
            }
            if (this.debug) console.error(`[Reader] No valid firmware response found`);
            return reject(new Error('No valid firmware response found'));
          });
        });
      });
    });
  }
}

module.exports = Reader;

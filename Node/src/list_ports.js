const { SerialPort } = require('serialport');

async function listPorts() {
  const ports = await SerialPort.list();
  return ports.map(p => ({ path: p.path, manufacturer: p.manufacturer }));
}

module.exports = { listPorts };

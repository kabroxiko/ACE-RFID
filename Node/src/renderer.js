const { getAllMaterials, getTemps } = require('./utils');

window.addEventListener('DOMContentLoaded', async () => {
  const materialSelect = document.getElementById('material');
  const tempsDiv = document.getElementById('temps');
  const uidDiv = document.getElementById('uid');
  const msgDiv = document.getElementById('msg');

  const { ipcRenderer } = require('electron');
  const portSelect = document.createElement('select');
  portSelect.id = 'port';
  portSelect.style.marginBottom = '0.5em';
  materialSelect.parentNode.insertBefore(portSelect, materialSelect);

  async function populatePorts() {
    const ports = await ipcRenderer.invoke('list-ports');
    portSelect.innerHTML = '';
    ports.forEach(p => {
      const opt = document.createElement('option');
      opt.value = p.path;
      opt.textContent = p.path + (p.manufacturer ? ` (${p.manufacturer})` : '');
      portSelect.appendChild(opt);
    });
    if (ports.length) portSelect.value = ports[0].path;
  }
  await populatePorts();

  const materials = await getAllMaterials();
  materials.forEach(m => {
    const opt = document.createElement('option');
    opt.value = m;
    opt.textContent = m;
    materialSelect.appendChild(opt);
  });

  async function updateTemps() {
    const temps = await getTemps(materialSelect.value);
    tempsDiv.textContent = temps.join(', ');
  }

  materialSelect.addEventListener('change', updateTemps);
  if (materials.length) {
    materialSelect.value = materials[0];
    updateTemps();
  }

  document.getElementById('read').addEventListener('click', async () => {
    const port = portSelect.value;
    uidDiv.textContent = 'Reading firmware...';
    msgDiv.textContent = '';
    try {
      const fw = await ipcRenderer.invoke('read-firmware', port);
      if (fw.error) {
        uidDiv.textContent = '';
        msgDiv.textContent = 'Error: ' + fw.error;
      } else {
        uidDiv.textContent = `PN532 Firmware: IC=${fw.ic}, Ver=${fw.ver}, Rev=${fw.rev}`;
        msgDiv.textContent = '';
      }
    } catch (e) {
      uidDiv.textContent = '';
      msgDiv.textContent = 'Error: ' + e.message;
    }
  });
  document.getElementById('write').addEventListener('click', () => {
    msgDiv.textContent = 'Write Tag pressed (demo)';
    uidDiv.textContent = '';
  });
});

const { getAllMaterials, getTemps } = require('./utils');

window.addEventListener('DOMContentLoaded', async () => {
  const materialSelect = document.getElementById('material');
  const tempsDiv = document.getElementById('temps');
  const uidDiv = document.getElementById('uid');
  const msgDiv = document.getElementById('msg');

  const { ipcRenderer } = require('electron');
  const portInput = document.createElement('input');
  portInput.type = 'text';
  portInput.placeholder = 'Serial Port (e.g. COM3)';
  portInput.id = 'port';
  materialSelect.parentNode.insertBefore(portInput, materialSelect);

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
    const port = portInput.value || 'COM3';
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

const { app, BrowserWindow } = require('electron');
const path = require('path');
const { ipcMain } = require('electron');
const Reader = require('./reader');

function createWindow() {
  const win = new BrowserWindow({
    width: 800,
    height: 600,
    webPreferences: {
      nodeIntegration: true,
      contextIsolation: false,
    },
    icon: path.join(__dirname, '../assets/add.png'),
  });
  win.loadFile(path.join(__dirname, 'index.html'));
}

app.whenReady().then(createWindow);

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});

ipcMain.handle('read-firmware', async (event, port) => {
  const reader = new Reader(port);
  await reader.open();
  try {
    const fw = await reader.getFirmwareVersion();
    await reader.close();
    return fw;
  } catch (e) {
    await reader.close();
    return { error: e.message };
  }
});

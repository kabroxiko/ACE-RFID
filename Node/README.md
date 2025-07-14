# ACE RFID Node.js

This is the Node.js implementation equivalent to the Windows ACE RFID solution.

## Structure
- `src/filament.js`: Filament model
- `src/matdb.js`: Filament database (XML-based)
- `src/utils.js`: Utility functions
- `src/reader.js`: PN532 reader logic (serialport)
- `src/index.js`: Main entry point
- `assets/`: UI images

## Usage
1. Install dependencies: `npm install`
2. Run: `npm start`

## TODO
- Implement full PN532 reader logic in `reader.js`
- Add Electron-based UI for desktop app

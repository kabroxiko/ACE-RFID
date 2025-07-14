const fs = require('fs');
const xml2js = require('xml2js');
const Filament = require('./filament');

const xmlPath = 'filaments.xml';

class MatDB {
  static async getAllFilaments() {
    if (!fs.existsSync(xmlPath)) return [];
    const xml = fs.readFileSync(xmlPath, 'utf8');
    const result = await xml2js.parseStringPromise(xml);
    return (result.Filaments.Filament || []).map(f => new Filament(
      parseInt(f.Position[0]),
      f.FilamentName[0],
      f.FilamentId[0],
      f.FilamentVendor[0],
      f.FilamentParam[0]
    ));
  }
  static async getFilamentByName(name) {
    const filaments = await MatDB.getAllFilaments();
    return filaments.find(f => f.filamentName === name);
  }
  static async addFilament(filament) {
    // TODO: Implement add logic
  }
}

module.exports = MatDB;

const MatDB = require('./matdb');

async function getAllMaterials() {
  const filaments = await MatDB.getAllFilaments();
  return filaments.map(f => f.filamentName);
}

async function getTemps(materialName) {
  const item = await MatDB.getFilamentByName(materialName);
  if (!item || !item.filamentParam) return [200, 210, 50, 60];
  const temps = item.filamentParam.split('|').map(t => parseInt(t.trim())).filter(Number.isFinite);
  return temps.length ? temps : [200, 210, 50, 60];
}

module.exports = { getAllMaterials, getTemps };

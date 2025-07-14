const { getAllMaterials, getTemps } = require('./utils');
const Reader = require('./reader');

async function main() {
  console.log('ACE RFID Node.js App');
  const materials = await getAllMaterials();
  console.log('Materials:', materials);
  if (materials.length) {
    const temps = await getTemps(materials[0]);
    console.log(`Temps for ${materials[0]}:`, temps);
  }
  // Example usage of Reader
  // const reader = new Reader('COM3');
  // await reader.open();
  // ...
  // await reader.close();
}

main();

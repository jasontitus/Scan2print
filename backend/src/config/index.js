require('dotenv').config();

module.exports = {
  port: parseInt(process.env.PORT, 10) || 3000,
  bambuStudioCli: process.env.BAMBU_STUDIO_CLI || '/Applications/BambuStudio.app/Contents/MacOS/bambu-studio',
  printer: {
    ip: process.env.PRINTER_IP,
    accessCode: process.env.PRINTER_ACCESS_CODE,
    serial: process.env.PRINTER_SERIAL,
  },
};

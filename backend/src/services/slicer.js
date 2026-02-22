const { exec } = require('child_process');
const path = require('path');
const fs = require('fs');
const config = require('../config');
const { updateJob } = require('./jobManager');

const SLICE_TIMEOUT_MS = 120_000; // 2 minutes

function sliceModel(jobId, modelPath) {
  updateJob(jobId, { status: 'slicing' });

  const outputDir = path.join('/tmp', 'scan2print', 'output', jobId);
  fs.mkdirSync(outputDir, { recursive: true });

  const outputFile = path.join(outputDir, 'output.gcode.3mf');
  const profileDir = path.join(__dirname, '..', '..', 'slicing-profiles');

  const cmd = [
    `"${config.bambuStudioCli}"`,
    '--export-3mf',
    `--load-filament "${path.join(profileDir, 'filament.json')}"`,
    `--load-process "${path.join(profileDir, 'process.json')}"`,
    `--load-machine "${path.join(profileDir, 'machine.json')}"`,
    `--output "${outputFile}"`,
    `"${modelPath}"`,
  ].join(' ');

  console.log(`[slicer] Starting job ${jobId}: ${cmd}`);

  exec(cmd, { timeout: SLICE_TIMEOUT_MS }, (error, stdout, stderr) => {
    if (error) {
      console.error(`[slicer] Job ${jobId} failed:`, error.message);
      console.error(`[slicer] stderr: ${stderr}`);
      updateJob(jobId, {
        status: 'failed',
        error: error.killed ? 'Slicing timed out' : `Slicing failed: ${error.message}`,
      });
      return;
    }

    console.log(`[slicer] Job ${jobId} completed. stdout: ${stdout}`);

    if (!fs.existsSync(outputFile)) {
      updateJob(jobId, {
        status: 'failed',
        error: 'Slicer produced no output file',
      });
      return;
    }

    updateJob(jobId, {
      status: 'sliced',
      gcodeFile: outputFile,
    });
  });
}

module.exports = { sliceModel };

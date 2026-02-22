const ftp = require('basic-ftp');
const mqtt = require('mqtt');
const path = require('path');
const config = require('../config');

async function uploadToPrinter(gcodeFile) {
  const client = new ftp.Client();
  client.ftp.verbose = true;

  try {
    await client.access({
      host: config.printer.ip,
      port: 990,
      user: 'bblp',
      password: config.printer.accessCode,
      secure: 'implicit',
      secureOptions: { rejectUnauthorized: false },
    });

    const remoteName = path.basename(gcodeFile);
    await client.uploadFrom(gcodeFile, remoteName);
    console.log(`[printer] Uploaded ${remoteName} via FTPS`);
    return remoteName;
  } finally {
    client.close();
  }
}

function sendPrintCommand(remoteFileName) {
  return new Promise((resolve, reject) => {
    const url = `mqtts://${config.printer.ip}:8883`;
    const client = mqtt.connect(url, {
      username: 'bblp',
      password: config.printer.accessCode,
      rejectUnauthorized: false,
    });

    const timeout = setTimeout(() => {
      client.end(true);
      reject(new Error('MQTT connection timed out'));
    }, 10_000);

    client.on('connect', () => {
      const topic = `device/${config.printer.serial}/request`;
      const payload = JSON.stringify({
        print: {
          command: 'project_file',
          param: `ftp/${remoteFileName}`,
          project_id: '0',
          profile_id: '0',
          task_id: '0',
          subtask_id: '0',
        },
      });

      client.publish(topic, payload, { qos: 1 }, (err) => {
        clearTimeout(timeout);
        client.end();
        if (err) {
          reject(err);
        } else {
          console.log(`[printer] Print command sent for ${remoteFileName}`);
          resolve();
        }
      });
    });

    client.on('error', (err) => {
      clearTimeout(timeout);
      client.end(true);
      reject(err);
    });
  });
}

module.exports = { uploadToPrinter, sendPrintCommand };

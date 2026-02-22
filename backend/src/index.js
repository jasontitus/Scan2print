const express = require('express');
const config = require('./config');
const errorHandler = require('./middleware/errorHandler');

const uploadRoute = require('./routes/upload');
const statusRoute = require('./routes/status');
const printRoute = require('./routes/print');

const app = express();

app.use(express.json());

app.get('/health', (_req, res) => {
  res.json({ status: 'ok' });
});

app.use('/upload', uploadRoute);
app.use('/status', statusRoute);
app.use('/print', printRoute);

app.use(errorHandler);

app.listen(config.port, '0.0.0.0', () => {
  console.log(`Scan2Print backend listening on 0.0.0.0:${config.port}`);
});

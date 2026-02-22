const { describe, it, before, after, mock } = require('node:test');
const assert = require('node:assert/strict');
const path = require('path');
const fs = require('fs');
const request = require('supertest');

// Stub sliceModel so the upload route does not launch the real slicer binary.
const slicer = require('../src/services/slicer');
mock.method(slicer, 'sliceModel', () => {});

// Build an Express app identical to src/index.js but without calling listen().
const express = require('express');
const errorHandler = require('../src/middleware/errorHandler');
const uploadRoute = require('../src/routes/upload');
const statusRoute = require('../src/routes/status');
const printRoute = require('../src/routes/print');

function createApp() {
  const app = express();
  app.use(express.json());

  app.get('/health', (_req, res) => {
    res.json({ status: 'ok' });
  });

  app.use('/upload', uploadRoute);
  app.use('/status', statusRoute);
  app.use('/print', printRoute);

  app.use(errorHandler);
  return app;
}

// Tiny .obj file used for upload tests.
const OBJ_FILE = path.join('/tmp', 'scan2print-test-model.obj');

before(() => {
  fs.writeFileSync(OBJ_FILE, 'v 0 0 0\nv 1 0 0\nv 0 1 0\nf 1 2 3\n');
});

after(() => {
  try { fs.unlinkSync(OBJ_FILE); } catch { /* ignore */ }
});

// ---------------------------------------------------------------------------
// Health
// ---------------------------------------------------------------------------
describe('GET /health', () => {
  const app = createApp();

  it('returns 200 with {status: "ok"}', async () => {
    const res = await request(app).get('/health');
    assert.equal(res.status, 200);
    assert.deepStrictEqual(res.body, { status: 'ok' });
  });
});

// ---------------------------------------------------------------------------
// Upload
// ---------------------------------------------------------------------------
describe('POST /upload', () => {
  const app = createApp();

  it('returns 400 when no file is provided', async () => {
    const res = await request(app)
      .post('/upload')
      .send({});

    // Multer silently skips non-multipart requests; the route handler then
    // sees that req.file is undefined and returns 400.
    assert.equal(res.status, 400);
    assert.ok(res.body.error);
  });

  it('rejects a .txt file', async () => {
    const txtFile = path.join('/tmp', 'scan2print-test.txt');
    fs.writeFileSync(txtFile, 'hello');
    try {
      const res = await request(app)
        .post('/upload')
        .attach('model', txtFile);

      // Multer's fileFilter passes an Error to next(), which the error
      // handler middleware catches.  The error has no .status so we get 500.
      assert.ok([400, 500].includes(res.status), `Expected 400 or 500, got ${res.status}`);
      assert.match(res.body.error, /\.obj|\.stl|accepted/i);
    } finally {
      try { fs.unlinkSync(txtFile); } catch { /* ignore */ }
    }
  });

  it('accepts an .obj file and returns 202 with jobId', async () => {
    const res = await request(app)
      .post('/upload')
      .attach('model', OBJ_FILE);

    assert.equal(res.status, 202);
    assert.ok(res.body.jobId, 'response should contain jobId');
    assert.equal(typeof res.body.jobId, 'string');
    assert.equal(res.body.status, 'uploaded');

    // sliceModel should have been called
    assert.ok(slicer.sliceModel.mock.calls.length > 0, 'sliceModel should be called');
  });
});

// ---------------------------------------------------------------------------
// Status
// ---------------------------------------------------------------------------
describe('GET /status/:jobId', () => {
  const app = createApp();

  it('returns job status for an existing job', async () => {
    // First, upload a model to create a job.
    const upload = await request(app)
      .post('/upload')
      .attach('model', OBJ_FILE);

    const { jobId } = upload.body;
    assert.ok(jobId);

    const res = await request(app).get(`/status/${jobId}`);
    assert.equal(res.status, 200);
    assert.equal(res.body.jobId, jobId);
    assert.ok(res.body.status);
    assert.ok(res.body.createdAt);
    assert.ok(res.body.updatedAt);
  });

  it('returns 404 for a nonexistent job', async () => {
    const res = await request(app).get('/status/nonexistent-job-id');
    assert.equal(res.status, 404);
    assert.ok(res.body.error);
  });
});

// ---------------------------------------------------------------------------
// Print
// ---------------------------------------------------------------------------
describe('POST /print/:jobId', () => {
  const app = createApp();

  it('returns 404 for a nonexistent job', async () => {
    const res = await request(app).post('/print/nonexistent-job-id');
    assert.equal(res.status, 404);
    assert.ok(res.body.error);
  });

  it('returns 409 when job is not in sliced state', async () => {
    // Upload creates a job with status "uploaded" (the mock prevents real
    // slicing, so the status never advances to "sliced").
    const upload = await request(app)
      .post('/upload')
      .attach('model', OBJ_FILE);

    const { jobId } = upload.body;
    assert.ok(jobId);

    const res = await request(app).post(`/print/${jobId}`);
    assert.equal(res.status, 409);
    assert.match(res.body.error, /not ready|status/i);
  });
});

const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { createJob, getJob, updateJob } = require('../src/services/jobManager');

describe('jobManager', () => {
  describe('createJob', () => {
    it('creates a job with correct initial state', () => {
      const modelPath = '/tmp/test-model.obj';
      const job = createJob(modelPath);

      assert.ok(job.jobId, 'jobId should be defined');
      assert.equal(typeof job.jobId, 'string');
      assert.equal(job.status, 'uploaded');
      assert.equal(job.modelPath, modelPath);
      assert.equal(job.gcodeFile, null);
      assert.equal(job.error, null);
      assert.equal(typeof job.createdAt, 'number');
      assert.equal(typeof job.updatedAt, 'number');
      assert.ok(job.createdAt <= Date.now(), 'createdAt should be in the past or present');
    });
  });

  describe('getJob', () => {
    it('returns null for nonexistent job', () => {
      const result = getJob('nonexistent-id-12345');
      assert.equal(result, null);
    });

    it('returns correct job', () => {
      const modelPath = '/tmp/another-model.stl';
      const created = createJob(modelPath);
      const retrieved = getJob(created.jobId);

      assert.deepStrictEqual(retrieved, created);
      assert.equal(retrieved.jobId, created.jobId);
      assert.equal(retrieved.modelPath, modelPath);
      assert.equal(retrieved.status, 'uploaded');
    });
  });

  describe('updateJob', () => {
    it('updates fields and updatedAt timestamp', () => {
      const job = createJob('/tmp/update-test.obj');
      const originalUpdatedAt = job.updatedAt;

      // Small delay to ensure updatedAt changes
      const beforeUpdate = Date.now();
      const updated = updateJob(job.jobId, { status: 'slicing', gcodeFile: '/tmp/output.gcode' });

      assert.equal(updated.status, 'slicing');
      assert.equal(updated.gcodeFile, '/tmp/output.gcode');
      assert.equal(updated.modelPath, job.modelPath, 'modelPath should remain unchanged');
      assert.equal(updated.jobId, job.jobId, 'jobId should remain unchanged');
      assert.ok(updated.updatedAt >= beforeUpdate, 'updatedAt should be refreshed');
    });

    it('returns null for nonexistent job', () => {
      const result = updateJob('does-not-exist-99999', { status: 'slicing' });
      assert.equal(result, null);
    });
  });
});

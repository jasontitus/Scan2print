const crypto = require('crypto');

// In-memory job store — sufficient for single-user local system
const jobs = new Map();

function createJob(modelPath) {
  const jobId = crypto.randomUUID();
  const job = {
    jobId,
    status: 'uploaded',    // uploaded → slicing → sliced → printing → completed | failed
    modelPath,
    gcodeFile: null,
    error: null,
    createdAt: Date.now(),
    updatedAt: Date.now(),
  };
  jobs.set(jobId, job);
  return job;
}

function getJob(jobId) {
  return jobs.get(jobId) || null;
}

function updateJob(jobId, updates) {
  const job = jobs.get(jobId);
  if (!job) return null;
  Object.assign(job, updates, { updatedAt: Date.now() });
  return job;
}

module.exports = { createJob, getJob, updateJob };

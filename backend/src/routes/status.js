const express = require('express');
const { getJob } = require('../services/jobManager');

const router = express.Router();

router.get('/:jobId', (req, res) => {
  const job = getJob(req.params.jobId);
  if (!job) {
    return res.status(404).json({ error: 'Job not found' });
  }

  res.json({
    jobId: job.jobId,
    status: job.status,
    error: job.error,
    createdAt: job.createdAt,
    updatedAt: job.updatedAt,
  });
});

module.exports = router;

const express = require('express');
const { getJob, updateJob } = require('../services/jobManager');
const { uploadToPrinter, sendPrintCommand } = require('../services/printer');

const router = express.Router();

router.post('/:jobId', async (req, res, next) => {
  try {
    const job = getJob(req.params.jobId);
    if (!job) {
      return res.status(404).json({ error: 'Job not found' });
    }

    if (job.status !== 'sliced') {
      return res.status(409).json({
        error: `Job is not ready for printing (current status: ${job.status})`,
      });
    }

    updateJob(job.jobId, { status: 'printing' });

    const remoteName = await uploadToPrinter(job.gcodeFile);
    await sendPrintCommand(remoteName);

    updateJob(job.jobId, { status: 'completed' });

    res.json({
      jobId: job.jobId,
      status: 'completed',
      message: 'Print job sent to printer',
    });
  } catch (err) {
    const job = getJob(req.params.jobId);
    if (job) {
      updateJob(job.jobId, {
        status: 'failed',
        error: `Print failed: ${err.message}`,
      });
    }
    next(err);
  }
});

module.exports = router;

const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { createJob } = require('../services/jobManager');
const { sliceModel } = require('../services/slicer');

const router = express.Router();

const storage = multer.diskStorage({
  destination(_req, _file, cb) {
    const dir = path.join('/tmp', 'scan2print', 'uploads');
    fs.mkdirSync(dir, { recursive: true });
    cb(null, dir);
  },
  filename(_req, file, cb) {
    const unique = `${Date.now()}-${Math.round(Math.random() * 1e6)}`;
    cb(null, `${unique}${path.extname(file.originalname)}`);
  },
});

const upload = multer({
  storage,
  fileFilter(_req, file, cb) {
    const ext = path.extname(file.originalname).toLowerCase();
    if (['.obj', '.stl'].includes(ext)) {
      cb(null, true);
    } else {
      cb(new Error('Only .obj and .stl files are accepted'));
    }
  },
  limits: { fileSize: 100 * 1024 * 1024 }, // 100 MB
});

router.post('/', upload.single('model'), (req, res) => {
  if (!req.file) {
    return res.status(400).json({ error: 'No model file provided' });
  }

  const job = createJob(req.file.path);

  // Fire off async slicing — don't await
  sliceModel(job.jobId, req.file.path);

  res.status(202).json({
    jobId: job.jobId,
    status: job.status,
  });
});

module.exports = router;

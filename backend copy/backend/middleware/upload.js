const multer = require('multer');
const path = require('path');
const fs = require('fs');
const crypto = require('crypto');

const UPLOADS_ROOT = path.join(__dirname, '..', 'uploads');

function makeUploader(subfolder, { allowedMimePrefixes = ['image/'], maxSizeMb = 10 } = {}) {
  const dest = path.join(UPLOADS_ROOT, subfolder);
  fs.mkdirSync(dest, { recursive: true });

  const storage = multer.diskStorage({
    destination: (_req, _file, cb) => cb(null, dest),
    filename: (_req, file, cb) =>
      cb(null, `${Date.now()}-${crypto.randomUUID()}${path.extname(file.originalname)}`),
  });

  return multer({
    storage,
    limits: { fileSize: maxSizeMb * 1024 * 1024 },
    fileFilter: (_req, file, cb) =>
      cb(null, allowedMimePrefixes.some((p) => file.mimetype.startsWith(p))),
  });
}

// Relative URL path a served upload is reachable at, given the on-disk path
// multer wrote it to (see server.js's `app.use('/uploads', ...)`).
function relativeUploadUrl(subfolder, filename) {
  return `/uploads/${subfolder}/${filename}`;
}

module.exports = { makeUploader, relativeUploadUrl, UPLOADS_ROOT };

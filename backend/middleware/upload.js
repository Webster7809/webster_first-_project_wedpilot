const multer = require('multer');
const path = require('path');
const fs = require('fs');
const crypto = require('crypto');

const UPLOADS_ROOT = path.join(__dirname, '..', 'uploads');

// SVG is an XML document that can carry an inline <script> — every uploader
// here matches on the broad 'image/' prefix, which would otherwise accept it
// as freely as a JPEG. A stored SVG is later served back byte-for-byte from
// /uploads with no sanitization, so if it's ever opened directly (not
// rendered inside Flutter's own Image widget, which doesn't execute script)
// the embedded script runs in the backend's own origin. No feature here
// needs vector uploads, so it's excluded unconditionally rather than
// per-caller. Checked on both the claimed mimetype AND the original
// filename's extension — express.static later derives the served
// Content-Type from the stored file's extension (which this code preserves
// from the upload), not from whatever Content-Type the client claimed on the
// way in, so mimetype alone is bypassable by pairing a spoofed
// Content-Type with a real .svg filename.
const BLOCKED_MIME_TYPES = ['image/svg+xml'];
const BLOCKED_EXTENSIONS = ['.svg'];

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
    fileFilter: (_req, file, cb) => {
      if (BLOCKED_MIME_TYPES.includes(file.mimetype)) return cb(null, false);
      if (BLOCKED_EXTENSIONS.includes(path.extname(file.originalname).toLowerCase())) {
        return cb(null, false);
      }
      cb(null, allowedMimePrefixes.some((p) => file.mimetype.startsWith(p)));
    },
  });
}

// Relative URL path a served upload is reachable at, given the on-disk path
// multer wrote it to (see server.js's `app.use('/uploads', ...)`).
function relativeUploadUrl(subfolder, filename) {
  return `/uploads/${subfolder}/${filename}`;
}

module.exports = { makeUploader, relativeUploadUrl, UPLOADS_ROOT };

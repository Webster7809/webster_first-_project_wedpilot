const nodemailer = require('nodemailer');

let transporter;
let warnedMissingConfig = false;

// Lazily built so a missing SMTP config doesn't crash the server at require
// time — routes call sendPasswordResetEmail() and it no-ops (with a console
// warning + the link logged) until SMTP_* is filled in in .env.
function getTransporter() {
  if (transporter) return transporter;
  if (!process.env.SMTP_HOST || !process.env.SMTP_USER || !process.env.SMTP_PASS) {
    return null;
  }
  const port = Number(process.env.SMTP_PORT) || 587;
  transporter = nodemailer.createTransport({
    host: process.env.SMTP_HOST,
    port,
    secure: port === 465,
    auth: {
      user: process.env.SMTP_USER,
      pass: process.env.SMTP_PASS,
    },
  });
  return transporter;
}

async function sendPasswordResetEmail(to, resetLink) {
  const t = getTransporter();
  if (!t) {
    if (!warnedMissingConfig) {
      console.warn(
        '[mailer] SMTP_HOST/SMTP_USER/SMTP_PASS not set in .env — password reset emails will not be sent. ' +
        'Falling back to logging the reset link to the console for local testing.'
      );
      warnedMissingConfig = true;
    }
    console.warn(`[mailer] Reset link for ${to}: ${resetLink}`);
    return;
  }

  await t.sendMail({
    from: process.env.SMTP_FROM || 'Wedpilot <no-reply@wedpilot.app>',
    to,
    subject: 'Reset your Wedpilot password',
    html: `
      <p>Someone requested a password reset for your Wedpilot account.</p>
      <p><a href="${resetLink}">Click here to choose a new password</a>. This link expires in 1 hour.</p>
      <p>If you didn't request this, you can safely ignore this email.</p>
    `,
  });
}

module.exports = { sendPasswordResetEmail };

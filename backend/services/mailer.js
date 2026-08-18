const nodemailer = require('nodemailer');

let transporter;
let warnedMissingConfig = false;

// Lazily built so a missing SMTP config doesn't crash the server at require
// time — the send helpers below no-op (with a console warning + the link
// logged) until SMTP_* is filled in in .env.
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

const FROM = () => process.env.SMTP_FROM || 'Wedpilot <no-reply@wedpilot.app>';

// Logs the link instead of mailing it when SMTP is unconfigured, so the whole
// flow is still testable locally. Returns true when a real send should follow.
function warnIfUnconfigured(label, to, link) {
  if (!warnedMissingConfig) {
    console.warn(
      '[mailer] SMTP_HOST/SMTP_USER/SMTP_PASS not set in .env — no mail will be sent. ' +
      'Falling back to logging links to the console for local testing.'
    );
    warnedMissingConfig = true;
  }
  console.warn(`[mailer] ${label} for ${to}: ${link}`);
}

async function sendPasswordResetEmail(to, resetLink) {
  const t = getTransporter();
  if (!t) return warnIfUnconfigured('Reset link', to, resetLink);

  await t.sendMail({
    from: FROM(),
    to,
    subject: 'Reset your Wedpilot password',
    html: `
      <p>Someone requested a password reset for your Wedpilot account.</p>
      <p><a href="${resetLink}">Click here to choose a new password</a>. This link expires in 1 hour.</p>
      <p>If you didn't request this, you can safely ignore this email.</p>
    `,
  });
}

async function sendVerificationEmail(to, verifyLink) {
  const t = getTransporter();
  if (!t) return warnIfUnconfigured('Verification link', to, verifyLink);

  await t.sendMail({
    from: FROM(),
    to,
    subject: 'Confirm your Wedpilot email address',
    html: `
      <p>Welcome to Wedpilot — one quick step and your account is active.</p>
      <p><a href="${verifyLink}">Confirm this email address</a>. This link expires in 24 hours.</p>
      <p>If you didn't create a Wedpilot account, you can safely ignore this email.</p>
    `,
  });
}

// Generic event mail (booking accepted, new message, budget alert, etc.) —
// see services/notify.js, which gates every call to this on the recipient's
// email_notifications preference before it ever gets here.
async function sendNotificationEmail(to, { subject, heading, bodyHtml }) {
  const t = getTransporter();
  if (!t) return warnIfUnconfigured(subject, to, bodyHtml);

  await t.sendMail({
    from: FROM(),
    to,
    subject,
    html: `
      <p><strong>${heading}</strong></p>
      <p>${bodyHtml}</p>
    `,
  });
}

module.exports = { sendPasswordResetEmail, sendVerificationEmail, sendNotificationEmail };

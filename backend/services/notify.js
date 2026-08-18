const User = require('../db/models/user');
const Notification = require('../db/models/notification');
const { sendNotificationEmail } = require('./mailer');

/**
 * Creates the in-app Notification row every event-triggering route already
 * built inline, and — when `emailContent` is given and the recipient hasn't
 * opted out — also sends the matching email. The email send is best-effort:
 * an SMTP hiccup must not stop the in-app notification from existing, same
 * principle as the verification-email send in routes/auth.js.
 *
 * @param {string} userId
 * @param {{type: string, title: string, body: string, entity_id?: string, entity_type?: string}} notification
 * @param {{subject: string, heading: string, bodyHtml: string}} [emailContent]
 */
async function notifyUser(userId, notification, emailContent) {
  const notif = await Notification.create({ user_id: userId, ...notification });

  if (emailContent) {
    try {
      const user = await User.findByPk(userId, { attributes: ['email', 'email_notifications'] });
      if (user?.email_notifications) {
        await sendNotificationEmail(user.email, emailContent);
      }
    } catch (err) {
      console.error(`Notification email failed for user ${userId}:`, err.message);
    }
  }

  return notif;
}

module.exports = { notifyUser };

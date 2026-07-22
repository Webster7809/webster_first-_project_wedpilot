// One-off dev cleanup script — the deletion counterpart to
// seedCuratedVendors.js. Removes every vendor account that script created
// (identified by its distinctive `@wedpilot-curated.internal` email domain,
// which no real vendor signup could ever have) along with every row across
// the schema that references its vendor_id. There are no DB-level
// foreign-key constraints in this schema (see the model files — vendor_id is
// always a plain UUID column, never a `references`), so this has to be done
// explicitly, table by table, or the leftover rows become orphaned data that
// admin queries and recalculateVendorStats could later choke on. Mirrors
// removeTestVendors.js exactly, just matched by a different email pattern.
//
// Usage: node scripts/removeCuratedVendors.js
require('dotenv').config();
const { Op } = require('sequelize');
const sequelize = require('../db/sequelize');
const User = require('../db/models/user');
const Vendor = require('../db/models/vendor');
const VendorService = require('../db/models/vendorService');
const VendorFeedback = require('../db/models/vendorFeedback');
const VendorMedia = require('../db/models/vendorMedia');
const VendorStats = require('../db/models/vendorStats');
const VendorMatch = require('../db/models/vendorMatch');
const SavedVendor = require('../db/models/savedVendor');
const Inquiry = require('../db/models/inquiry');
const Conversation = require('../db/models/conversation');
const Message = require('../db/models/message');
const Task = require('../db/models/task');
const Expense = require('../db/models/expense');

const EMAIL_DOMAIN = 'wedpilot-curated.internal';

async function main() {
  await sequelize.authenticate();

  const curatedUsers = await User.findAll({ where: { email: { [Op.like]: `%@${EMAIL_DOMAIN}` } } });
  if (curatedUsers.length === 0) {
    console.log('No seeded curated vendor accounts found (nothing to remove).');
    process.exit(0);
  }

  const userIds = curatedUsers.map((u) => u.user_id);
  const vendors = await Vendor.findAll({ where: { user_id: { [Op.in]: userIds } } });
  const vendorIds = vendors.map((v) => v.vendor_id);

  console.log(`Found ${curatedUsers.length} curated vendor account(s), ${vendorIds.length} vendor record(s).`);

  if (vendorIds.length > 0) {
    const convos = await Conversation.findAll({ where: { vendor_id: { [Op.in]: vendorIds } } });
    const convoIds = convos.map((c) => c.convo_id);
    const messagesDeleted = convoIds.length
      ? await Message.destroy({ where: { convo_id: { [Op.in]: convoIds } } })
      : 0;
    const convosDeleted = await Conversation.destroy({ where: { vendor_id: { [Op.in]: vendorIds } } });

    const feedbackDeleted = await VendorFeedback.destroy({ where: { vendor_id: { [Op.in]: vendorIds } } });
    const inquiriesDeleted = await Inquiry.destroy({ where: { vendor_id: { [Op.in]: vendorIds } } });
    const mediaDeleted = await VendorMedia.destroy({ where: { vendor_id: { [Op.in]: vendorIds } } });
    const statsDeleted = await VendorStats.destroy({ where: { vendor_id: { [Op.in]: vendorIds } } });
    const matchesDeleted = await VendorMatch.destroy({ where: { vendor_id: { [Op.in]: vendorIds } } });
    const savedDeleted = await SavedVendor.destroy({ where: { vendor_id: { [Op.in]: vendorIds } } });
    const servicesDeleted = await VendorService.destroy({ where: { vendor_id: { [Op.in]: vendorIds } } });

    // These belong to the couple, not the vendor — unlink rather than delete.
    const [tasksUnlinked] = await Task.update(
      { linked_vendor_id: null },
      { where: { linked_vendor_id: { [Op.in]: vendorIds } } },
    );
    const [expensesUnlinked] = await Expense.update(
      { vendor_id: null },
      { where: { vendor_id: { [Op.in]: vendorIds } } },
    );

    const vendorsDeleted = await Vendor.destroy({ where: { vendor_id: { [Op.in]: vendorIds } } });

    console.log(`  Messages deleted: ${messagesDeleted}`);
    console.log(`  Conversations deleted: ${convosDeleted}`);
    console.log(`  VendorFeedback deleted: ${feedbackDeleted}`);
    console.log(`  Inquiries deleted: ${inquiriesDeleted}`);
    console.log(`  VendorMedia deleted: ${mediaDeleted}`);
    console.log(`  VendorStats deleted: ${statsDeleted}`);
    console.log(`  VendorMatch deleted: ${matchesDeleted}`);
    console.log(`  SavedVendor deleted: ${savedDeleted}`);
    console.log(`  VendorService deleted: ${servicesDeleted}`);
    console.log(`  Task.linked_vendor_id unlinked: ${tasksUnlinked}`);
    console.log(`  Expense.vendor_id unlinked: ${expensesUnlinked}`);
    console.log(`  Vendors deleted: ${vendorsDeleted}`);
  }

  const usersDeleted = await User.destroy({ where: { user_id: { [Op.in]: userIds } } });
  console.log(`  Users deleted: ${usersDeleted}`);

  console.log('Done.');
  process.exit(0);
}

main().catch((err) => {
  console.error('Failed to remove curated vendors:', err.message);
  process.exit(1);
});

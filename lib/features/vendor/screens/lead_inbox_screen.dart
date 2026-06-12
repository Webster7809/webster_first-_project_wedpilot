import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/messaging.dart';
import '../../../widgets/wed_avatar.dart';

class LeadInboxScreen extends StatefulWidget {
  const LeadInboxScreen({super.key});

  @override
  State<LeadInboxScreen> createState() => _LeadInboxScreenState();
}

class _LeadInboxScreenState extends State<LeadInboxScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  final _mockLeads = [
    Inquiry(
      id: 'l-001',
      coupleId: 'c-001',
      vendorId: 'v-001',
      coupleName: 'Emma & Noah',
      status: InquiryStatus.newInquiry,
      budgetRangeMin: 2500,
      budgetRangeMax: 4000,
      weddingDate: DateTime(2027, 8, 15),
      message: 'Hi! We love your portfolio and would love full day coverage.',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    Inquiry(
      id: 'l-002',
      coupleId: 'c-002',
      vendorId: 'v-001',
      coupleName: 'Sophia & Lucas',
      status: InquiryStatus.responded,
      budgetRangeMin: 3000,
      budgetRangeMax: 5000,
      weddingDate: DateTime(2027, 6, 21),
      message: 'Interested in your full day package, please send pricing!',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Inquiry(
      id: 'l-003',
      coupleId: 'c-003',
      vendorId: 'v-001',
      coupleName: 'Olivia & James',
      status: InquiryStatus.booked,
      budgetRangeMin: 4000,
      budgetRangeMax: 6000,
      weddingDate: DateTime(2026, 11, 5),
      message: 'Ready to book — can we sign the contract?',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Lead Inbox'),
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          tabs: const [
            Tab(text: 'New'),
            Tab(text: 'Contacted'),
            Tab(text: 'Quoted'),
            Tab(text: 'Booked'),
            Tab(text: 'Declined'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _LeadList(leads: _mockLeads.where((l) => l.status == InquiryStatus.newInquiry).toList()),
          _LeadList(leads: _mockLeads.where((l) => l.status == InquiryStatus.responded).toList()),
          _LeadList(leads: []),
          _LeadList(leads: _mockLeads.where((l) => l.status == InquiryStatus.booked).toList()),
          _LeadList(leads: []),
        ],
      ),
    );
  }
}

class _LeadList extends StatelessWidget {
  final List<Inquiry> leads;
  const _LeadList({required this.leads});

  @override
  Widget build(BuildContext context) {
    if (leads.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📭', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text('No leads here', style: AppTextStyles.headlineMedium),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: leads.length,
      itemBuilder: (_, i) => _LeadCard(lead: leads[i]),
    );
  }
}

class _LeadCard extends StatelessWidget {
  final Inquiry lead;
  const _LeadCard({required this.lead});

  Color get _statusColor => switch (lead.status) {
        InquiryStatus.newInquiry => AppColors.info,
        InquiryStatus.booked => AppColors.success,
        InquiryStatus.declined => AppColors.error,
        _ => AppColors.warning,
      };

  String get _statusLabel => switch (lead.status) {
        InquiryStatus.newInquiry => 'New',
        InquiryStatus.viewed => 'Viewed',
        InquiryStatus.responded => 'Responded',
        InquiryStatus.quoted => 'Quoted',
        InquiryStatus.booked => 'Booked',
        InquiryStatus.declined => 'Declined',
      };

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                WedAvatar(name: lead.coupleName ?? 'Couple', radius: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lead.coupleName ?? 'Couple', style: AppTextStyles.titleMedium),
                      Text(_timeAgo(lead.createdAt), style: AppTextStyles.caption),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withAlpha(31),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(_statusLabel,
                      style: AppTextStyles.caption.copyWith(
                          color: _statusColor, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (lead.weddingDate != null)
              Row(
                children: [
                  const Icon(Icons.event, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text('Wedding: ${lead.weddingDate!.toLocal().toString().split(' ')[0]}',
                      style: AppTextStyles.bodySmall),
                  const SizedBox(width: 12),
                  const Icon(Icons.attach_money, size: 14, color: AppColors.textSecondary),
                  Text(
                    '\$${lead.budgetRangeMin?.toStringAsFixed(0)} – \$${lead.budgetRangeMax?.toStringAsFixed(0)}',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            const SizedBox(height: 8),
            Text(lead.message, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.reply, size: 16),
                    label: const Text('Reply'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.secondary,
                      side: const BorderSide(color: AppColors.secondary),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.request_quote_outlined, size: 16),
                    label: const Text('Quote'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/wed_card.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Real-time KPI cards
          Text('Platform Overview', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: const [
              _KpiCard(title: 'Daily Active Users', value: '1,284', icon: Icons.people_outline, color: AppColors.info),
              _KpiCard(title: 'New Registrations', value: '47', icon: Icons.person_add_outlined, color: AppColors.success),
              _KpiCard(title: 'Pending Verifications', value: '12', icon: Icons.pending_outlined, color: AppColors.warning),
              _KpiCard(title: 'Monthly Revenue', value: '\$8,420', icon: Icons.attach_money, color: AppColors.secondary),
            ],
          ),
          const SizedBox(height: 20),

          Text('Quick Actions', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 12),
          _AdminActionCard(
            emoji: '✅',
            title: 'Vendor Verification Queue',
            subtitle: '12 vendors awaiting review',
            badge: '12',
            onTap: () => context.push('/admin/vendors/verification'),
          ),
          const SizedBox(height: 10),
          _AdminActionCard(
            emoji: '🛡️',
            title: 'Content Moderation',
            subtitle: '8 items flagged for review',
            badge: '8',
            onTap: () => context.push('/admin/moderation'),
          ),
          const SizedBox(height: 10),
          _AdminActionCard(
            emoji: '👥',
            title: 'User Management',
            subtitle: 'Manage all platform users',
            onTap: () => context.push('/admin/users'),
          ),
          const SizedBox(height: 10),
          _AdminActionCard(
            emoji: '📊',
            title: 'Platform Analytics',
            subtitle: 'Revenue, growth & engagement',
            onTap: () => context.push('/admin/analytics'),
          ),
          const SizedBox(height: 20),

          // System health
          Text('System Health', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 12),
          WedCard(
            child: Column(
              children: const [
                _HealthRow(label: 'API Response Time (p95)', value: '280ms', status: 'good'),
                Divider(height: 16),
                _HealthRow(label: 'Database Query Time', value: '45ms', status: 'good'),
                Divider(height: 16),
                _HealthRow(label: 'Error Rate', value: '0.02%', status: 'good'),
                Divider(height: 16),
                _HealthRow(label: 'Uptime (30d)', value: '99.98%', status: 'good'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _KpiCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: AppTextStyles.headlineMedium.copyWith(color: color)),
              Text(title, style: AppTextStyles.caption, maxLines: 2),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminActionCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback onTap;

  const _AdminActionCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return WedCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.titleMedium),
                Text(subtitle, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.warning,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(badge!, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

class _HealthRow extends StatelessWidget {
  final String label;
  final String value;
  final String status;
  const _HealthRow({required this.label, required this.value, required this.status});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodySmall),
        Row(
          children: [
            Text(value, style: AppTextStyles.titleMedium),
            const SizedBox(width: 6),
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                color: status == 'good' ? AppColors.success : AppColors.error,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

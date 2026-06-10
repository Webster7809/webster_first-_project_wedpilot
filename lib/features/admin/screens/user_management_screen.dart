import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/wed_avatar.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  String _filter = 'All';
  final _searchCtrl = TextEditingController();

  final _users = [
    {'name': 'Alex & Jordan', 'email': 'alex@example.com', 'role': 'couple', 'status': 'active', 'joined': '2 days ago'},
    {'name': 'Blossom Photography', 'email': 'blossom@example.com', 'role': 'vendor', 'status': 'active', 'joined': '1 week ago'},
    {'name': 'Emma & Noah', 'email': 'emma@example.com', 'role': 'couple', 'status': 'active', 'joined': '3 days ago'},
    {'name': 'Garden Venue', 'email': 'garden@example.com', 'role': 'vendor', 'status': 'suspended', 'joined': '1 month ago'},
    {'name': 'Sarah Mitchell', 'email': 'sarah@example.com', 'role': 'admin', 'status': 'active', 'joined': '6 months ago'},
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _users.where((u) {
      final matchesFilter = _filter == 'All' || u['role'] == _filter.toLowerCase();
      final query = _searchCtrl.text.toLowerCase();
      final matchesSearch = query.isEmpty ||
          (u['name']?.toLowerCase().contains(query) ?? false) ||
          (u['email']?.toLowerCase().contains(query) ?? false);
      return matchesFilter && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('User Management')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search users...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Couple', 'Vendor', 'Admin'].map((f) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(f),
                        selected: _filter == f,
                        onSelected: (_) => setState(() => _filter = f),
                      selectedColor: AppColors.secondary.withValues(alpha: 38),
                      ),
                    )).toList(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final user = filtered[i];
                return ListTile(
                  leading: WedAvatar(name: user['name'] ?? 'U', radius: 20),
                  title: Text(user['name'] ?? '', style: AppTextStyles.titleMedium),
                  subtitle: Text(user['email'] ?? '', style: AppTextStyles.caption),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _RoleBadge(role: user['role'] ?? ''),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 20),
                        onSelected: (action) {},
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'view', child: Text('View Profile')),
                          PopupMenuItem(value: 'suspend', child: Text('Suspend Account')),
                          PopupMenuItem(value: 'delete', child: Text('Delete Account', style: TextStyle(color: AppColors.error))),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  Color get color => switch (role) {
        'admin' => AppColors.secondary,
        'vendor' => AppColors.info,
        _ => AppColors.tertiary,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 31),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        role[0].toUpperCase() + role.substring(1),
        style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

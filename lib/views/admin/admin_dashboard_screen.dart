import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/haiti_departments.dart';
import '../../core/constants/service_categories.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common.dart';
import '../../services/data_service.dart';
import '../../viewmodels/admin_view_model.dart';
import '../../viewmodels/session_view_model.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Strings s = context.l10n;
    final AdminViewModel admin = context.watch<AdminViewModel>();
    final SessionViewModel session = context.read<SessionViewModel>();
    final PlatformStats stats = admin.stats;
    final String localeCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.adminDashboard),
        actions: <Widget>[
          IconButton(
            onPressed: admin.refreshStats,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: s.retry,
          ),
          IconButton(
            onPressed: () => context.push(Routes.settings),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: admin.refreshStats,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: <Widget>[
            Text(
              '${s.greetingMorning}, ${session.user?.fullName ?? ''}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.md),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 1.5,
              children: <Widget>[
                _MetricCard(
                  icon: Icons.group_outlined,
                  label: s.totalUsers,
                  value: '${stats.totalUsers}',
                  color: AppColors.primary,
                ),
                _MetricCard(
                  icon: Icons.handyman_outlined,
                  label: s.activeWorkers,
                  value: '${stats.activeWorkers}',
                  color: AppColors.accent,
                ),
                _MetricCard(
                  icon: Icons.assignment_outlined,
                  label: s.totalJobs,
                  value: '${stats.totalJobs}',
                  color: AppColors.primaryDark,
                ),
                _MetricCard(
                  icon: Icons.payments_outlined,
                  label: s.totalRevenue,
                  value: Formatters.money(stats.totalRevenue, localeCode),
                  color: AppColors.warning,
                ),
              ],
            ),
            SectionHeader(title: s.moderation),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: <Widget>[
                  _QueueTile(
                    icon: Icons.badge_outlined,
                    label: s.pendingVerifications,
                    count: admin.verifications.length,
                    onTap: () => context.push(Routes.adminVerifications),
                  ),
                  const Divider(height: 1),
                  _QueueTile(
                    icon: Icons.flag_outlined,
                    label: s.reportedContent,
                    count: admin.reports.length,
                    onTap: () => context.push(Routes.adminReports),
                  ),
                  const Divider(height: 1),
                  _QueueTile(
                    icon: Icons.reviews_outlined,
                    label: s.reviews,
                    count: admin.reviews.length,
                    onTap: () => context.push(Routes.adminReviews),
                  ),
                  const Divider(height: 1),
                  _QueueTile(
                    icon: Icons.group_outlined,
                    label: s.users,
                    count: admin.users.length,
                    onTap: () => context.push(Routes.adminUsers),
                  ),
                ],
              ),
            ),
            SectionHeader(title: s.analytics),
            _Breakdown(
              title: s.categories,
              data: stats.jobsByCategory,
              labelFor: (String id) =>
                  ServiceCategory.fromId(id)?.label(s) ?? id,
            ),
            const SizedBox(height: AppSpacing.md),
            _Breakdown(
              title: s.filterDepartment,
              data: stats.jobsByDepartment,
              labelFor: (String id) =>
                  HaitiDepartment.fromId(id)?.label(s) ?? id,
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Icon(icon, color: color),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
}

class _QueueTile extends StatelessWidget {
  const _QueueTile({
    required this.icon,
    required this.label,
    required this.count,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon),
        title: Text(label),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (count > 0) Badge.count(count: count),
            const SizedBox(width: AppSpacing.sm),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
        onTap: onTap,
      );
}

/// Simple horizontal bars — enough signal for an ops dashboard without
/// pulling in a charting dependency.
class _Breakdown extends StatelessWidget {
  const _Breakdown({
    required this.title,
    required this.data,
    required this.labelFor,
  });

  final String title;
  final Map<String, int> data;
  final String Function(String id) labelFor;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox.shrink();
    }
    final List<MapEntry<String, int>> entries = data.entries.toList()
      ..sort(
        (MapEntry<String, int> a, MapEntry<String, int> b) =>
            b.value.compareTo(a.value),
      );
    final int max = entries.first.value == 0 ? 1 : entries.first.value;
    final ThemeData theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          for (final MapEntry<String, int> entry in entries.take(8))
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 110,
                    child: Text(
                      labelFor(entry.key),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: LinearProgressIndicator(
                        value: entry.value / max,
                        minHeight: 8,
                        backgroundColor: theme.colorScheme.outlineVariant
                            .withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text('${entry.value}', style: theme.textTheme.bodySmall),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

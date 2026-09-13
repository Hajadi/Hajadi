import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/rating_stars.dart';
import '../../models/job_request.dart';
import '../../models/worker_profile.dart';
import '../../viewmodels/jobs_view_model.dart';
import '../../viewmodels/session_view_model.dart';
import '../../viewmodels/worker_dashboard_view_model.dart';
import '../booking/jobs_screen.dart';

class WorkerDashboardScreen extends StatelessWidget {
  const WorkerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Strings s = context.l10n;
    final SessionViewModel session = context.watch<SessionViewModel>();
    final JobsViewModel jobs = context.watch<JobsViewModel>();
    final WorkerDashboardViewModel dashboard =
        context.watch<WorkerDashboardViewModel>();
    final WorkerProfile profile = dashboard.profile;
    final String localeCode = Localizations.localeOf(context).languageCode;
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: <Widget>[
            Row(
              children: <Widget>[
                AppAvatar(
                  name: profile.fullName,
                  photoUrl: profile.photoUrl,
                  radius: 26,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(profile.fullName, style: theme.textTheme.titleMedium),
                      Row(
                        children: <Widget>[
                          RatingStars(rating: profile.rating, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${Formatters.rating(profile.rating)} · '
                            '${profile.reviewCount}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => context.push(Routes.notifications),
                  icon: Badge.count(
                    isLabelVisible: session.unreadNotifications > 0,
                    count: session.unreadNotifications,
                    child: const Icon(Icons.notifications_none_rounded),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(s.availability, style: theme.textTheme.titleMedium),
                        Text(
                          profile.availableNow ? s.availableNow : s.unavailable,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: profile.availableNow,
                    onChanged: dashboard.toggleAvailability,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (!profile.isVerified) _VerificationCard(profile: profile),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: <Widget>[
                Expanded(
                  child: _StatCard(
                    icon: Icons.payments_outlined,
                    label: s.earningsMonth,
                    value: Formatters.money(jobs.monthEarnings, localeCode),
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _StatCard(
                    icon: Icons.account_balance_wallet_outlined,
                    label: s.earningsTotal,
                    value: Formatters.money(jobs.totalEarnings, localeCode),
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: <Widget>[
                Expanded(
                  child: _StatCard(
                    icon: Icons.task_alt_rounded,
                    label: s.completedJobs,
                    value: '${jobs.completed.length}',
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _StatCard(
                    icon: Icons.percent_rounded,
                    label: s.acceptanceRate,
                    value: '${(jobs.acceptanceRate * 100).round()}%',
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
            SectionHeader(
              title: s.pendingRequests,
              actionLabel: s.seeAll,
              onAction: () => context.go(Routes.jobs),
            ),
            if (jobs.pending.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(s.noRequests, style: theme.textTheme.bodySmall),
              )
            else
              for (final JobRequest job in jobs.pending.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: JobCard(job: job, asWorker: true),
                ),
            SectionHeader(title: s.myProfile),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.edit_outlined),
                    title: Text(s.editProfile),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push(Routes.dashboardProfile),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.verified_outlined),
                    title: Text(s.uploadId),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push(Routes.dashboardVerification),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.receipt_long_outlined),
                    title: Text(s.paymentHistory),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push(Routes.dashboardEarnings),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
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
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      );
}

class _VerificationCard extends StatelessWidget {
  const _VerificationCard({required this.profile});

  final WorkerProfile profile;

  @override
  Widget build(BuildContext context) {
    final Strings s = context.l10n;
    final (String title, Color color) = switch (profile.verification) {
      VerificationStatus.pending => (s.verificationPending, AppColors.warning),
      VerificationStatus.rejected => (s.verificationRejected, AppColors.danger),
      _ => (s.notVerified, AppColors.warning),
    };

    return AppCard(
      onTap: () => context.push(Routes.dashboardVerification),
      child: Row(
        children: <Widget>[
          Icon(Icons.badge_outlined, color: color),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text(
                  s.idVerified,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

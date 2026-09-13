import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/service_categories.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/common.dart';
import '../../models/job_request.dart';
import '../../viewmodels/jobs_view_model.dart';
import '../../viewmodels/session_view_model.dart';

/// Job list for both sides: a customer's requests, or a worker's inbox.
class JobsScreen extends StatelessWidget {
  const JobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Strings s = context.l10n;
    final JobsViewModel jobs = context.watch<JobsViewModel>();
    final bool asWorker = context.watch<SessionViewModel>().isWorker;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(asWorker ? s.pendingRequests : s.myRequests),
          bottom: TabBar(
            tabs: <Widget>[
              Tab(text: s.statusPending),
              Tab(text: s.statusInProgress),
              Tab(text: s.statusCompleted),
            ],
          ),
        ),
        body: jobs.loading
            ? const LoadingList()
            : TabBarView(
                children: <Widget>[
                  _JobList(jobs: jobs.pending, asWorker: asWorker),
                  _JobList(
                    jobs: jobs.active
                        .where(
                          (JobRequest job) => job.status != JobStatus.pending,
                        )
                        .toList(),
                    asWorker: asWorker,
                  ),
                  _JobList(
                    jobs: jobs.jobs
                        .where((JobRequest job) => !job.status.isOpen)
                        .toList(),
                    asWorker: asWorker,
                  ),
                ],
              ),
      ),
    );
  }
}

class _JobList extends StatelessWidget {
  const _JobList({required this.jobs, required this.asWorker});

  final List<JobRequest> jobs;
  final bool asWorker;

  @override
  Widget build(BuildContext context) {
    final Strings s = context.l10n;
    if (jobs.isEmpty) {
      return EmptyState(
        icon: Icons.assignment_outlined,
        title: s.noRequests,
        actionLabel: asWorker ? null : s.search,
        onAction: asWorker ? null : () => context.go(Routes.search),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: jobs.length,
      separatorBuilder: (BuildContext context, int index) =>
          const SizedBox(height: AppSpacing.md),
      itemBuilder: (BuildContext context, int index) =>
          JobCard(job: jobs[index], asWorker: asWorker),
    );
  }
}

class JobCard extends StatelessWidget {
  const JobCard({super.key, required this.job, required this.asWorker});

  final JobRequest job;
  final bool asWorker;

  static String statusLabel(Strings s, JobStatus status) => switch (status) {
        JobStatus.pending => s.statusPending,
        JobStatus.accepted => s.statusAccepted,
        JobStatus.rejected => s.statusRejected,
        JobStatus.inProgress => s.statusInProgress,
        JobStatus.completed => s.statusCompleted,
        JobStatus.cancelled => s.statusCancelled,
      };

  static Color statusColor(JobStatus status) => switch (status) {
        JobStatus.pending => AppColors.warning,
        JobStatus.accepted => AppColors.primary,
        JobStatus.inProgress => AppColors.primary,
        JobStatus.completed => AppColors.accent,
        JobStatus.rejected => AppColors.danger,
        JobStatus.cancelled => AppColors.inkMuted,
      };

  @override
  Widget build(BuildContext context) {
    final Strings s = context.l10n;
    final ThemeData theme = Theme.of(context);
    final String localeCode = Localizations.localeOf(context).languageCode;
    final ServiceCategory? category = ServiceCategory.fromId(job.categoryId);
    final String counterpartName = asWorker ? job.customerName : job.workerName;
    final String? counterpartPhoto =
        asWorker ? job.customerPhotoUrl : job.workerPhotoUrl;

    return AppCard(
      onTap: () => context.push(Routes.jobDetail(job.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              AppAvatar(
                name: counterpartName,
                photoUrl: counterpartPhoto,
                radius: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(counterpartName, style: theme.textTheme.titleMedium),
                    Text(
                      '${category?.label(s) ?? ''} · '
                      '${Formatters.date(job.createdAt, localeCode)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              StatusPill(
                label: statusLabel(s, job.status),
                color: statusColor(job.status),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            job.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: <Widget>[
              const Icon(Icons.place_outlined, size: 15),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  job.city ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ),
              Text(
                Formatters.money(job.billableAmount, localeCode),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

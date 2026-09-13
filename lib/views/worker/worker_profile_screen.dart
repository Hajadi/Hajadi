import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/haiti_departments.dart';
import '../../core/constants/service_categories.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/rating_stars.dart';
import '../../core/widgets/verified_badge.dart';
import '../../models/worker_profile.dart';
import '../../viewmodels/chat_view_model.dart';
import '../../viewmodels/session_view_model.dart';
import '../../viewmodels/worker_detail_view_model.dart';
import '../common/report_sheet.dart';
import 'widgets/review_tile.dart';

class WorkerProfileScreen extends StatelessWidget {
  const WorkerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Strings s = context.l10n;
    final WorkerDetailViewModel detail =
        context.watch<WorkerDetailViewModel>();
    final SessionViewModel session = context.watch<SessionViewModel>();
    final WorkerProfile? worker = detail.worker;

    if (detail.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (worker == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(
          icon: Icons.person_off_outlined,
          title: s.noResults,
          body: s.errorGeneric,
        ),
      );
    }

    final bool favorite = session.isFavorite(worker.id);

    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            pinned: true,
            actions: <Widget>[
              if (session.isSignedIn)
                IconButton(
                  tooltip: favorite ? s.removeFavorite : s.addFavorite,
                  onPressed: () => session.toggleFavorite(worker.id),
                  icon: Icon(
                    favorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: favorite ? AppColors.danger : null,
                  ),
                ),
              PopupMenuButton<String>(
                onSelected: (String value) {
                  if (value == 'report') {
                    showReportSheet(
                      context,
                      targetUserId: worker.id,
                      targetName: worker.fullName,
                    );
                  }
                },
                itemBuilder: (BuildContext context) =>
                    <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'report',
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.flag_outlined, size: 18),
                        const SizedBox(width: AppSpacing.sm),
                        Text(s.reportUser),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          SliverToBoxAdapter(child: _Header(worker: worker)),
          SliverToBoxAdapter(child: _Stats(worker: worker)),
          if (worker.bio.isNotEmpty) ...<Widget>[
            SliverToBoxAdapter(child: SectionHeader(title: s.about)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  worker.bio,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ],
          SliverToBoxAdapter(child: SectionHeader(title: s.servicesOffered)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: <Widget>[
                  for (final ServiceCategory trade in worker.categoryIds
                      .map(ServiceCategory.fromId)
                      .whereType<ServiceCategory>())
                    Chip(
                      avatar: Icon(trade.icon, size: 16),
                      label: Text(trade.label(s)),
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: SectionHeader(title: s.serviceAreas)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: <Widget>[
                  for (final HaitiDepartment department
                      in <String>{
                    worker.departmentId,
                    ...worker.serviceDepartmentIds,
                  }
                          .map(HaitiDepartment.fromId)
                          .whereType<HaitiDepartment>())
                    Chip(
                      avatar: const Icon(Icons.map_outlined, size: 16),
                      label: Text(department.label(s)),
                    ),
                  for (final String city in worker.serviceCities)
                    Chip(
                      avatar: const Icon(Icons.location_city_outlined, size: 16),
                      label: Text(city),
                    ),
                ],
              ),
            ),
          ),
          if (worker.certificates.isNotEmpty) ...<Widget>[
            SliverToBoxAdapter(child: SectionHeader(title: s.certificates)),
            SliverList.builder(
              itemCount: worker.certificates.length,
              itemBuilder: (BuildContext context, int index) {
                final Certificate certificate = worker.certificates[index];
                return ListTile(
                  leading: const Icon(Icons.workspace_premium_outlined),
                  title: Text(certificate.title),
                  subtitle: Text(certificate.issuer),
                );
              },
            ),
          ],
          if (worker.portfolio.isNotEmpty) ...<Widget>[
            SliverToBoxAdapter(child: SectionHeader(title: s.portfolio)),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 132,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  itemCount: worker.portfolio.length,
                  separatorBuilder: (BuildContext context, int index) =>
                      const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (BuildContext context, int index) =>
                      _PortfolioTile(item: worker.portfolio[index]),
                ),
              ),
            ),
          ],
          SliverToBoxAdapter(
            child: SectionHeader(
              title: s.reviewsCount(count: worker.reviewCount),
              actionLabel: s.seeAll,
              onAction: () => context.push(Routes.workerReviews(worker.id)),
            ),
          ),
          if (detail.reviews.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  s.noReviews,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            )
          else
            SliverList.builder(
              itemCount:
                  detail.reviews.length > 3 ? 3 : detail.reviews.length,
              itemBuilder: (BuildContext context, int index) => Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: ReviewTile(review: detail.reviews[index]),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ],
      ),
      bottomNavigationBar: _ActionBar(worker: worker),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.worker});

  final WorkerProfile worker;

  @override
  Widget build(BuildContext context) {
    final Strings s = context.l10n;
    final ThemeData theme = Theme.of(context);
    final String localeCode = Localizations.localeOf(context).languageCode;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppAvatar(
            name: worker.fullName,
            photoUrl: worker.photoUrl,
            radius: 38,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(worker.fullName, style: theme.textTheme.displaySmall),
                const SizedBox(height: 2),
                Text(worker.headline, style: theme.textTheme.bodySmall),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    if (worker.isVerified) const VerifiedBadge(),
                    StatusPill(
                      label: worker.availableNow ? s.availableNow : s.unavailable,
                      color: worker.availableNow
                          ? AppColors.accent
                          : AppColors.inkMuted,
                      icon: worker.availableNow
                          ? Icons.bolt_rounded
                          : Icons.schedule_rounded,
                    ),
                    Text(
                      '${Formatters.money(worker.hourlyRate, localeCode)}'
                      '${s.perHour}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.worker});

  final WorkerProfile worker;

  @override
  Widget build(BuildContext context) {
    final Strings s = context.l10n;
    final String localeCode = Localizations.localeOf(context).languageCode;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: AppCard(
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                children: <Widget>[
                  RatingStars(rating: worker.rating, size: 15),
                  const SizedBox(height: 4),
                  Text(
                    '${Formatters.rating(worker.rating)} · '
                    '${worker.reviewCount}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 34,
              child: VerticalDivider(width: 1),
            ),
            Expanded(
              child: Column(
                children: <Widget>[
                  Text(
                    '${worker.jobsCompleted}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s.completedJobs,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 34,
              child: VerticalDivider(width: 1),
            ),
            Expanded(
              child: Column(
                children: <Widget>[
                  Text(
                    '${worker.yearsExperience}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s.experienceYears(years: worker.yearsExperience),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 34,
              child: VerticalDivider(width: 1),
            ),
            Expanded(
              child: Column(
                children: <Widget>[
                  const Icon(Icons.place_outlined, size: 18),
                  const SizedBox(height: 4),
                  Text(
                    worker.distanceKm != null
                        ? Formatters.distance(worker.distanceKm)
                        : worker.city,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (worker.createdAt != null)
                    Text(
                      s.memberSince(
                        date: Formatters.monthYear(worker.createdAt, localeCode),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PortfolioTile extends StatelessWidget {
  const _PortfolioTile({required this.item});

  final PortfolioItem item;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: SizedBox(
          width: 168,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              CachedNetworkImage(
                imageUrl: item.imageUrl,
                fit: BoxFit.cover,
                placeholder: (BuildContext context, String url) => ColoredBox(
                  color: Theme.of(context)
                      .colorScheme
                      .outlineVariant
                      .withValues(alpha: 0.4),
                ),
                errorWidget:
                    (BuildContext context, String url, Object error) =>
                        ColoredBox(
                  color: Theme.of(context)
                      .colorScheme
                      .outlineVariant
                      .withValues(alpha: 0.4),
                  child: const Icon(Icons.image_outlined),
                ),
              ),
              if (item.caption.isNotEmpty)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    color: Colors.black54,
                    child: Text(
                      item.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.worker});

  final WorkerProfile worker;

  Future<void> _call(BuildContext context) async {
    final String? phone = worker.phone;
    if (phone == null || phone.isEmpty) {
      showAppSnackBar(context, context.l10n.errorGeneric, error: true);
      return;
    }
    await launchUrl(Uri(scheme: 'tel', path: phone));
  }

  Future<void> _message(BuildContext context) async {
    final SessionViewModel session = context.read<SessionViewModel>();
    if (session.user == null) {
      context.push(Routes.login);
      return;
    }
    final ConversationsViewModel conversations =
        context.read<ConversationsViewModel>();
    final String? id = await conversations.openWith(
      me: session.user!,
      otherId: worker.id,
      otherName: worker.fullName,
      otherPhotoUrl: worker.photoUrl,
    );
    if (id != null && context.mounted) {
      context.push(Routes.chatThread(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final Strings s = context.l10n;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _call(context),
                icon: const Icon(Icons.call_rounded, size: 20),
                label: Text(s.callNow),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _message(context),
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                label: Text(s.message),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: () => context.push(Routes.book(worker.id)),
                child: Text(s.requestJob),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

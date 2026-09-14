import 'package:flutter/material.dart';

import '../../models/worker_profile.dart';
import '../constants/service_categories.dart';
import '../localization/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'app_avatar.dart';
import 'common.dart';
import 'rating_stars.dart';
import 'verified_badge.dart';

/// The row used by search, favourites and every "see all" list.
class WorkerCard extends StatelessWidget {
  const WorkerCard({
    super.key,
    required this.worker,
    required this.onTap,
    this.isFavorite = false,
    this.onToggleFavorite,
  });

  final WorkerProfile worker;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback? onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Strings s = context.l10n;
    final String localeCode = Localizations.localeOf(context).languageCode;
    final List<String> trades = TradeLabels.forWorker(
      categoryIds: worker.categoryIds,
      customCategories: worker.customCategories,
      s: s,
    );

    return AppCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Stack(
            children: <Widget>[
              AppAvatar(
                name: worker.fullName,
                photoUrl: worker.photoUrl,
                radius: 30,
              ),
              if (worker.availableNow)
                Positioned(
                  right: 0,
                  bottom: 2,
                  child: Container(
                    height: 14,
                    width: 14,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.surface,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        worker.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    if (worker.isVerified) ...<Widget>[
                      const SizedBox(width: 6),
                      const VerifiedBadge(compact: true),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  trades.isEmpty
                      ? worker.headline
                      : trades.join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        RatingStars(rating: worker.rating, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${Formatters.rating(worker.rating)} '
                          '(${worker.reviewCount})',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    Text(
                      '· ${worker.city}',
                      style: theme.textTheme.bodySmall,
                    ),
                    if (worker.distanceKm != null)
                      Text(
                        '· ${Formatters.distance(worker.distanceKm)}',
                        style: theme.textTheme.bodySmall,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              if (onToggleFavorite != null)
                IconButton(
                  onPressed: onToggleFavorite,
                  visualDensity: VisualDensity.compact,
                  tooltip: isFavorite ? s.removeFavorite : s.addFavorite,
                  icon: Icon(
                    isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: isFavorite ? AppColors.danger : null,
                    size: 22,
                  ),
                ),
              Text(
                Formatters.money(worker.hourlyRate, localeCode),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              Text(s.perHour, style: theme.textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

/// Narrow card for the horizontal shelves on the home screen.
class WorkerShelfCard extends StatelessWidget {
  const WorkerShelfCard({
    super.key,
    required this.worker,
    required this.onTap,
  });

  final WorkerProfile worker;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Strings s = context.l10n;
    final String localeCode = Localizations.localeOf(context).languageCode;
    final List<String> trades = TradeLabels.forWorker(
      categoryIds: worker.categoryIds,
      customCategories: worker.customCategories,
      s: s,
    );
    final String? trade = trades.isEmpty ? null : trades.first;

    return SizedBox(
      width: 176,
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                AppAvatar(
                  name: worker.fullName,
                  photoUrl: worker.photoUrl,
                  radius: 22,
                ),
                const Spacer(),
                if (worker.isVerified) const VerifiedBadge(compact: true),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              worker.fullName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium,
            ),
            Text(
              trade ?? worker.city,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: <Widget>[
                const Icon(Icons.star_rounded, size: 15, color: AppColors.star),
                const SizedBox(width: 2),
                Text(
                  Formatters.rating(worker.rating),
                  style: theme.textTheme.bodySmall,
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    Formatters.money(worker.hourlyRate, localeCode),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
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
}

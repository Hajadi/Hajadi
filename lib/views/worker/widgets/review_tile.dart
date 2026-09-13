import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/rating_stars.dart';
import '../../../models/review.dart';

class ReviewTile extends StatelessWidget {
  const ReviewTile({super.key, required this.review, this.trailing});

  final Review review;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String localeCode = Localizations.localeOf(context).languageCode;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              AppAvatar(
                name: review.customerName,
                photoUrl: review.customerPhotoUrl,
                radius: 18,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      review.customerName,
                      style: theme.textTheme.titleMedium?.copyWith(fontSize: 15),
                    ),
                    Text(
                      Formatters.date(review.createdAt, localeCode),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              RatingStars(rating: review.rating, size: 15),
              if (trailing != null) trailing!,
            ],
          ),
          if (review.comment.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Text(review.comment, style: theme.textTheme.bodyMedium),
          ],
          if (review.status == ReviewStatus.pending) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.l10n.moderationPending,
              style: theme.textTheme.bodySmall,
            ),
          ],
          if (review.workerReply != null &&
              review.workerReply!.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                review.workerReply!,
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

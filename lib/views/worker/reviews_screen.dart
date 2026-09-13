import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../viewmodels/worker_detail_view_model.dart';
import 'widgets/review_tile.dart';

class ReviewsScreen extends StatelessWidget {
  const ReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Strings s = context.l10n;
    final WorkerDetailViewModel detail = context.watch<WorkerDetailViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          detail.worker == null
              ? s.reviews
              : '${s.reviews} · ${detail.worker!.fullName}',
        ),
      ),
      body: detail.reviews.isEmpty
          ? EmptyState(icon: Icons.rate_review_outlined, title: s.noReviews)
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: detail.reviews.length,
              separatorBuilder: (BuildContext context, int index) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (BuildContext context, int index) =>
                  ReviewTile(review: detail.reviews[index]),
            ),
    );
  }
}

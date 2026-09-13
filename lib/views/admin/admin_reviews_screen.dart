import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../models/review.dart';
import '../../viewmodels/admin_view_model.dart';
import '../worker/widgets/review_tile.dart';

class AdminReviewsScreen extends StatelessWidget {
  const AdminReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Strings s = context.l10n;
    final AdminViewModel admin = context.watch<AdminViewModel>();

    return Scaffold(
      appBar: AppBar(title: Text('${s.reviews} · ${s.moderation}')),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: admin.reviews.length,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(height: AppSpacing.md),
        itemBuilder: (BuildContext context, int index) {
          final Review review = admin.reviews[index];
          return ReviewTile(
            review: review,
            trailing: PopupMenuButton<String>(
              onSelected: (String action) => switch (action) {
                'hide' => admin.hideReview(review.id),
                'publish' => admin.publishReview(review.id),
                _ => admin.deleteReview(review.id),
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                if (review.status != ReviewStatus.hidden)
                  PopupMenuItem<String>(value: 'hide', child: Text(s.hideReview)),
                if (review.status != ReviewStatus.published)
                  PopupMenuItem<String>(value: 'publish', child: Text(s.approve)),
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Text(s.deleteReview),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

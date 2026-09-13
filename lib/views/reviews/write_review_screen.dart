import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/rating_stars.dart';
import '../../models/job_request.dart';
import '../../viewmodels/jobs_view_model.dart';
import '../../viewmodels/review_view_model.dart';
import '../../viewmodels/session_view_model.dart';

class WriteReviewScreen extends StatefulWidget {
  const WriteReviewScreen({super.key, required this.jobId});

  final String jobId;

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  final TextEditingController _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Strings s = context.l10n;
    final ReviewViewModel review = context.watch<ReviewViewModel>();
    final JobsViewModel jobs = context.watch<JobsViewModel>();
    final SessionViewModel session = context.watch<SessionViewModel>();

    final Iterable<JobRequest> matches =
        jobs.jobs.where((JobRequest job) => job.id == widget.jobId);
    if (matches.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(icon: Icons.rate_review_outlined, title: s.noRequests),
      );
    }
    final JobRequest job = matches.first;

    return Scaffold(
      appBar: AppBar(title: Text(s.writeReview)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: <Widget>[
          Center(
            child: Column(
              children: <Widget>[
                AppAvatar(
                  name: job.workerName,
                  photoUrl: job.workerPhotoUrl,
                  radius: 36,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  job.workerName,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(s.yourRating,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          RatingInput(rating: review.rating, onChanged: review.setRating),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _comment,
            maxLines: 5,
            onChanged: review.setComment,
            decoration: InputDecoration(
              hintText: s.reviewHint,
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: BusyButton(
            label: s.submitReview,
            busy: review.busy,
            onPressed: review.canSubmit && session.user != null
                ? () async {
                    final bool ok = await review.submit(
                      job: job,
                      customer: session.user!,
                    );
                    if (!context.mounted) {
                      return;
                    }
                    showAppSnackBar(
                      context,
                      ok ? s.reviewSubmitted : s.errorGeneric,
                      error: !ok,
                    );
                    if (ok) {
                      context.pop();
                    }
                  }
                : null,
          ),
        ),
      ),
    );
  }
}

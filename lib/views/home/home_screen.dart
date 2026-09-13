import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/service_categories.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/category_tile.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/worker_card.dart';
import '../../models/worker_profile.dart';
import '../../viewmodels/home_view_model.dart';
import '../../viewmodels/session_view_model.dart';
import '../common/emergency_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Strings s = context.l10n;
    final SessionViewModel session = context.watch<SessionViewModel>();
    final HomeViewModel home = context.watch<HomeViewModel>();
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: home.load,
          child: CustomScrollView(
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    0,
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              _greeting(s),
                              style: theme.textTheme.bodySmall,
                            ),
                            Text(
                              session.user?.fullName.split(' ').first ??
                                  s.appName,
                              style: theme.textTheme.headlineSmall,
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
                      IconButton(
                        onPressed: () => context.push(Routes.favorites),
                        icon: const Icon(Icons.favorite_border_rounded),
                      ),
                      GestureDetector(
                        onTap: () => context.go(Routes.profile),
                        child: AppAvatar(
                          name: session.user?.fullName ?? '',
                          photoUrl: session.user?.photoUrl,
                          radius: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: _SearchBar(
                    hint: s.searchHint,
                    onTap: () => context.go(Routes.search),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: s.categories,
                  actionLabel: s.seeAll,
                  onAction: () => context.push(Routes.categories),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 108,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    itemCount: home.categories.length,
                    separatorBuilder: (BuildContext context, int index) =>
                        const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (BuildContext context, int index) {
                      final ServiceCategory category = home.categories[index];
                      return SizedBox(
                        width: 104,
                        child: CategoryTile(
                          category: category,
                          onTap: () => context.go(
                            '${Routes.search}?category=${category.id}',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              _Shelf(
                title: s.topRated,
                workers: home.topRated,
                busy: home.busy,
              ),
              if (home.nearby.isNotEmpty)
                _Shelf(title: s.nearYou, workers: home.nearby, busy: false),
              _Shelf(
                title: s.verifiedWorkers,
                workers: home.verified,
                busy: home.busy,
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: EmergencyCallCard(),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
            ],
          ),
        ),
      ),
    );
  }

  String _greeting(Strings s) {
    final int hour = DateTime.now().hour;
    if (hour < 12) {
      return s.greetingMorning;
    }
    if (hour < 18) {
      return s.greetingAfternoon;
    }
    return s.greetingEvening;
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.hint, required this.onTap});

  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 15,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Row(
            children: <Widget>[
              Icon(Icons.search_rounded, color: theme.colorScheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(hint, style: theme.textTheme.bodyMedium),
              ),
              Icon(Icons.tune_rounded, color: theme.colorScheme.onSurface),
            ],
          ),
        ),
      ),
    );
  }
}

class _Shelf extends StatelessWidget {
  const _Shelf({
    required this.title,
    required this.workers,
    required this.busy,
  });

  final String title;
  final List<WorkerProfile> workers;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    if (!busy && workers.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SectionHeader(
            title: title,
            actionLabel: context.l10n.seeAll,
            onAction: () => context.go(Routes.search),
          ),
          SizedBox(
            height: 150,
            child: busy && workers.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    itemCount: workers.length,
                    separatorBuilder: (BuildContext context, int index) =>
                        const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (BuildContext context, int index) =>
                        WorkerShelfCard(
                      worker: workers[index],
                      onTap: () => context.push(
                        Routes.workerDetail(workers[index].id),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

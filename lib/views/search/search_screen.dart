import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/worker_card.dart';
import '../../models/search_filters.dart';
import '../../models/worker_profile.dart';
import '../../viewmodels/search_view_model.dart';
import '../../viewmodels/session_view_model.dart';
import 'filters_sheet.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _query =
      TextEditingController(text: context.read<SearchViewModel>().filters.query);

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Strings s = context.l10n;
    final SearchViewModel search = context.watch<SearchViewModel>();
    final SessionViewModel session = context.watch<SessionViewModel>();
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.md,
        title: TextField(
          controller: _query,
          onChanged: search.updateQuery,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: s.searchHint,
            prefixIcon: const Icon(Icons.search_rounded),
            isDense: true,
            suffixIcon: _query.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      _query.clear();
                      search.updateQuery('');
                    },
                  ),
          ),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: s.filters,
            onPressed: () async {
              final SearchFilters? updated =
                  await showFiltersSheet(context, search.filters);
              if (updated != null) {
                search.applyFilters(updated);
              }
            },
            icon: Badge.count(
              isLabelVisible: search.filters.activeCount > 0,
              count: search.filters.activeCount,
              child: const Icon(Icons.tune_rounded),
            ),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              children: <Widget>[
                for (final WorkerSort sort in WorkerSort.values)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: ChoiceChip(
                      label: Text(_sortLabel(s, sort)),
                      selected: search.filters.sort == sort,
                      onSelected: (_) => search.setSort(sort),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: FilterChip(
                    label: Text(s.filterVerifiedOnly),
                    selected: search.filters.verifiedOnly,
                    onSelected: (bool value) => search.applyFilters(
                      search.filters.copyWith(verifiedOnly: value),
                    ),
                  ),
                ),
                FilterChip(
                  label: Text(s.filterAvailableNow),
                  selected: search.filters.availableNow,
                  onSelected: (bool value) => search.applyFilters(
                    search.filters.copyWith(availableNow: value),
                  ),
                ),
              ],
            ),
          ),
          if (search.busy) const LinearProgressIndicator(minHeight: 2),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: <Widget>[
                Text(
                  s.resultsCount(count: search.results.length),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Expanded(
            child: search.busy && search.results.isEmpty
                ? const LoadingList()
                : search.isEmpty
                    ? EmptyState(
                        icon: Icons.person_search_outlined,
                        title: s.noResults,
                        body: s.noResultsBody,
                        actionLabel: s.resetFilters,
                        onAction: search.resetFilters,
                      )
                    : RefreshIndicator(
                        onRefresh: search.search,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            0,
                            AppSpacing.md,
                            AppSpacing.xl,
                          ),
                          itemCount: search.results.length,
                          separatorBuilder:
                              (BuildContext context, int index) =>
                                  const SizedBox(height: AppSpacing.md),
                          itemBuilder: (BuildContext context, int index) {
                            final WorkerProfile worker = search.results[index];
                            return WorkerCard(
                              worker: worker,
                              isFavorite: session.isFavorite(worker.id),
                              onToggleFavorite: session.isSignedIn
                                  ? () => session.toggleFavorite(worker.id)
                                  : null,
                              onTap: () => context
                                  .push(Routes.workerDetail(worker.id)),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  String _sortLabel(Strings s, WorkerSort sort) => switch (sort) {
        WorkerSort.rating => '${s.sortBy}: ${s.sortRating}',
        WorkerSort.price => '${s.sortBy}: ${s.sortPrice}',
        WorkerSort.distance => '${s.sortBy}: ${s.sortDistance}',
      };
}

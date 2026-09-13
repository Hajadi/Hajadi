import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/haiti_departments.dart';
import '../../core/constants/service_categories.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/search_filters.dart';

/// The full filter set: category, department, city, distance, price, rating,
/// verified-only and available-now.
Future<SearchFilters?> showFiltersSheet(
  BuildContext context,
  SearchFilters current,
) =>
    showModalBottomSheet<SearchFilters>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => FractionallySizedBox(
        heightFactor: 0.92,
        child: _FiltersSheet(initial: current),
      ),
    );

class _FiltersSheet extends StatefulWidget {
  const _FiltersSheet({required this.initial});

  final SearchFilters initial;

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  late SearchFilters _filters = widget.initial;

  List<String> get _cities {
    final HaitiDepartment? department =
        HaitiDepartment.fromId(_filters.departmentId);
    return department?.cities ?? HaitiDepartment.allCities;
  }

  @override
  Widget build(BuildContext context) {
    final Strings s = context.l10n;
    final ThemeData theme = Theme.of(context);
    final String localeCode = Localizations.localeOf(context).languageCode;

    return SafeArea(
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.sm,
              0,
            ),
            child: Row(
              children: <Widget>[
                Text(s.filters, style: theme.textTheme.headlineSmall),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(
                    () => _filters = SearchFilters(query: _filters.query),
                  ),
                  child: Text(s.resetFilters),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: <Widget>[
                _Label(s.filterCategory),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: <Widget>[
                    ChoiceChip(
                      label: Text(s.anyCategory),
                      selected: _filters.categoryId == null,
                      onSelected: (_) => setState(
                        () => _filters = _filters.copyWith(categoryId: null),
                      ),
                    ),
                    for (final ServiceCategory category
                        in ServiceCategory.values)
                      ChoiceChip(
                        label: Text(category.label(s)),
                        avatar: Icon(category.icon, size: 16),
                        selected: _filters.categoryId == category.id,
                        onSelected: (_) => setState(
                          () => _filters =
                              _filters.copyWith(categoryId: category.id),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _Label(s.filterDepartment),
                DropdownButtonFormField<String?>(
                  value: _filters.departmentId,
                  isExpanded: true,
                  items: <DropdownMenuItem<String?>>[
                    DropdownMenuItem<String?>(
                      child: Text(s.anyDepartment),
                    ),
                    for (final HaitiDepartment department
                        in HaitiDepartment.values)
                      DropdownMenuItem<String?>(
                        value: department.id,
                        child: Text(department.label(s)),
                      ),
                  ],
                  onChanged: (String? value) => setState(
                    () => _filters = _filters.copyWith(
                      departmentId: value,
                      city: null,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _Label(s.filterCity),
                DropdownButtonFormField<String?>(
                  value:
                      _cities.contains(_filters.city) ? _filters.city : null,
                  isExpanded: true,
                  items: <DropdownMenuItem<String?>>[
                    const DropdownMenuItem<String?>(child: Text('—')),
                    for (final String city in _cities)
                      DropdownMenuItem<String?>(value: city, child: Text(city)),
                  ],
                  onChanged: (String? value) => setState(
                    () => _filters = _filters.copyWith(city: value),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _Label(
                  '${s.filterDistance} · '
                  '${_filters.maxDistanceKm.round()} ${s.km}',
                ),
                Slider(
                  value: _filters.maxDistanceKm,
                  min: AppConfig.minDistanceKm,
                  max: AppConfig.maxDistanceKm,
                  divisions: 33,
                  label: '${_filters.maxDistanceKm.round()} ${s.km}',
                  onChanged: (double value) => setState(
                    () => _filters = _filters.copyWith(maxDistanceKm: value),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _Label(
                  '${s.filterPriceRange} · '
                  '${Formatters.money(_filters.minPrice, localeCode)} — '
                  '${Formatters.money(_filters.maxPrice, localeCode)}',
                ),
                RangeSlider(
                  values: RangeValues(_filters.minPrice, _filters.maxPrice),
                  min: AppConfig.minHourlyRate,
                  max: AppConfig.maxHourlyRate,
                  divisions: 20,
                  onChanged: (RangeValues values) => setState(
                    () => _filters = _filters.copyWith(
                      minPrice: values.start,
                      maxPrice: values.end,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _Label(s.filterRating),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: <Widget>[
                    for (final double rating in <double>[0, 3, 3.5, 4, 4.5])
                      ChoiceChip(
                        label: Text(
                          rating == 0
                              ? s.anyRating
                              : '${Formatters.rating(rating)}★+',
                        ),
                        selected: _filters.minRating == rating,
                        onSelected: (_) => setState(
                          () => _filters = _filters.copyWith(minRating: rating),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                SwitchListTile(
                  value: _filters.verifiedOnly,
                  onChanged: (bool value) => setState(
                    () => _filters = _filters.copyWith(verifiedOnly: value),
                  ),
                  title: Text(s.filterVerifiedOnly),
                  secondary: const Icon(Icons.verified_outlined),
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  value: _filters.availableNow,
                  onChanged: (bool value) => setState(
                    () => _filters = _filters.copyWith(availableNow: value),
                  ),
                  title: Text(s.filterAvailableNow),
                  secondary: const Icon(Icons.bolt_outlined),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(_filters),
              child: Text(s.applyFilters),
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Text(
          text,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontSize: 15),
        ),
      );
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/service_categories.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/category_tile.dart';
import '../../core/widgets/common.dart';

/// The full trade catalog, grouped.
///
/// The last group is "Other": the workers who typed a trade we do not list yet.
/// It is browsable on purpose — it is where a customer looks when the thing
/// they need has no tile, and where the product learns what to list next.
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Strings s = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(s.categories)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        children: <Widget>[
          for (final TradeGroup group in TradeGroup.values) ...<Widget>[
            SectionHeader(title: group.label(s)),
            if (group == TradeGroup.other)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: Text(
                  s.customTradeSearchNote,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 180,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: 1.05,
              ),
              itemCount: group.categories.length,
              itemBuilder: (BuildContext context, int index) {
                final ServiceCategory category = group.categories[index];
                return CategoryTile(
                  category: category,
                  onTap: () =>
                      context.go('${Routes.search}?category=${category.id}'),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

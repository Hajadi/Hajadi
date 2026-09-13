import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/service_categories.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/category_tile.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Strings s = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(s.categories)),
      body: GridView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 180,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.05,
        ),
        itemCount: ServiceCategory.values.length,
        itemBuilder: (BuildContext context, int index) {
          final ServiceCategory category = ServiceCategory.values[index];
          return CategoryTile(
            category: category,
            onTap: () => context.go('${Routes.search}?category=${category.id}'),
          );
        },
      ),
    );
  }
}

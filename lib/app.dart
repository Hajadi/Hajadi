import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/localization/app_localizations.dart';
import 'core/routing/app_router.dart';
import 'core/routing/user_scope.dart';
import 'core/theme/app_theme.dart';
import 'services/service_locator.dart';
import 'viewmodels/auth_view_model.dart';
import 'viewmodels/favorites_view_model.dart';
import 'viewmodels/payment_view_model.dart';
import 'viewmodels/review_view_model.dart';
import 'viewmodels/session_view_model.dart';

class JwennMetApp extends StatelessWidget {
  const JwennMetApp({super.key, required this.services});

  final Services services;

  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          Provider<Services>.value(value: services),
          ChangeNotifierProvider<SessionViewModel>(
            create: (_) => SessionViewModel(services),
          ),
          // Declared after the session so its `create` can read it.
          ChangeNotifierProvider<AuthViewModel>(
            create: (BuildContext context) => AuthViewModel(
              services,
              context.read<SessionViewModel>(),
            ),
          ),
          ChangeNotifierProvider<PaymentViewModel>(
            create: (_) => PaymentViewModel(services),
          ),
          ChangeNotifierProvider<ReviewViewModel>(
            create: (_) => ReviewViewModel(services),
          ),
          ChangeNotifierProvider<FavoritesViewModel>(
            create: (_) => FavoritesViewModel(services),
          ),
        ],
        child: const _AppView(),
      );
}

class _AppView extends StatefulWidget {
  const _AppView();

  @override
  State<_AppView> createState() => _AppViewState();
}

class _AppViewState extends State<_AppView> {
  // Built once: the router listens to the session itself, and rebuilding it on
  // every notification would reset the navigation stack.
  late final GoRouter _router =
      buildRouter(context.read<SessionViewModel>());

  @override
  Widget build(BuildContext context) {
    final SessionViewModel session = context.watch<SessionViewModel>();

    return MaterialApp.router(
      title: 'Jwenn Mèt',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: session.themeMode,
      locale: session.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      // Kreyòl first: it is what most users in Haiti read, and it is the
      // fallback when the device asks for a language we do not ship.
      localeListResolutionCallback: (
        List<Locale>? locales,
        Iterable<Locale> supported,
      ) {
        for (final Locale locale in locales ?? const <Locale>[]) {
          for (final Locale candidate in supported) {
            if (candidate.languageCode == locale.languageCode) {
              return candidate;
            }
          }
        }
        return const Locale('ht');
      },
      builder: (BuildContext context, Widget? child) => UserScope(
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}

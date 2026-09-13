import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../models/chat.dart';
import '../../models/search_filters.dart';
import '../../models/worker_profile.dart';
import '../../services/service_locator.dart';
import '../../viewmodels/booking_view_model.dart';
import '../../viewmodels/chat_view_model.dart';
import '../../viewmodels/home_view_model.dart';
import '../../viewmodels/search_view_model.dart';
import '../../viewmodels/session_view_model.dart';
import '../../viewmodels/worker_detail_view_model.dart';
import '../../views/admin/admin_dashboard_screen.dart';
import '../../views/admin/admin_reports_screen.dart';
import '../../views/admin/admin_reviews_screen.dart';
import '../../views/admin/admin_users_screen.dart';
import '../../views/admin/admin_verifications_screen.dart';
import '../../views/auth/forgot_password_screen.dart';
import '../../views/auth/login_screen.dart';
import '../../views/auth/phone_screen.dart';
import '../../views/auth/signup_screen.dart';
import '../../views/booking/booking_screen.dart';
import '../../views/booking/job_detail_screen.dart';
import '../../views/booking/jobs_screen.dart';
import '../../views/chat/chat_screen.dart';
import '../../views/chat/conversations_screen.dart';
import '../../views/dashboard/earnings_screen.dart';
import '../../views/dashboard/verification_screen.dart';
import '../../views/dashboard/worker_dashboard_screen.dart';
import '../../views/dashboard/worker_profile_edit_screen.dart';
import '../../views/favorites/favorites_screen.dart';
import '../../views/home/app_shell.dart';
import '../../views/home/categories_screen.dart';
import '../../views/home/home_screen.dart';
import '../../views/notifications/notifications_screen.dart';
import '../../views/onboarding/language_screen.dart';
import '../../views/onboarding/onboarding_screen.dart';
import '../../views/onboarding/role_screen.dart';
import '../../views/reviews/write_review_screen.dart';
import '../../views/search/search_screen.dart';
import '../../views/settings/profile_screen.dart';
import '../../views/settings/settings_screen.dart';
import '../../views/splash/splash_screen.dart';
import '../../views/worker/reviews_screen.dart';
import '../../views/worker/worker_profile_screen.dart';
import 'routes.dart';

/// Builds the router. [session] drives every redirect and is also what the
/// router listens to, so a sign-out or a language choice re-evaluates the
/// current location immediately.
GoRouter buildRouter(SessionViewModel session) {
  final GlobalKey<NavigatorState> rootKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> shellKey = GlobalKey<NavigatorState>();

  const Set<String> authRoutes = <String>{
    Routes.login,
    Routes.signup,
    Routes.role,
    Routes.phone,
    Routes.forgotPassword,
  };

  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: Routes.splash,
    refreshListenable: session,
    redirect: (BuildContext context, GoRouterState state) {
      final String location = state.uri.path;

      // 1. Wait for auth and preferences to be restored.
      if (!session.bootstrapped) {
        return location == Routes.splash ? null : Routes.splash;
      }
      // 2. Language is the first decision the app asks for.
      if (!session.hasChosenLanguage) {
        return location == Routes.language ? null : Routes.language;
      }
      // 3. Then the one-time value pitch.
      if (!session.onboardingDone && !session.isSignedIn) {
        return location == Routes.onboarding ? null : Routes.onboarding;
      }
      // 4. Signed out: only the auth routes are reachable.
      if (!session.isSignedIn) {
        return authRoutes.contains(location) ? null : Routes.login;
      }
      // 5. Signed in: keep each role on its own home.
      if (location == Routes.splash ||
          location == Routes.language ||
          location == Routes.onboarding ||
          authRoutes.contains(location)) {
        return _homeFor(session);
      }
      if (session.isWorker && location == Routes.home) {
        return Routes.dashboard;
      }
      if (!session.isWorker && location == Routes.dashboard) {
        return Routes.home;
      }
      if (location.startsWith(Routes.admin) && !session.isAdmin) {
        return _homeFor(session);
      }
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: Routes.splash,
        builder: (BuildContext context, GoRouterState state) =>
            const SplashScreen(),
      ),
      GoRoute(
        path: Routes.language,
        builder: (BuildContext context, GoRouterState state) =>
            const LanguageScreen(),
      ),
      GoRoute(
        path: Routes.onboarding,
        builder: (BuildContext context, GoRouterState state) =>
            const OnboardingScreen(),
      ),
      GoRoute(
        path: Routes.role,
        builder: (BuildContext context, GoRouterState state) =>
            const RoleScreen(),
      ),
      GoRoute(
        path: Routes.login,
        builder: (BuildContext context, GoRouterState state) =>
            const LoginScreen(),
      ),
      GoRoute(
        path: Routes.signup,
        builder: (BuildContext context, GoRouterState state) =>
            const SignupScreen(),
      ),
      GoRoute(
        path: Routes.phone,
        builder: (BuildContext context, GoRouterState state) =>
            const PhoneScreen(),
      ),
      GoRoute(
        path: Routes.forgotPassword,
        builder: (BuildContext context, GoRouterState state) =>
            const ForgotPasswordScreen(),
      ),

      // ------------------------------------------------------------ shell
      ShellRoute(
        navigatorKey: shellKey,
        builder: (BuildContext context, GoRouterState state, Widget child) =>
            AppShell(child: child),
        routes: <RouteBase>[
          GoRoute(
            path: Routes.home,
            builder: (BuildContext context, GoRouterState state) =>
                ChangeNotifierProvider<HomeViewModel>(
              create: (BuildContext context) =>
                  HomeViewModel(context.read<SessionViewModel>().services),
              child: const HomeScreen(),
            ),
          ),
          GoRoute(
            path: Routes.search,
            builder: (BuildContext context, GoRouterState state) {
              final String? category = state.uri.queryParameters['category'];
              final String? department =
                  state.uri.queryParameters['department'];
              return ChangeNotifierProvider<SearchViewModel>(
                // Keyed on the query so tapping a different category from the
                // home grid really re-runs the search.
                key: ValueKey<String>('$category|$department'),
                create: (BuildContext context) => SearchViewModel(
                  context.read<SessionViewModel>().services,
                  initialFilters: SearchFilters(
                    categoryId: category,
                    departmentId: department,
                  ),
                ),
                child: const SearchScreen(),
              );
            },
          ),
          GoRoute(
            path: Routes.jobs,
            builder: (BuildContext context, GoRouterState state) =>
                const JobsScreen(),
          ),
          GoRoute(
            path: Routes.chats,
            builder: (BuildContext context, GoRouterState state) =>
                const ConversationsScreen(),
          ),
          GoRoute(
            path: Routes.profile,
            builder: (BuildContext context, GoRouterState state) =>
                const ProfileScreen(),
          ),
          GoRoute(
            path: Routes.dashboard,
            builder: (BuildContext context, GoRouterState state) =>
                const _WorkerDashboardRoute(),
          ),
        ],
      ),

      // --------------------------------------------------------- details
      GoRoute(
        path: Routes.categories,
        builder: (BuildContext context, GoRouterState state) =>
            const CategoriesScreen(),
      ),
      GoRoute(
        path: Routes.favorites,
        builder: (BuildContext context, GoRouterState state) =>
            const FavoritesScreen(),
      ),
      GoRoute(
        path: Routes.notifications,
        builder: (BuildContext context, GoRouterState state) =>
            const NotificationsScreen(),
      ),
      GoRoute(
        path: Routes.settings,
        builder: (BuildContext context, GoRouterState state) =>
            const SettingsScreen(),
      ),
      GoRoute(
        path: '${Routes.worker}/:id',
        builder: (BuildContext context, GoRouterState state) =>
            _workerScope(context, state, const WorkerProfileScreen()),
        routes: <RouteBase>[
          GoRoute(
            path: 'reviews',
            builder: (BuildContext context, GoRouterState state) =>
                _workerScope(context, state, const ReviewsScreen()),
          ),
          GoRoute(
            path: 'book',
            builder: (BuildContext context, GoRouterState state) =>
                _BookingRoute(workerId: state.pathParameters['id'] ?? ''),
          ),
        ],
      ),
      GoRoute(
        path: '${Routes.job}/:id',
        builder: (BuildContext context, GoRouterState state) =>
            JobDetailScreen(jobId: state.pathParameters['id'] ?? ''),
        routes: <RouteBase>[
          GoRoute(
            path: 'review',
            builder: (BuildContext context, GoRouterState state) =>
                WriteReviewScreen(jobId: state.pathParameters['id'] ?? ''),
          ),
        ],
      ),
      GoRoute(
        path: '${Routes.chat}/:id',
        builder: (BuildContext context, GoRouterState state) =>
            _ChatRoute(conversationId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: Routes.dashboardProfile,
        builder: (BuildContext context, GoRouterState state) =>
            const WorkerProfileEditScreen(),
      ),
      GoRoute(
        path: Routes.dashboardVerification,
        builder: (BuildContext context, GoRouterState state) =>
            const VerificationScreen(),
      ),
      GoRoute(
        path: Routes.dashboardEarnings,
        builder: (BuildContext context, GoRouterState state) =>
            const EarningsScreen(),
      ),

      // ----------------------------------------------------------- admin
      GoRoute(
        path: Routes.admin,
        builder: (BuildContext context, GoRouterState state) =>
            const AdminDashboardScreen(),
      ),
      GoRoute(
        path: Routes.adminVerifications,
        builder: (BuildContext context, GoRouterState state) =>
            const AdminVerificationsScreen(),
      ),
      GoRoute(
        path: Routes.adminReports,
        builder: (BuildContext context, GoRouterState state) =>
            const AdminReportsScreen(),
      ),
      GoRoute(
        path: Routes.adminUsers,
        builder: (BuildContext context, GoRouterState state) =>
            const AdminUsersScreen(),
      ),
      GoRoute(
        path: Routes.adminReviews,
        builder: (BuildContext context, GoRouterState state) =>
            const AdminReviewsScreen(),
      ),
    ],
    errorBuilder: (BuildContext context, GoRouterState state) => Scaffold(
      appBar: AppBar(),
      body: Center(child: Text('${state.error}')),
    ),
  );
}

String _homeFor(SessionViewModel session) {
  if (session.isAdmin) {
    return Routes.admin;
  }
  return session.isWorker ? Routes.dashboard : Routes.home;
}

Widget _workerScope(BuildContext context, GoRouterState state, Widget child) =>
    ChangeNotifierProvider<WorkerDetailViewModel>(
      create: (BuildContext context) => WorkerDetailViewModel(
        context.read<SessionViewModel>().services,
        state.pathParameters['id'] ?? '',
      ),
      child: child,
    );

/// The dashboard needs the worker's own profile document; until it arrives
/// (first launch after sign-up, or a cold start offline) we hold a spinner
/// rather than render an empty shell.
class _WorkerDashboardRoute extends StatelessWidget {
  const _WorkerDashboardRoute();

  @override
  Widget build(BuildContext context) {
    final SessionViewModel session = context.watch<SessionViewModel>();
    if (session.workerProfile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return const WorkerDashboardScreen();
  }
}

/// Loads the worker being booked, then hands the form its view-model.
class _BookingRoute extends StatelessWidget {
  const _BookingRoute({required this.workerId});

  final String workerId;

  @override
  Widget build(BuildContext context) {
    final SessionViewModel session = context.watch<SessionViewModel>();
    final Services services = session.services;
    final AppUser? user = session.user;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return FutureBuilder<WorkerProfile?>(
      future: services.data.fetchWorker(workerId),
      builder: (
        BuildContext context,
        AsyncSnapshot<WorkerProfile?> snapshot,
      ) {
        final WorkerProfile? worker = snapshot.data;
        if (worker == null) {
          return Scaffold(
            appBar: AppBar(),
            body: snapshot.connectionState == ConnectionState.waiting
                ? const Center(child: CircularProgressIndicator())
                : const SizedBox.shrink(),
          );
        }
        return ChangeNotifierProvider<BookingViewModel>(
          create: (_) => BookingViewModel(services, worker, user),
          child: const BookingScreen(),
        );
      },
    );
  }
}

/// Resolves the thread header from the inbox the user already has open.
class _ChatRoute extends StatelessWidget {
  const _ChatRoute({required this.conversationId});

  final String conversationId;

  @override
  Widget build(BuildContext context) {
    final SessionViewModel session = context.watch<SessionViewModel>();
    final ConversationsViewModel conversations =
        context.watch<ConversationsViewModel>();
    final AppUser? user = session.user;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final Iterable<Conversation> matches = conversations.conversations
        .where((Conversation conversation) => conversation.id == conversationId);
    if (matches.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final Conversation conversation = matches.first;

    return ChangeNotifierProvider<ChatViewModel>(
      create: (_) => ChatViewModel(
        session.services,
        conversationId: conversationId,
        me: user,
        otherId: conversation.otherParticipantId(user.id),
      ),
      child: ChatScreen(
        title: conversation.titleFor(user.id),
        photoUrl: conversation.photoFor(user.id),
      ),
    );
  }
}

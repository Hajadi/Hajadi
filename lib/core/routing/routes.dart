/// Every route path in one place, so deep links and redirects can't drift.
abstract final class Routes {
  static const String splash = '/';
  static const String language = '/language';
  static const String onboarding = '/onboarding';
  static const String role = '/role';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String phone = '/phone';
  static const String forgotPassword = '/forgot-password';

  static const String home = '/home';
  static const String search = '/search';
  static const String categories = '/categories';
  static const String jobs = '/jobs';
  static const String chats = '/chats';
  static const String profile = '/profile';

  static const String favorites = '/favorites';
  static const String notifications = '/notifications';
  static const String settings = '/settings';

  static const String worker = '/worker';
  static String workerDetail(String id) => '$worker/$id';
  static String workerReviews(String id) => '$worker/$id/reviews';
  static String book(String id) => '$worker/$id/book';

  static const String job = '/job';
  static String jobDetail(String id) => '$job/$id';
  static String review(String jobId) => '$job/$jobId/review';

  static const String chat = '/chat';
  static String chatThread(String conversationId) => '$chat/$conversationId';

  static const String dashboard = '/dashboard';
  static const String dashboardProfile = '/dashboard/profile';
  static const String dashboardVerification = '/dashboard/verification';
  static const String dashboardEarnings = '/dashboard/earnings';

  static const String admin = '/admin';
  static const String adminVerifications = '/admin/verifications';
  static const String adminReports = '/admin/reports';
  static const String adminUsers = '/admin/users';
  static const String adminReviews = '/admin/reviews';
}

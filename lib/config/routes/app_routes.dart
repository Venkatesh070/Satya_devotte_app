class AppRoutes {
  // ─── App routes ───────────────────────────────────────────────
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String home = '/home';
  static const String rituals = '/rituals';
  static const String ritualDetail = '/ritual-detail';

  // ─── CMS routes (admin + superadmin) ─────────────────────────
  static const String cms = '/cms';
  static const String cmsDeities = '/cms/deities';
  static const String cmsDeityCreate = '/cms/deities/create';
  static const String cmsDeityEdit = '/cms/deities/edit';
  static const String cmsRituals = '/cms/rituals';
  static const String cmsRitualCreate = '/cms/rituals/create';
  static const String cmsRitualEdit = '/cms/rituals/edit';
  static const String cmsFestivals = '/cms/festivals';
  static const String cmsFestivalCreate = '/cms/festivals/create';
  static const String cmsUsers = '/cms/users';
  static const String cmsNotifications = '/cms/notifications';
  static const String cmsAnalytics = '/cms/analytics';

  // ─── Super Admin only ─────────────────────────────────────────
  static const String cmsApproval = '/cms/approval';
  static const String cmsAdmins = '/cms/admins';
  static const String cmsShlokas = '/cms/shlokas';
}

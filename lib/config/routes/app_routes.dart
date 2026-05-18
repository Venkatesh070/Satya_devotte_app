class AppRoutes {
  // ─── App routes ───────────────────────────────────────────────
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String home = '/home';
  static const String rituals = '/rituals';
  static const String ritualDetail = '/ritual-detail';

  // ─── User-facing donations flow ───────────────────────────────
  /// All approved donations (full list).
  static const String userDonations = '/donations';

  /// Single donation details. Pass `DonationModel` via `arguments`.
  static const String userDonationDetails = '/donations/details';

  /// Post-Paystack confirming screen. Pass `DonationInitData`.
  static const String userDonationConfirming = '/donations/confirming';

  /// Terminal screens. Pass `VerifyResult` (success) or
  /// `DonationFailedArgs` (failed).
  static const String userDonationSuccess = '/donations/success';
  static const String userDonationFailed = '/donations/failed';

  /// Authenticated user's contribution history.
  static const String userContributions = '/donations/contributions';

  // ─── Pooja Kit flow ──────────────────────────────────────────
  /// Single pooja kit details. Pass `ProductModel` via `arguments`.
  static const String poojaKitDetails = '/pooja-kit/details';

  /// Checkout screen for pooja kit.
  static const String poojaKitCheckout = '/pooja-kit/checkout';

  /// WebView for Paystack payment. Pass `OrderInitData`.
  static const String poojaKitPayment = '/pooja-kit/payment';

  /// Success screen after order placement.
  static const String poojaKitOrderSuccess = '/pooja-kit/success';

  /// User's order history.
  static const String userOrders = '/user/orders';

  // ─── CMS routes (admin + superadmin) ─────────────────────────
  static const String cms = '/cms';
  static const String cmsDeities = '/cms/deities';
  static const String cmsDeityCreate = '/cms/deities/create';
  static const String cmsDeityEdit = '/cms/deities/edit';
  static const String cmsRituals = '/cms/rituals';
  static const String cmsRitualCreate = '/cms/rituals/create';
  static const String cmsRitualEdit = '/cms/rituals/edit';
  /// Top-level "Manage Rituals" sidebar tab. Distinct from `cmsRituals`
  /// which is the historical "Manage Pujas" entry.
  static const String cmsManageRituals = '/cms/manage-rituals';
  static const String cmsFestivals = '/cms/festivals';
  static const String cmsFestivalCreate = '/cms/festivals/create';
  static const String cmsUsers = '/cms/users';
  static const String cmsNotifications = '/cms/notifications';
  static const String cmsAnalytics = '/cms/analytics';

  // ─── Pooja Kit (admin + superadmin) ──────────────────────────
  /// Stock levels for approved Puja Kit products.
  static const String cmsPoojaKitInventory = '/cms/pooja-kit/inventory';

  /// Manage Pooja Kit listing / create / edit.
  static const String cmsPoojaKit = '/cms/pooja-kit';

  /// Pooja Kit orders placed by devotees.
  static const String cmsPoojaKitOrders = '/cms/pooja-kit/orders';
  /// Pooja Kit: replace, cancel & refund order requests (admin inbox).
  static const String cmsPoojaKitRefunds = '/cms/pooja-kit/refunds';
  /// Pooja Kit payments overview.
  static const String cmsPoojaKitPayments = '/cms/pooja-kit/payments';

  // ─── Donations (admin + superadmin) ──────────────────────────
  /// Admin's own donation campaigns (create / edit / review).
  static const String cmsDonations = '/cms/donations';

  /// All donations across admins (super-admin overview list).
  static const String cmsDonationsAll = '/cms/donations/all';

  // ─── Super Admin only ─────────────────────────────────────────
  static const String cmsApproval = '/cms/approval';
  static const String cmsAdmins = '/cms/admins';
  static const String cmsShlokas = '/cms/shlokas';
}

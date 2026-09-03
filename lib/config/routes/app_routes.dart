class AppRoutes {
  // ─── App routes ───────────────────────────────────────────────
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String createAccount = '/create-account';
  static const String emailVerification = '/email-verification';
  static const String home = '/home';
  static const String notifications = '/notifications';
  static const String rituals = '/rituals';
  static const String ritualDetail = '/ritual-detail';
  static const String poojaHistory = '/pooja-history';
  static const String ritualHistory = '/ritual-history';
  static const String poojaWizard = '/pooja-wizard';
  static const String editProfile = '/edit-profile';
  static const String search = '/search';

  // ─── User-facing donations flow ───────────────────────────────
  /// All approved donations (full list).
  static const String userDonations = '/donations';

  /// Single donation details. Pass `DonationModel` via `arguments`.
  static const String userDonationDetails = '/donations/details';

  /// Post-PayFast confirming screen. Pass `DonationInitData`.
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

  /// Cart screen for pooja kit.
  static const String poojaKitCart = '/pooja-kit/cart';

  /// WebView for PayFast payment. Pass `OrderInitData`.
  static const String poojaKitPayment = '/pooja-kit/payment';

  /// Success screen after order placement.
  static const String poojaKitOrderSuccess = '/pooja-kit/success';

  /// User's order history.
  static const String userOrders = '/user/orders';

  /// Single order detail.
  static const String userOrderDetail = '/user/orders/detail';

  // ─── CMS routes (admin + superadmin) ─────────────────────────
  static const String cms = '/cms';
  static const String cmsDeities = '/cms/deities';
  static const String cmsDeityCreate = '/cms/deities/create';
  static const String cmsDeityEdit = '/cms/deities/edit';
  static const String cmsPujas = '/cms/pujas';
  static const String cmsPujaCreate = '/cms/pujas/create';
  static const String cmsPujaEdit = '/cms/pujas/edit';

  /// Legacy paths kept for bookmarked URLs.
  static const String cmsRituals = '/cms/rituals';
  static const String cmsRitualCreate = '/cms/rituals/create';
  static const String cmsRitualEdit = '/cms/rituals/edit';

  /// Top-level "Manage Rituals" sidebar tab. Distinct from [cmsPujas]
  /// which is the "Manage Pujas" entry.
  static const String cmsManageRituals = '/cms/manage-rituals';
  static const String cmsFestivals = '/cms/festivals';
  static const String cmsFestivalCreate = '/cms/festivals/create';
  static const String cmsUsers = '/cms/users';
  static const String cmsNotifications = '/cms/notifications';

  /// Operational alerts inbox (orders, donations, refund requests).
  static const String cmsActivity = '/cms/activity';

  static const String cmsAnalytics = '/cms/analytics';

  // ─── Pooja Kit (admin + superadmin) ──────────────────────────
  /// Stock levels for approved Puja Kit products.
  static const String cmsPoojaKitInventory = '/cms/products/inventory';

  /// Manage Pooja Kit listing / create / edit.
  static const String cmsPoojaKit = '/cms/products';

  /// Pooja Kit orders placed by devotees.
  static const String cmsPoojaKitOrders = '/cms/products/orders';

  /// In-shell order detail (web hash). Use [cmsPoojaKitOrderPath] for URLs.
  static const String cmsPoojaKitOrderDetail = '/cms/products/orders/:orderId';

  static String cmsPoojaKitOrderPath(String orderId) =>
      '$cmsPoojaKitOrders/$orderId';

  /// Pooja Kit refund requests / processed refunds.
  static const String cmsPoojaKitRefunds = '/cms/products/replacements';

  /// Pooja Kit payments overview.
  static const String cmsPoojaKitPayments = '/cms/products/payments';

  /// Ecommerce store settings (VAT number and percentage).
  static const String cmsPoojaKitSettings = '/cms/products/settings';

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

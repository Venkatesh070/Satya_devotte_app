import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/config/routes/route_guard.dart';
import 'package:satya_devotte_app/features/auth/presentation/pages/login_page.dart';
import 'package:satya_devotte_app/features/auth/presentation/pages/web_login_page.dart';
import 'package:satya_devotte_app/features/cms/presentation/pages/cms_shell_page.dart';
import 'package:satya_devotte_app/features/donations/presentation/pages/donation_details_screen.dart';
import 'package:satya_devotte_app/features/donations/presentation/pages/donation_paystack_webview_screen.dart';
import 'package:satya_devotte_app/features/donations/presentation/pages/donation_failed_screen.dart';
import 'package:satya_devotte_app/features/donations/presentation/pages/donation_success_screen.dart';
import 'package:satya_devotte_app/features/donations/presentation/pages/donations_list_screen.dart';
import 'package:satya_devotte_app/features/donations/presentation/pages/my_contributions_screen.dart';
import 'package:satya_devotte_app/features/poojakit/presentation/pages/product_details_page.dart';
import 'package:satya_devotte_app/features/poojakit/presentation/pages/product_checkout_page.dart';
import 'package:satya_devotte_app/features/poojakit/presentation/pages/product_payment_webview_screen.dart';
import 'package:satya_devotte_app/features/poojakit/presentation/pages/order_success_screen.dart';
import 'package:satya_devotte_app/features/poojakit/presentation/pages/user_order_detail_screen.dart';
import 'package:satya_devotte_app/features/poojakit/presentation/pages/user_orders_screen.dart';
import 'package:satya_devotte_app/features/poojakit/presentation/pages/cart_screen.dart';
import 'package:satya_devotte_app/features/poojakit/bindings/user_orders_binding.dart';
import 'package:satya_devotte_app/features/home/presentation/pages/bottom_tab_page.dart';
import 'package:satya_devotte_app/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:satya_devotte_app/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:satya_devotte_app/features/pujas/bindings/puja_binding.dart';
import 'package:satya_devotte_app/features/pujas/presentation/pages/puja_detail_page.dart';
import 'package:satya_devotte_app/features/pujas/presentation/pages/puja_list_page.dart';
import 'package:satya_devotte_app/features/splash/presentation/pages/splash_page.dart';

class AppPages {
  static final pages = <GetPage<dynamic>>[
    GetPage(
      name: AppRoutes.userOrders,
      page: () => const UserOrdersScreen(),
      binding: UserOrdersBinding(),
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: AppRoutes.userOrderDetail,
      page: () => const UserOrderDetailScreen(),
      binding: UserOrdersBinding(),
      middlewares: [AuthGuard()],
    ),
    // ─── App flow ───────────────────────────────────────────────
    GetPage(name: AppRoutes.splash, page: SplashPage.new),
    if (!kIsWeb) GetPage(name: AppRoutes.onboarding, page: OnboardingPage.new),
    GetPage(
      name: AppRoutes.login,
      page: () => kIsWeb ? const WebLoginPage() : const LoginPage(),
    ),
    GetPage(
      name: AppRoutes.home,
      page: BottomTabPage.new,
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: AppRoutes.editProfile,
      page: () => const EditProfilePage(),
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: AppRoutes.rituals,
      page: RitualListPage.new,
      binding: RitualBinding(),
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: AppRoutes.ritualDetail,
      page: RitualDetailPage.new,
      binding: RitualBinding(),
      middlewares: [AuthGuard()],
    ),

    // ─── User-facing donations flow ─────────────────────────────
    GetPage(
      name: AppRoutes.userDonations,
      page: DonationsListScreen.new,
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: AppRoutes.userDonationDetails,
      page: DonationDetailsScreen.new,
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: AppRoutes.userDonationConfirming,
      page: DonationPaystackWebViewScreen.new,
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: AppRoutes.userDonationSuccess,
      page: DonationSuccessScreen.new,
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: AppRoutes.userDonationFailed,
      page: DonationFailedScreen.new,
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: AppRoutes.userContributions,
      page: MyContributionsScreen.new,
      middlewares: [AuthGuard()],
    ),

    // ─── Pooja Kit flow ────────────────────────────────────────
    GetPage(
      name: AppRoutes.poojaKitDetails,
      page: ProductDetailsPage.new,
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: AppRoutes.poojaKitCheckout,
      page: ProductCheckoutPage.new,
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: AppRoutes.poojaKitCart,
      page: () => const CartScreen(),
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: AppRoutes.poojaKitPayment,
      page: ProductPaymentWebViewScreen.new,
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: AppRoutes.poojaKitOrderSuccess,
      page: OrderSuccessScreen.new,
      middlewares: [AuthGuard()],
    ),

    // ─── CMS (admin + superadmin) ───────────────────────────────
    // All CMS routes render the same `CmsShellPage`; the shell
    // switches its content based on the selected sidebar item.
    // Disable the default GetX page transition so tab clicks do not
    // animate (which on Flutter web shows up as a "shrinking" zoom).
    GetPage(
      name: AppRoutes.cms,
      page: CmsShellPage.new,
      middlewares: [AdminGuard()],
      transition: Transition.noTransition,
      transitionDuration: Duration.zero,
    ),
    GetPage(
      name: AppRoutes.cmsDeities,
      page: CmsShellPage.new,
      middlewares: [AdminGuard()],
      transition: Transition.noTransition,
      transitionDuration: Duration.zero,
    ),
    GetPage(
      name: AppRoutes.cmsRituals,
      page: CmsShellPage.new,
      middlewares: [AdminGuard()],
      transition: Transition.noTransition,
      transitionDuration: Duration.zero,
    ),
    GetPage(
      name: AppRoutes.cmsRitualCreate,
      page: CmsShellPage.new,
      middlewares: [AdminGuard()],
      transition: Transition.noTransition,
      transitionDuration: Duration.zero,
    ),
    GetPage(
      name: AppRoutes.cmsRitualEdit,
      page: CmsShellPage.new,
      middlewares: [AdminGuard()],
      transition: Transition.noTransition,
      transitionDuration: Duration.zero,
    ),
    GetPage(
      name: AppRoutes.cmsManageRituals,
      page: CmsShellPage.new,
      middlewares: [AdminGuard()],
      transition: Transition.noTransition,
      transitionDuration: Duration.zero,
    ),
    GetPage(
      name: AppRoutes.cmsFestivals,
      page: CmsShellPage.new,
      middlewares: [AdminGuard()],
      transition: Transition.noTransition,
      transitionDuration: Duration.zero,
    ),
    GetPage(
      name: AppRoutes.cmsUsers,
      page: CmsShellPage.new,
      middlewares: [AdminGuard()],
      transition: Transition.noTransition,
      transitionDuration: Duration.zero,
    ),
    GetPage(
      name: AppRoutes.cmsNotifications,
      page: CmsShellPage.new,
      middlewares: [AdminGuard()],
      transition: Transition.noTransition,
      transitionDuration: Duration.zero,
    ),
    GetPage(
      name: AppRoutes.cmsActivity,
      page: CmsShellPage.new,
      middlewares: [AdminGuard()],
      transition: Transition.noTransition,
      transitionDuration: Duration.zero,
    ),
    GetPage(
      name: AppRoutes.cmsAnalytics,
      page: CmsShellPage.new,
      middlewares: [AdminGuard()],
      transition: Transition.noTransition,
      transitionDuration: Duration.zero,
    ),
    GetPage(
      name: AppRoutes.cmsPoojaKitInventory,
      page: CmsShellPage.new,
      middlewares: [AdminGuard()],
      transition: Transition.noTransition,
      transitionDuration: Duration.zero,
    ),
    GetPage(
      name: AppRoutes.cmsPoojaKit,
      page: CmsShellPage.new,
      middlewares: [AdminGuard()],
      transition: Transition.noTransition,
      transitionDuration: Duration.zero,
    ),
    GetPage(
      name: AppRoutes.cmsPoojaKitOrders,
      page: CmsShellPage.new,
      middlewares: [AdminGuard()],
      transition: Transition.noTransition,
      transitionDuration: Duration.zero,
    ),
    GetPage(
      name: AppRoutes.cmsPoojaKitOrderDetail,
      page: CmsShellPage.new,
      middlewares: [AdminGuard()],
      transition: Transition.noTransition,
      transitionDuration: Duration.zero,
    ),
    GetPage(
      name: AppRoutes.cmsPoojaKitRefunds,
      page: CmsShellPage.new,
      middlewares: [AdminGuard()],
      transition: Transition.noTransition,
      transitionDuration: Duration.zero,
    ),
    GetPage(
      name: AppRoutes.cmsPoojaKitPayments,
      page: CmsShellPage.new,
      middlewares: [AdminGuard()],
      transition: Transition.noTransition,
      transitionDuration: Duration.zero,
    ),
    GetPage(
      name: AppRoutes.cmsDonations,
      page: CmsShellPage.new,
      middlewares: [AdminGuard()],
      transition: Transition.noTransition,
      transitionDuration: Duration.zero,
    ),
    GetPage(
      name: AppRoutes.cmsDonationsAll,
      page: CmsShellPage.new,
      middlewares: [AdminGuard()],
      transition: Transition.noTransition,
      transitionDuration: Duration.zero,
    ),

    // ─── Super Admin only ───────────────────────────────────────
    GetPage(
      name: AppRoutes.cmsApproval,
      page: CmsShellPage.new,
      middlewares: [SuperAdminGuard()],
      transition: Transition.noTransition,
      transitionDuration: Duration.zero,
    ),
    GetPage(
      name: AppRoutes.cmsAdmins,
      page: CmsShellPage.new,
      middlewares: [SuperAdminGuard()],
      transition: Transition.noTransition,
      transitionDuration: Duration.zero,
    ),
    GetPage(
      name: AppRoutes.cmsShlokas,
      page: CmsShellPage.new,
      middlewares: [SuperAdminGuard()],
      transition: Transition.noTransition,
      transitionDuration: Duration.zero,
    ),
  ];
}

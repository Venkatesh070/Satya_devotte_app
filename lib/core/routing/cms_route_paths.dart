import 'package:satya_devotte_app/config/routes/app_routes.dart';

/// CMS path helpers for hash / deep-link parsing (web).
class CmsRoutePaths {
  CmsRoutePaths._();

  static final RegExp _poojaKitOrderDetail = RegExp(
    r'^/cms/pooja-kit/orders/([^/]+)$',
  );

  /// e.g. `/cms/pooja-kit/orders/6a0d5fea08407f70c95cb320`
  static String poojaKitOrderDetail(String orderId) =>
      '${AppRoutes.cmsPoojaKitOrders}/$orderId';

  /// Returns Mongo order id when [route] is an order-detail path.
  static String? poojaKitOrderIdFromRoute(String route) {
    final path = route.trim();
    if (path.isEmpty) return null;
    final normalized = path.startsWith('/') ? path : '/$path';
    return _poojaKitOrderDetail.firstMatch(normalized)?.group(1);
  }

  static bool isPoojaKitOrdersSection(String route) {
    final normalized =
        route.trim().startsWith('/') ? route.trim() : '/${route.trim()}';
    return normalized == AppRoutes.cmsPoojaKitOrders ||
        poojaKitOrderIdFromRoute(normalized) != null;
  }
}

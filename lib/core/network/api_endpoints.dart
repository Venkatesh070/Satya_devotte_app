class ApiEndpoints {
  static const String authLogin = '/api/v1/auth/login';
  static const String authAdminLogin = '/api/v1/auth/admin/login';
  
  static const String authLogout = '/api/v1/auth/logout';
  static const String authRefresh = '/api/v1/auth/refresh';
  static const String profile = '/api/v1/auth/profile';
  // ── Poojas ────────────────────────────────────────────────
  static const String poojas = '/api/v1/poojas'; // GET — all poojas (public)
  static const String festivals =
      '/api/v1/festivals'; // GET — all festivals (public)
  static const String myPoojas =
      '/api/v1/poojas/my'; // GET — admin's own poojas (admin role)
  static const String allPoojas =
      '/api/v1/poojas/all'; // GET — all poojas all statuses (super admin)
  static const String createPooja = '/api/v1/poojas/create-pooja'; // POST
  static const String deities = '/api/v1/deities'; // GET
  static const String allDeities = '/api/v1/deities/all'; // GET
  static const String createDeity = '/api/v1/deities/create-deity'; // POST
  static String deity(String id) => '/api/v1/deities/$id'; // GET by id
  static String reviewDeity(String id) => '/api/v1/deities/review/$id'; // PUT
  static String updateDeity(String id) => '/api/v1/deities/$id'; // PATCH
  static String deleteDeity(String id) => '/api/v1/deities/$id'; // DELETE
  static String pooja(String id) => '/api/v1/poojas/$id'; // GET by id
  static String updatePooja(String id) => '/api/v1/poojas/$id'; // PATCH
  static String deletePooja(String id) => '/api/v1/poojas/$id'; // DELETE
  static String reviewPooja(String id) =>
      '/api/v1/poojas/review/$id'; // PUT — approve/reject (super admin)
  static const String home = '/api/v1/user-home';
  static const String calendar = '/api/v1/calendar';
  static const String subscribeNotification = '/api/v1/notifications/subscribe';
  /// Super Admin — invite/create admin user (POST JSON body).
  static const String superadminCreateAdmin = '/api/v1/superadmin/admins';

  /// Super Admin — toggle admin panel access (PATCH).
  /// Body: `{ "canLoginAdminPanel": bool }`.
  static String superadminAdminPanelAccess(String id) =>
      '/api/v1/superadmin/admins/$id/panel-access';

  // ── Pooja Kit Products ────────────────────────────────────────
  /// POST — create a new Pooja Kit product (multipart/form-data).
  static const String createProduct = '/api/v1/products/create-product';
  /// GET — list products (public).
  static const String products = '/api/v1/products';
  /// GET — list all products including inactive (super-admin).
  static const String allProducts = '/api/v1/products/all';
  static const String featuredProducts = '/api/v1/products/featured';
  static String product(String id) => '/api/v1/products/$id';
  /// PATCH — update product fields (multipart/form-data; same fields as create).
  static String updateProduct(String id) => '/api/v1/products/$id';
  /// DELETE — remove a product.
  static String deleteProduct(String id) => '/api/v1/products/$id';
  /// PUT — super-admin review (APPROVED / REJECTED / QUEUED) with optional
  /// reason. Body: `{ status, reason? }`.
  static String reviewProduct(String id) => '/api/v1/products/review/$id';
  /// PATCH — flip lifecycle (`productStatus`: ACTIVE | INACTIVE).
  static String productStatus(String id) => '/api/v1/products/$id/status';

  // ── Warehouse inventory (admin) ─────────────────────────────
  /// GET — category master for dropdowns. Query: `activeOnly` (default true).
  static const String inventoryCategories = '/api/v1/inventory/categories';

  /// POST — upsert category master data (superadmin only).
  static const String inventoryCategoriesSeed =
      '/api/v1/inventory/categories';

  /// GET — paginated items. Query: `page`, `limit`, `search`, `category`,
  /// `status`, `lowStock`.
  static const String inventory = '/api/v1/inventory';

  static String inventoryItem(String id) => '/api/v1/inventory/$id';

  /// POST — adjust stock. Body: `{ delta, reason }`.
  static String inventoryAdjustStock(String id) =>
      '/api/v1/inventory/$id/adjust-stock';

  // ── Pooja Kit Orders (admin / super-admin) ────────────────────
  /// GET — paginated list of every order. Query: `page`, `limit`,
  /// `orderStatus`, `paymentStatus`, `user`, `search` (order # substring).
  static const String allOrders = '/api/v1/orders/all';

  /// GET — single order by Mongo `_id`.
  static String order(String id) => '/api/v1/orders/$id';

  /// PATCH — fulfilment status. Body: `{ status, note? }`.
  /// `SHIPPED` requires `tracking.trackingNumber` already set.
  static String orderStatus(String id) => '/api/v1/orders/$id/status';

  /// PATCH — payment fields. Body: `{ paymentStatus?, paymentMethod? }`.
  /// Use sparingly — Paystack verify normally sets PAID.
  static String orderPayment(String id) => '/api/v1/orders/$id/payment';

  /// PATCH — set tracking only.
  /// Body: `{ courier, trackingNumber, trackingUrl? }`.
  static String orderTracking(String id) => '/api/v1/orders/$id/tracking';

  /// POST — set tracking + mark `SHIPPED`. Triggers tracking email.
  /// Body: `{ courier, trackingNumber, trackingUrl?, note? }`.
  static String orderDispatch(String id) => '/api/v1/orders/$id/dispatch';

  /// POST — admin terminal cancel for paid / pre-ship orders.
  /// Body: `{ reason? }`. Not allowed once SHIPPED / DELIVERED / FULFILLED.
  static String orderCancelPaid(String id) => '/api/v1/orders/$id/cancel-paid';

  // ── Pooja Kit replacement requests (admin) ─────────────────────
  /// GET — paginated replacement inbox. Query: `page`, `limit`, `status`.
  static const String adminReplacements = '/api/v1/admin/replacements';

  /// GET — single replacement request with populated `order` / `replacementOrder`.
  static String orderReplacementRequest(String id) =>
      '/api/v1/admin/replacements/$id';

  /// POST — approve. Body: `{ adminNote? }`.
  static String approveReplacementRequest(String id) =>
      '/api/v1/admin/replacements/$id/approve';

  /// POST — reject. Body: `{ adminNote? }`.
  static String rejectReplacementRequest(String id) =>
      '/api/v1/admin/replacements/$id/reject';

  /// Legacy combined requests inbox (cancel / refund / replacement).
  static const String orderRequests = '/api/v1/orders/requests';
  // ── Orders (user flow) ────────────────────────────────────────
  /// POST — place an order (from explicit items or cart).
  /// Body: `{ items: [{ productId, quantity }], shippingAddress, notes? }`.
  static const String createOrder = '/api/v1/orders';
  /// POST — initialize a Paystack transaction for a specific order.
  static String initializeOrderPayment(String id) =>
      '/api/v1/orders/$id/payments/paystack/initialize';
  /// POST — manually verify a Paystack transaction for an order.
  static String verifyOrderPayment(String id) =>
      '/api/v1/orders/$id/payments/paystack/verify';
  /// GET — paginated history of the signed-in user's orders.
  static const String myOrders = '/api/v1/orders/my';


  // ── Donations (user flow) ─────────────────────────────────────
  /// GET — list approved + visible donations for users.
  static const String donations = '/api/v1/donations';

  /// POST — initiate a Paystack payment for the given donation.
  /// Body: `{ amount, currency?, note?, callbackUrl? }`.
  static String donate(String id) => '/api/v1/donations/$id/donate';

  /// GET — idempotent verification by Paystack reference.
  static String verifyPayment(String reference) =>
      '/api/v1/payments/verify/$reference';

  /// GET — paginated history of the signed-in user's contributions.
  /// Query: `page`, `limit`, `paymentStatus`.
  static const String myContributions = '/api/v1/donations/contributions/my';

  /// GET — admin / super-admin: paginated list of contributions across
  /// all donors. Query: `page`, `limit`, `paymentStatus` (optional).
  static const String allContributions = '/api/v1/donations/contributions/all';

  // ── Firebase Cloud Messaging (device token registry) ─────────
  /// POST — register an FCM token for the signed-in user (idempotent,
  /// server `$addToSet`s into `user.fcmTokens`).
  /// Body: `{ token, platform: "android" | "ios" | "web", deviceId? }`.
  static const String fcmRegister = '/api/v1/fcm/register';

  /// DELETE — remove a previously-registered FCM token.
  /// Body: `{ token }`.
  static const String fcmUnregister = '/api/v1/fcm/unregister';

  /// GET — sanity check; returns `{ count: N }` for the signed-in user.
  static const String fcmMe = '/api/v1/fcm/me';

  // ── Notifications (admin / super-admin) ───────────────────────
  /// POST — send immediately OR schedule with `scheduledAt`. Body matches
  /// the `SendNotificationRequest` shape.
  static const String notificationsSend = '/api/v1/notifications/send';

  /// GET — paginated history of admin broadcasts.
  /// Query: `page`, `limit`, `status`, `audience`.
  static const String notifications = '/api/v1/notifications';

  /// GET — single notification by id.
  static String notification(String id) => '/api/v1/notifications/$id';

  /// POST — cancel a `SCHEDULED` broadcast before its send time.
  static String cancelNotification(String id) =>
      '/api/v1/notifications/$id/cancel';
}

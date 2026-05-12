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
  /// GET — list products. Assumed to return `{ data: [ProductModel] }` or
  /// `{ products: [...] }`. The data source normalises both shapes.
  static const String allProducts = '/api/v1/products/all';
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
}

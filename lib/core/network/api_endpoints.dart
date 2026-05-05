class ApiEndpoints {
  static const String authLogin = '/api/v1/auth/login';
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
}

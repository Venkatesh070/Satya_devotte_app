class ApiEndpoints {
  static const String authLogin = '/api/v1/auth/login';
  static const String authLogout = '/api/v1/auth/logout';
  static const String authRefresh = '/api/v1/auth/refresh';
  static const String profile = '/api/v1/auth/profile';
  // ── Poojas ────────────────────────────────────────────────
  static const String poojas = '/api/v1/poojas';
  static const String createPooja = '/api/v1/poojas/create-pooja';
  static String pooja(String id) => '/api/v1/poojas/$id';
  static String updatePooja(String id) => '/api/v1/poojas/$id';
  static String deletePooja(String id) => '/api/v1/poojas/$id';
  // Approve = PATCH {id} with status:Published | Reject = PATCH {id} with status:Rejected
}

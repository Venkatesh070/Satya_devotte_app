class AdminNotificationItem {
  const AdminNotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.read,
    required this.createdAt,
    this.data,
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final bool read;
  final DateTime createdAt;

  String? get orderId => _dataString('orderId');
  String? get orderNumber => _dataString('orderNumber');
  String? get contributionId => _dataString('contributionId');
  String? get contributionNumber => _dataString('contributionNumber');
  String? get requestId => _dataString('requestId');
  String? get requestNumber => _dataString('requestNumber');
  String? get paymentReference =>
      _dataString('paymentReference') ??
      _dataString('payfastReference') ??
      _dataString('paystackReference');

  String? _dataString(String key) {
    final v = data?[key];
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  factory AdminNotificationItem.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    Map<String, dynamic>? dataMap;
    if (rawData is Map<String, dynamic>) {
      dataMap = rawData;
    } else if (rawData is Map) {
      dataMap = Map<String, dynamic>.from(rawData);
    }

    final createdRaw = json['createdAt'] ?? json['created_at'];
    DateTime createdAt = DateTime.now().toUtc();
    if (createdRaw is String && createdRaw.isNotEmpty) {
      createdAt = DateTime.tryParse(createdRaw)?.toUtc() ?? createdAt;
    }

    return AdminNotificationItem(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      type: (json['type'] ?? dataMap?['type'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      data: dataMap,
      read: json['read'] == true,
      createdAt: createdAt,
    );
  }

  AdminNotificationItem copyWith({bool? read}) {
    return AdminNotificationItem(
      id: id,
      type: type,
      title: title,
      body: body,
      data: data,
      read: read ?? this.read,
      createdAt: createdAt,
    );
  }
}

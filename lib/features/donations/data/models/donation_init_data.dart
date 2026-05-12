// Response payload of POST /api/v1/donations/:id/donate.
//
// The backend may return either `authorization_url` (Paystack-native) or
// the camelCase `authorizationUrl` — `fromJson` accepts both.
class DonationInitData {
  const DonationInitData({
    required this.reference,
    required this.authorizationUrl,
    required this.amount,
    required this.currency,
    required this.donationId,
    required this.donationTitle,
    required this.contributionId,
    required this.contributionNumber,
    this.accessCode,
    this.publicKey,
  });

  final String reference;
  final String authorizationUrl;
  final num amount;
  final String currency;
  final String donationId;
  final String donationTitle;
  final String contributionId;
  final String contributionNumber;
  final String? accessCode;
  final String? publicKey;

  static String _str(dynamic v) => (v ?? '').toString().trim();

  factory DonationInitData.fromJson(Map<String, dynamic> raw) {
    // Some backends wrap the payload inside `data` or `payment` — peel one
    // layer if so, but accept a flat shape too.
    final root = (raw['data'] is Map<String, dynamic>)
        ? raw['data'] as Map<String, dynamic>
        : raw;

    final donation = root['donation'];
    final donationMap = donation is Map<String, dynamic> ? donation : const {};

    return DonationInitData(
      reference: _str(root['reference']),
      authorizationUrl: _str(
        root['authorizationUrl'] ?? root['authorization_url'],
      ),
      amount: (root['amount'] is num)
          ? root['amount'] as num
          : num.tryParse(_str(root['amount'])) ?? 0,
      currency: _str(root['currency']).isEmpty
          ? 'ZAR'
          : _str(root['currency']),
      donationId: _str(donationMap['_id'] ?? donationMap['id']),
      donationTitle: _str(donationMap['title'] ?? donationMap['name']),
      contributionId: _str(root['contributionId']),
      contributionNumber: _str(root['contributionNumber']),
      accessCode: () {
        final s = _str(root['accessCode']);
        return s.isEmpty ? null : s;
      }(),
      publicKey: () {
        final s = _str(root['publicKey']);
        return s.isEmpty ? null : s;
      }(),
    );
  }
}

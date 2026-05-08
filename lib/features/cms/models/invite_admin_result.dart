/// Response from POST /api/v1/superadmin/admins (invite new admin).
class InviteAdminResult {
  const InviteAdminResult({
    required this.emailDelivered,
    this.passwordResetLink,
  });

  final bool emailDelivered;
  final String? passwordResetLink;
}

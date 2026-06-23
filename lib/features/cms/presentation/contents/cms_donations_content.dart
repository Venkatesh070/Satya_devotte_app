// lib/features/cms/presentation/contents/cms_donations_content.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/core/services/media_upload_service.dart';
import 'package:satya_devotte_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:satya_devotte_app/features/cms/models/donation_model.dart';
import 'package:satya_devotte_app/features/cms/presentation/controllers/cms_contributions_controller.dart';
import 'package:satya_devotte_app/features/cms/presentation/controllers/donation_controller.dart';
import 'package:satya_devotte_app/features/cms/presentation/pages/cms_shell_page.dart';
import 'package:satya_devotte_app/features/cms/presentation/widgets/cms_shared_widgets.dart';
import 'package:satya_devotte_app/features/cms/presentation/widgets/cms_upload_box.dart';
import 'package:satya_devotte_app/features/donations/data/models/donation_contribution.dart';

Widget _cmsClickable({
  required VoidCallback onTap,
  required Widget child,
  HitTestBehavior behavior = HitTestBehavior.deferToChild,
}) {
  return MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: onTap,
      behavior: behavior,
      child: child,
    ),
  );
}

Widget _cmsClickableInk({
  required VoidCallback? onTap,
  required Widget child,
  BorderRadius? borderRadius,
}) {
  return MouseRegion(
    cursor: onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
    child: InkWell(
      onTap: onTap,
      borderRadius: borderRadius,
      child: child,
    ),
  );
}

const _cmsButtonClickCursor = WidgetStatePropertyAll<MouseCursor>(
  SystemMouseCursors.click,
);

class CmsDonationsContent extends StatefulWidget {
  const CmsDonationsContent({super.key});

  @override
  State<CmsDonationsContent> createState() => _CmsDonationsContentState();
}

class _CmsDonationsContentState extends State<CmsDonationsContent> {
  late final DonationController _ctrl;
  bool _showForm = false;
  DonationModel? _editing;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<DonationController>();
    // Trigger an initial fetch on first open so users don't have to
    // manually press the reload icon to see the API content.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _ctrl.loadDonations();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showForm) {
      return _DonationForm(
        donation: _editing,
        ctrl: _ctrl,
        onCancel: () => setState(() {
          _showForm = false;
          _editing = null;
        }),
        onSaved: () {
          _ctrl.loadDonations();
          setState(() {
            _showForm = false;
            _editing = null;
          });
        },
      );
    }
    return _DonationList(
      ctrl: _ctrl,
      onAdd: () => setState(() {
        _editing = null;
        _showForm = true;
      }),
      onEdit: (d) => setState(() {
        _editing = d;
        _showForm = true;
      }),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// DONATION LIST
// ════════════════════════════════════════════════════════════════
class _DonationList extends StatelessWidget {
  const _DonationList({
    required this.ctrl,
    required this.onAdd,
    required this.onEdit,
  });
  final DonationController ctrl;
  final VoidCallback onAdd;
  final ValueChanged<DonationModel> onEdit;

  static const _filters = ['All', 'Approved', 'Pending', 'Queued', 'Rejected'];

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width >= 768;

    return Column(
      children: [
        // ── SuperAdmin banner ─────────────────────────────────────
        Obx(() {
          if (!Get.find<AuthController>().isSuperAdmin) {
            return const SizedBox.shrink();
          }
          return Container(
            margin: EdgeInsets.fromLTRB(
              isWeb ? 24 : 16,
              12,
              isWeb ? 24 : 16,
              0,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFE082)),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  color: Color(0xFFF9A825),
                  size: 15,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Super Admin — Seeing all donations. Pending donations show Approve & Reject buttons.',
                    style: TextStyle(
                      color: Color(0xFF5D4037),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),

        // ── Toolbar ──────────────────────────────────────────────
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isWeb ? 24 : 16,
            vertical: 14,
          ),
          color: CmsColors.white,
          child: Row(
            children: [
              Expanded(
                child: CmsSearchBar(
                  hint: 'Search donations...',
                  onChanged: (_) {},
                ),
              ),
              const SizedBox(width: 12),
              Obx(
                () => ctrl.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: CmsColors.orange,
                        ),
                      )
                    : _cmsClickable(
                        onTap: ctrl.loadDonations,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: CmsColors.bg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: CmsColors.border),
                          ),
                          child: const Icon(
                            Icons.refresh,
                            size: 18,
                            color: CmsColors.textSecond,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              CmsPrimaryButton(
                label: isWeb ? 'Add Donation' : 'Add',
                icon: Icons.add,
                onTap: onAdd,
              ),
            ],
          ),
        ),

        // ── Filter tabs ───────────────────────────────────────────
        Container(
          color: CmsColors.white,
          padding: EdgeInsets.only(left: isWeb ? 24 : 16, bottom: 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Obx(
              () => Row(
                children: _filters.map((f) {
                  final isSel = ctrl.filter == f;
                  return _cmsClickable(
                    onTap: () => ctrl.setFilter(f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSel ? CmsColors.orange : CmsColors.bg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSel ? CmsColors.orange : CmsColors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            f,
                            style: TextStyle(
                              color: isSel
                                  ? Colors.white
                                  : CmsColors.textSecond,
                              fontSize: 12,
                              fontWeight: isSel
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                          if (f == 'Pending' && ctrl.pendingCount > 0) ...[
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? Colors.white.withOpacity(0.3)
                                    : CmsColors.orange,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${ctrl.pendingCount}',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                          if (f == 'Queued' && ctrl.queuedCount > 0) ...[
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? Colors.white.withOpacity(0.3)
                                    : CmsColors.orange,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${ctrl.queuedCount}',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),

        const Divider(height: 1, color: CmsColors.border),

        // ── Content ───────────────────────────────────────────────
        Expanded(
          child: Obx(() {
            if (ctrl.isLoading) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: CmsColors.orange),
                    SizedBox(height: 14),
                    Text(
                      'Loading donations...',
                      style: TextStyle(
                        color: CmsColors.textSecond,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }

            if (ctrl.error != null && ctrl.donations.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 36,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      ctrl.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: CmsColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CmsPrimaryButton(
                      label: 'Retry',
                      icon: Icons.refresh,
                      onTap: ctrl.loadDonations,
                    ),
                  ],
                ),
              );
            }

            final list = ctrl.filteredDonations;

            if (list.isEmpty) {
              return CmsEmptyState(
                icon: Icons.volunteer_activism_outlined,
                title: ctrl.filter == 'All'
                    ? 'No Donations Yet'
                    : 'No ${ctrl.filter} Donations',
                subtitle: 'Create a donation campaign to get started',
                actionLabel: ctrl.filter == 'All' ? 'Add Donation' : null,
                onAction: ctrl.filter == 'All' ? onAdd : null,
              );
            }

            return RefreshIndicator(
              color: CmsColors.orange,
              onRefresh: ctrl.loadDonations,
              child: isWeb
                  ? _WebGrid(donations: list, ctrl: ctrl, onEdit: onEdit)
                  : _MobileList(donations: list, ctrl: ctrl, onEdit: onEdit),
            );
          }),
        ),
      ],
    );
  }
}

// ── Web: 2-column grid ────────────────────────────────────────────
class _WebGrid extends StatelessWidget {
  const _WebGrid({
    required this.donations,
    required this.ctrl,
    required this.onEdit,
  });
  final List<DonationModel> donations;
  final DonationController ctrl;
  final ValueChanged<DonationModel> onEdit;

  @override
  Widget build(BuildContext context) => GridView.builder(
    padding: const EdgeInsets.all(24),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.6,
    ),
    itemCount: donations.length,
    itemBuilder: (ctx, i) => _DonationCard(
      donation: donations[i],
      onEdit: () => onEdit(donations[i]),
      onDelete: () => _deleteConfirm(ctx, donations[i], ctrl),
      onApprove: () => _approveDialog(ctx, donations[i], ctrl),
      onQueue: () => ctrl.queueDonation(donations[i].id),
      onReject: () => _rejectDialog(ctx, donations[i], ctrl),
    ),
  );
}

// ── Mobile: list ─────────────────────────────────────────────────
class _MobileList extends StatelessWidget {
  const _MobileList({
    required this.donations,
    required this.ctrl,
    required this.onEdit,
  });
  final List<DonationModel> donations;
  final DonationController ctrl;
  final ValueChanged<DonationModel> onEdit;

  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.all(16),
    itemCount: donations.length,
    separatorBuilder: (_, __) => const SizedBox(height: 12),
    itemBuilder: (ctx, i) => _DonationCard(
      donation: donations[i],
      onEdit: () => onEdit(donations[i]),
      onDelete: () => _deleteConfirm(ctx, donations[i], ctrl),
      onApprove: () => _approveDialog(ctx, donations[i], ctrl),
      onQueue: () => ctrl.queueDonation(donations[i].id),
      onReject: () => _rejectDialog(ctx, donations[i], ctrl),
    ),
  );
}

// ── Shared dialog helpers ─────────────────────────────────────────
void _deleteConfirm(
  BuildContext ctx,
  DonationModel d,
  DonationController ctrl,
) async {
  final ok = await showCmsDeleteDialog(ctx, itemName: d.title);
  if (ok == true) await ctrl.deleteDonation(d.id);
}

void _approveDialog(
  BuildContext ctx,
  DonationModel d,
  DonationController ctrl,
) {
  showDialog<void>(
    context: ctx,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: const Text(
        'Approve Donation',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green.withOpacity(0.2)),
            ),
            child: Text(
              d.title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: CmsColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'This will publish the donation to all users.',
            style: TextStyle(color: CmsColors.textSecond, fontSize: 13),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          style: TextButton.styleFrom().copyWith(
            mouseCursor: _cmsButtonClickCursor,
          ),
          child: const Text(
            'Cancel',
            style: TextStyle(color: CmsColors.textSecond),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () async {
            Navigator.pop(ctx);
            await ctrl.approveDonation(d.id);
          },
          icon: const Icon(Icons.check, size: 16),
          label: const Text('Approve & Publish'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ).copyWith(mouseCursor: _cmsButtonClickCursor),
        ),
      ],
    ),
  );
}

void _rejectDialog(BuildContext ctx, DonationModel d, DonationController ctrl) {
  final reasonCtrl = TextEditingController();
  showDialog<void>(
    context: ctx,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: const Text(
        'Reject Donation',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.withOpacity(0.2)),
            ),
            child: Text(
              d.title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: CmsColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Reason *',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: CmsColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: reasonCtrl,
            maxLines: 3,
            autofocus: true,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'e.g. Missing details...',
              hintStyle: const TextStyle(
                color: Color(0xFFAAAAAA),
                fontSize: 12,
              ),
              filled: true,
              fillColor: CmsColors.bg,
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: CmsColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.red),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          style: TextButton.styleFrom().copyWith(
            mouseCursor: _cmsButtonClickCursor,
          ),
          child: const Text(
            'Cancel',
            style: TextStyle(color: CmsColors.textSecond),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () async {
            if (reasonCtrl.text.trim().isEmpty) {
              Get.snackbar(
                'Required',
                'Please enter a reason',
                snackPosition: SnackPosition.TOP,
                backgroundColor: CmsColors.orange,
                colorText: Colors.white,
                margin: const EdgeInsets.all(12),
              );
              return;
            }
            Navigator.pop(ctx);
            await ctrl.rejectDonation(d.id, reasonCtrl.text.trim());
          },
          icon: const Icon(Icons.close, size: 16),
          label: const Text('Reject'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ).copyWith(mouseCursor: _cmsButtonClickCursor),
        ),
      ],
    ),
  );
}

// ════════════════════════════════════════════════════════════════
// DONATION CARD
// ════════════════════════════════════════════════════════════════
class _DonationCard extends StatelessWidget {
  const _DonationCard({
    required this.donation,
    required this.onEdit,
    required this.onDelete,
    required this.onApprove,
    required this.onQueue,
    required this.onReject,
  });
  final DonationModel donation;
  final VoidCallback onEdit, onDelete, onApprove, onQueue, onReject;

  Color get _statusColor {
    switch (donation.status) {
      case 'Approved':
        return Colors.green;
      case 'Pending':
        return CmsColors.orange;
      case 'Queued':
        return CmsColors.orangeDark;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final isSuperAdmin = auth.isSuperAdmin;
    final isCreatorSuperAdmin = isSuperAdmin && donation.createdBy == auth.currentUserId;
    final canEdit =
        isSuperAdmin ||
        (donation.createdBy != null &&
            donation.createdBy == auth.currentUserId);

    return Container(
      decoration: BoxDecoration(
        color: CmsColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _statusColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image header
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: // In _DonationCard image section, replace the Image.network with:
            donation.imageUrl != null && donation.imageUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(14),
                    ),
                    child: Image.network(
                      donation.imageUrl!,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, error, __) {
                        debugPrint(
                          'Image load error: $error for ${donation.imageUrl}',
                        );
                        return _PlaceholderImg();
                      },
                    ),
                  )
                : _PlaceholderImg(),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + status
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        donation.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: CmsColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        donation.status,
                        style: TextStyle(
                          fontSize: 10,
                          color: _statusColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (donation.description.isNotEmpty)
                  Text(
                    donation.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: CmsColors.textSecond,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 8),

                // Actions
                Row(
                  children: [
                    if (canEdit) ...[
                      _SmBtn(Icons.edit_outlined, Colors.blue, onEdit),
                      const SizedBox(width: 6),
                      _SmBtn(Icons.delete_outline, Colors.red, onDelete),
                    ],
                    const Spacer(),
                    if (isSuperAdmin &&
                        (donation.status == 'Pending' ||
                            donation.status == 'Queued')) ...[
                      if (isCreatorSuperAdmin) ...[
                        if (donation.status == 'Pending')
                          _TextBtn('Queued', Colors.orange, onQueue),
                        if (donation.status == 'Pending')
                          const SizedBox(width: 6),
                        _TextBtn('Publish Now', Colors.green, onApprove),
                      ] else ...[
                        _TextBtn('Reject', Colors.red, onReject),
                        const SizedBox(width: 6),
                        _TextBtn('Approve', Colors.green, onApprove),
                      ],
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderImg extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    height: 120,
    width: double.infinity,
    color: CmsColors.orange.withOpacity(0.08),
    child: const Icon(
      Icons.volunteer_activism_outlined,
      size: 40,
      color: CmsColors.orange,
    ),
  );
}

class _SmBtn extends StatelessWidget {
  const _SmBtn(this.icon, this.color, this.onTap);
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _cmsClickable(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Icon(icon, size: 14, color: color),
    ),
  );
}

class _TextBtn extends StatelessWidget {
  const _TextBtn(this.label, this.color, this.onTap);
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _cmsClickable(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

// ════════════════════════════════════════════════════════════════
// ADD / EDIT DONATION FORM
// ════════════════════════════════════════════════════════════════
class _DonationForm extends StatefulWidget {
  const _DonationForm({
    this.donation,
    required this.ctrl,
    required this.onCancel,
    required this.onSaved,
  });
  final DonationModel? donation;
  final DonationController ctrl;
  final VoidCallback onCancel, onSaved;

  @override
  State<_DonationForm> createState() => _DonationFormState();
}

class _DonationFormState extends State<_DonationForm> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  PickedFile? _pickedImage; // newly picked file bytes
  bool get _isEdit => widget.donation != null;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.donation?.title ?? '');
    _descCtrl = TextEditingController(text: widget.donation?.description ?? '');
    // _pickedImage starts null; existing imageUrl shown via initialUrl
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) {
      Get.snackbar(
        'Required',
        'Title is required',
        snackPosition: SnackPosition.TOP,
        backgroundColor: CmsColors.orangeDark,
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
      );
      return;
    }
    bool ok;
    if (_isEdit) {
      ok = await widget.ctrl.updateDonation(
        widget.donation!.id,
        _titleCtrl.text.trim(),
        _descCtrl.text.trim(),
        image: _pickedImage,
      );
    } else {
      ok = await widget.ctrl.createDonation(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        image: _pickedImage,
      );
    }
    if (ok) widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width >= 768;
    return Obx(() {
      final loading = widget.ctrl.isSubmitting;
      return SingleChildScrollView(
        padding: EdgeInsets.all(isWeb ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _cmsClickable(
                  onTap: widget.onCancel,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: CmsColors.bg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: CmsColors.border),
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      size: 18,
                      color: CmsColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _isEdit ? 'Edit Donation' : 'Add Donation',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: CmsColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            CmsFormCard(
              title: 'Donation Details',
              children: [
                CmsFormField(
                  label: 'Title *',
                  hint: 'e.g. Food Relief Fund',
                  controller: _titleCtrl,
                ),
                const SizedBox(height: 12),
                CmsFormField(
                  label: 'Description',
                  hint: 'Describe the donation campaign...',
                  controller: _descCtrl,
                  maxLines: 4,
                ),
                const SizedBox(height: 12),
                CmsUploadBox(
                  label: 'Donation Image *',
                  icon: Icons.image_outlined,
                  accept: 'JPG, PNG up to 5MB',
                  mediaType: PickMediaType.image,
                  initialUrl: widget.donation?.imageUrl,
                  onPicked: (f) => setState(() => _pickedImage = f),
                  onRemoved: () => setState(() => _pickedImage = null),
                ),
              ],
            ),

            if (_isEdit) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFFE082)),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Color(0xFFF9A825),
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Updating will send this donation back for re-approval.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF5D4037),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: loading ? null : widget.onCancel,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: CmsColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ).copyWith(mouseCursor: _cmsButtonClickCursor),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: CmsColors.textSecond),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CmsColors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ).copyWith(mouseCursor: _cmsButtonClickCursor),
                    child: loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _isEdit ? 'Save Changes' : 'Submit for Review',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

// ════════════════════════════════════════════════════════════════
// ALL DONATIONS — super-admin overview of every contribution.
// Source: GET /api/v1/donations/contributions/all
// ════════════════════════════════════════════════════════════════
class CmsDonationsAllContent extends StatefulWidget {
  const CmsDonationsAllContent({super.key});

  @override
  State<CmsDonationsAllContent> createState() => _CmsDonationsAllContentState();
}

class _CmsDonationsAllContentState extends State<CmsDonationsAllContent> {
  late final CmsContributionsController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<CmsContributionsController>();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 768;
    return Column(
      children: [
        
        const Divider(height: 1, color: CmsColors.border),
        _AllDonationsFilterBar(ctrl: _ctrl),
        Expanded(
          child: Obx(() {
            if (_ctrl.isLoading && _ctrl.items.isEmpty) {
              return const _ContributionsLoading();
            }
            if (_ctrl.error != null && _ctrl.items.isEmpty) {
              return _ContributionsError(
                message: _ctrl.error!,
                onRetry: _ctrl.refreshContributions,
              );
            }
            if (_ctrl.isEmpty) {
              return const CmsEmptyState(
                icon: Icons.volunteer_activism_outlined,
                title: 'No contributions yet',
                subtitle:
                    'Once devotees start donating their contributions '
                    'will appear here.',
              );
            }
            return RefreshIndicator(
              color: CmsColors.orange,
              onRefresh: _ctrl.refreshContributions,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 24 : 12,
                  vertical: 14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ContributionsTable(items: _ctrl.items),
                    const SizedBox(height: 14),
                    _ContributionsPaginationBar(ctrl: _ctrl),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ─── Filter chips ────────────────────────────────────────────────
class _AllDonationsFilterBar extends StatelessWidget {
  const _AllDonationsFilterBar({required this.ctrl});
  final CmsContributionsController ctrl;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 768;
    return Container(
      color: CmsColors.white,
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 24 : 12,
        vertical: 10,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Obx(() {
          final active = ctrl.filter;
          return Row(
            children: [
              for (final f in CmsContributionsController.filters) ...[
                _FilterChip(
                  label: _filterLabel(f),
                  isActive: f == active,
                  onTap: () => ctrl.setFilter(f),
                ),
                const SizedBox(width: 8),
              ],
              const SizedBox(width: 6),
              IconButton(
                tooltip: 'Reload',
                onPressed: ctrl.isLoading ? null : ctrl.refreshContributions,
                style: IconButton.styleFrom().copyWith(
                  mouseCursor: _cmsButtonClickCursor,
                ),
                icon: ctrl.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: CmsColors.orange,
                        ),
                      )
                    : const Icon(
                        Icons.refresh,
                        size: 18,
                        color: CmsColors.textSecond,
                      ),
              ),
            ],
          );
        }),
      ),
    );
  }

  String _filterLabel(String key) {
    switch (key) {
      case 'ALL':
        return 'All';
      case 'PAID':
        return 'Paid';
      case 'PENDING':
        return 'Pending';
      case 'FAILED':
        return 'Failed';
      default:
        return key;
    }
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _cmsClickableInk(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? CmsColors.orange : CmsColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? CmsColors.orange : CmsColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isActive ? Colors.white : CmsColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

// ─── Table ────────────────────────────────────────────────────────
class _ContributionsTable extends StatelessWidget {
  const _ContributionsTable({required this.items});
  final List<DonationContribution> items;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    if (isWide) return _WideTable(items: items);
    return _NarrowList(items: items);
  }
}

/// Human-readable contribution number, fully visible (selectable, no
/// ellipsis).
class _ContributionIdsBlock extends StatelessWidget {
  const _ContributionIdsBlock({
    required this.contribution,
    this.dense = false,
  });

  final DonationContribution contribution;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final num = contribution.contributionNumber.trim();
    if (num.isEmpty) {
      return Text(
        '—',
        style: TextStyle(
          fontSize: dense ? 12 : 12.5,
          color: CmsColors.textPrimary,
        ),
      );
    }
    return SelectableText(
      num,
      style: TextStyle(
        fontSize: dense ? 12 : 12.5,
        fontWeight: FontWeight.w700,
        color: CmsColors.textPrimary,
      ),
    );
  }
}

/// Two-line date / time renderer using the existing `formattedDate`
/// which is `"d MMM yyyy, h:mm a"`. We just split on the comma so the
/// date sits on line 1 and the time on line 2.
class _DateCell extends StatelessWidget {
  const _DateCell({required this.formattedDate, this.dense = false});

  final String formattedDate;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final s = formattedDate.trim();
    if (s.isEmpty) {
      return Text(
        '—',
        style: TextStyle(
          fontSize: dense ? 12 : 12.5,
          color: CmsColors.textPrimary,
        ),
      );
    }
    final parts = s.split(', ');
    final datePart = parts.first;
    final timePart = parts.length > 1 ? parts.sublist(1).join(', ') : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          datePart,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: dense ? 12 : 12.5,
            fontWeight: FontWeight.w600,
            color: CmsColors.textPrimary,
          ),
        ),
        if (timePart.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            timePart,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: dense ? 11 : 11.5,
              color: CmsColors.textSecond,
            ),
          ),
        ],
      ],
    );
  }
}

/// Payment reference — fully visible with copy action.
class _ReferenceCell extends StatelessWidget {
  const _ReferenceCell({
    required this.reference,
    this.dense = false,
  });

  final String? reference;
  final bool dense;

  Future<void> _copy(BuildContext context) async {
    final text = reference?.trim() ?? '';
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    showCmsSnackbar(
      title: 'Copied',
      message: 'Reference ID copied to clipboard',
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = reference?.trim() ?? '';
    if (text.isEmpty) {
      return Text(
        '—',
        style: TextStyle(
          fontSize: dense ? 12 : 12.5,
          color: CmsColors.textSecond,
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SelectableText(
            text,
            style: TextStyle(
              fontSize: dense ? 12 : 12,
              fontFamily: 'monospace',
              color: CmsColors.textSecond,
              height: 1.35,
            ),
          ),
        ),
        const SizedBox(width: 6),
        _cmsClickable(
          onTap: () => _copy(context),
          child: Tooltip(
            message: 'Copy reference ID',
            child: Container(
              padding: EdgeInsets.all(dense ? 5 : 6),
              decoration: BoxDecoration(
                color: CmsColors.bg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: CmsColors.border),
              ),
              child: Icon(
                Icons.copy_outlined,
                size: dense ? 14 : 15,
                color: CmsColors.textSecond,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Wide layout: flex Table that always fits the parent width ──
class _WideTable extends StatelessWidget {
  const _WideTable({required this.items});
  final List<DonationContribution> items;

  // Proportional column widths — 7 columns.
  static const _columnWidths = <int, TableColumnWidth>{
    0: FlexColumnWidth(2.2), // Contribution ID
    1: FlexColumnWidth(2.6), // Donor
    2: FlexColumnWidth(1.6), // Amount
    3: FlexColumnWidth(1.4), // Status
    4: FlexColumnWidth(2.0), // Date (two lines)
    5: FlexColumnWidth(2.2), // Note
    6: FlexColumnWidth(2.4), // Reference (payment ref)
  };

  static const _headerStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: CmsColors.textPrimary,
    letterSpacing: 0.2,
  );

  static const _cellStyle = TextStyle(
    fontSize: 12.5,
    color: CmsColors.textPrimary,
  );

  Widget _pad(Widget child) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CmsColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CmsColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Table(
          columnWidths: _columnWidths,
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              decoration: BoxDecoration(color: CmsColors.bg.withOpacity(.6)),
              children: [
                _pad(const Text('Contribution ID', style: _headerStyle)),
                _pad(const Text('Contributor', style: _headerStyle)),
                _pad(const Text(
                  'Amount',
                  style: _headerStyle,
                  textAlign: TextAlign.right,
                )),
                _pad(const Text('Status', style: _headerStyle)),
                _pad(const Text('Date', style: _headerStyle)),
                _pad(const Text('Note', style: _headerStyle)),
                _pad(const Text('Reference', style: _headerStyle)),
              ],
            ),
            for (final c in items)
              TableRow(
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: CmsColors.border, width: 0.6),
                  ),
                ),
                children: [
                  _pad(_ContributionIdsBlock(contribution: c)),
                  _pad(_DonorCell(contribution: c)),
                  _pad(Text(
                    c.formattedAmount,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: _cellStyle.copyWith(fontWeight: FontWeight.w700),
                  )),
                  _pad(Align(
                    alignment: Alignment.centerLeft,
                    child: _StatusPill(status: c.status),
                  )),
                  _pad(_DateCell(formattedDate: c.formattedDate)),
                  _pad(Text(
                    (c.note == null || c.note!.trim().isEmpty)
                        ? '—'
                        : c.note!.trim(),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: _cellStyle.copyWith(
                      color: (c.note == null || c.note!.trim().isEmpty)
                          ? CmsColors.textSecond
                          : CmsColors.textPrimary,
                    ),
                  )),
                  _pad(_ReferenceCell(reference: c.reference)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Narrow layout: card list, one card per contribution ────────
class _NarrowList extends StatelessWidget {
  const _NarrowList({required this.items});
  final List<DonationContribution> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < items.length; i++) ...[
          _ContributionCard(contribution: items[i]),
          if (i != items.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _ContributionCard extends StatelessWidget {
  const _ContributionCard({required this.contribution});
  final DonationContribution contribution;

  @override
  Widget build(BuildContext context) {
    final c = contribution;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CmsColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CmsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  c.donationTitle.isEmpty ? '—' : c.donationTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: CmsColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _StatusPill(status: c.status),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _DonorCell(contribution: c),
              ),
              const SizedBox(width: 10),
              Text(
                c.formattedAmount,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: CmsColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: CmsColors.border),
          const SizedBox(height: 10),
          _ContributionIdsBlock(contribution: c, dense: true),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                width: 96,
                child: Text(
                  'Date',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: CmsColors.textSecond,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: _DateCell(
                  formattedDate: c.formattedDate,
                  dense: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _MetaRow(
            label: 'Note',
            value: (c.note == null || c.note!.trim().isEmpty)
                ? '—'
                : c.note!.trim(),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                width: 96,
                child: Text(
                  'Reference',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: CmsColors.textSecond,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: _ReferenceCell(
                  reference: c.reference,
                  dense: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.label,
    required this.value,
  });
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              color: CmsColors.textSecond,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? '—' : value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: CmsColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _DonorCell extends StatelessWidget {
  const _DonorCell({required this.contribution});
  final DonationContribution contribution;

  @override
  Widget build(BuildContext context) {
    final name = contribution.donorName?.trim();
    final email = contribution.donorEmail?.trim();
    final hasName = name != null && name.isNotEmpty;
    final hasEmail = email != null && email.isNotEmpty;
    if (!hasName && !hasEmail) {
      return const Text('—');
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 220),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasName)
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          if (hasEmail)
            Text(
              email,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.5,
                color: CmsColors.textSecond,
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final ContributionStatus status;

  @override
  Widget build(BuildContext context) {
    late final Color bg;
    late final Color fg;
    late final String label;
    switch (status) {
      case ContributionStatus.paid:
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF2E7D32);
        label = 'Paid';
        break;
      case ContributionStatus.pending:
        bg = const Color(0xFFFFF3E0);
        fg = const Color(0xFFEF6C00);
        label = 'Pending';
        break;
      case ContributionStatus.failed:
        bg = const Color(0xFFFFEBEE);
        fg = const Color(0xFFC62828);
        label = 'Failed';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ─── Pagination ───────────────────────────────────────────────────
class _ContributionsPaginationBar extends StatelessWidget {
  const _ContributionsPaginationBar({required this.ctrl});
  final CmsContributionsController ctrl;

  static const _pageSizes = [10, 20, 50, 100];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isWide = MediaQuery.of(context).size.width >= 768;
      final page = ctrl.page;
      final size = ctrl.limit;
      final tp = ctrl.totalPages;
      final totalRows = ctrl.total;
      final start = totalRows == 0 ? 0 : (page - 1) * size + 1;
      final end = (page * size).clamp(0, totalRows);

      final left = <Widget>[
        Text(
          'Showing $start–$end of $totalRows',
          style: const TextStyle(
            fontSize: 12,
            color: CmsColors.textSecond,
          ),
        ),
        const SizedBox(width: 18),
        const Text(
          'Rows per page:',
          style: TextStyle(fontSize: 12, color: CmsColors.textSecond),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: CmsColors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: CmsColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _pageSizes.contains(size) ? size : _pageSizes[1],
              isDense: true,
              style: const TextStyle(
                fontSize: 12,
                color: CmsColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              items: _pageSizes
                  .map((s) =>
                      DropdownMenuItem(value: s, child: Text('$s')))
                  .toList(),
              onChanged: (v) {
                if (v != null) ctrl.setLimit(v);
              },
            ),
          ),
        ),
      ];

      final pager = <Widget>[
        _PagerBtnMini(
          icon: Icons.chevron_left,
          enabled: page > 1,
          onTap: ctrl.prevPage,
        ),
        for (final n in _pageRange(page, tp))
          n == -1
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    '…',
                    style: TextStyle(color: CmsColors.textSecond),
                  ),
                )
              : _PageNumberBtnMini(
                  number: n,
                  isActive: n == page,
                  onTap: () => ctrl.goToPage(n),
                ),
        _PagerBtnMini(
          icon: Icons.chevron_right,
          enabled: page < tp,
          onTap: ctrl.nextPage,
        ),
      ];

      if (isWide) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: CmsColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CmsColors.border),
          ),
          child: Row(
            children: [
              ...left,
              const Spacer(),
              ...pager.map(
                (w) => Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: w,
                ),
              ),
            ],
          ),
        );
      }
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: CmsColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CmsColors.border),
        ),
        child: Column(
          children: [
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 6,
              children: left,
            ),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              runSpacing: 4,
              children: pager,
            ),
          ],
        ),
      );
    });
  }

  List<int> _pageRange(int current, int total) {
    if (total <= 7) return [for (int i = 1; i <= total; i++) i];
    final out = <int>[1];
    final start = (current - 1).clamp(2, total - 4);
    final end = (current + 1).clamp(5, total - 1);
    if (start > 2) out.add(-1);
    for (int i = start; i <= end; i++) {
      out.add(i);
    }
    if (end < total - 1) out.add(-1);
    out.add(total);
    return out;
  }
}

class _PagerBtnMini extends StatelessWidget {
  const _PagerBtnMini({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          onTap: enabled ? onTap : null,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: enabled ? CmsColors.bg : CmsColors.bg.withOpacity(0.6),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: CmsColors.border),
            ),
            child: Icon(
              icon,
              size: 18,
              color: enabled
                  ? CmsColors.textPrimary
                  : CmsColors.textSecond.withOpacity(0.5),
            ),
          ),
        ),
      );
}

class _PageNumberBtnMini extends StatelessWidget {
  const _PageNumberBtnMini({
    required this.number,
    required this.isActive,
    required this.onTap,
  });
  final int number;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _cmsClickable(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? CmsColors.orange : CmsColors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? CmsColors.orange : CmsColors.border,
            ),
          ),
          child: Text(
            '$number',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isActive ? Colors.white : CmsColors.textPrimary,
            ),
          ),
        ),
      );
}

// ─── Loading + Error states ──────────────────────────────────────
class _ContributionsLoading extends StatelessWidget {
  const _ContributionsLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: CircularProgressIndicator(color: CmsColors.orange),
      ),
    );
  }
}

class _ContributionsError extends StatelessWidget {
  const _ContributionsError({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: CmsColors.red,
              size: 36,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: CmsColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Try again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: CmsColors.orange,
                foregroundColor: Colors.white,
              ).copyWith(mouseCursor: _cmsButtonClickCursor),
            ),
          ],
        ),
      ),
    );
  }
}

class _DonationsHeader extends StatelessWidget {
  const _DonationsHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width >= 768;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isWeb ? 24 : 16,
        vertical: 14,
      ),
      color: CmsColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: CmsColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: CmsColors.textSecond,
            ),
          ),
        ],
      ),
    );
  }
}

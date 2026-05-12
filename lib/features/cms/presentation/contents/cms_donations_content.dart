// lib/features/cms/presentation/contents/cms_donations_content.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/core/services/media_upload_service.dart';
import 'package:satya_devotte_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:satya_devotte_app/features/cms/models/donation_model.dart';
import 'package:satya_devotte_app/features/cms/presentation/controllers/donation_controller.dart';
import 'package:satya_devotte_app/features/cms/presentation/pages/cms_shell_page.dart';
import 'package:satya_devotte_app/features/cms/presentation/widgets/cms_shared_widgets.dart';
import 'package:satya_devotte_app/features/cms/presentation/widgets/cms_upload_box.dart';

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
                    : GestureDetector(
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
                  return GestureDetector(
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
          ),
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
          ),
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
  Widget build(BuildContext context) => GestureDetector(
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
  Widget build(BuildContext context) => GestureDetector(
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
                GestureDetector(
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
                    ),
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
                    ),
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
// ALL DONATIONS  (super-admin overview – placeholder for now)
// ════════════════════════════════════════════════════════════════
class CmsDonationsAllContent extends StatelessWidget {
  const CmsDonationsAllContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _DonationsHeader(
          title: 'All Donations',
          subtitle:
              'Browse every donation campaign created across the platform.',
        ),
        Divider(height: 1, color: CmsColors.border),
        Expanded(
          child: CmsEmptyState(
            icon: Icons.volunteer_activism_outlined,
            title: 'No Donations Yet',
            subtitle:
                'Once admins start publishing donation campaigns they will '
                'appear here as a unified, searchable list.',
          ),
        ),
      ],
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

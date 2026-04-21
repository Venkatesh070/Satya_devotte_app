// lib/features/cms/presentation/contents/cms_shlokas_content.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/features/cms/models/sloka_model.dart';
import 'package:satya_devotte_app/features/cms/presentation/controllers/sloka_controller.dart';
import 'package:satya_devotte_app/features/cms/presentation/pages/cms_shell_page.dart';
import 'package:satya_devotte_app/features/cms/presentation/widgets/cms_shared_widgets.dart';

class CmsShlokaContent extends StatefulWidget {
  const CmsShlokaContent({super.key});

  @override
  State<CmsShlokaContent> createState() => _CmsShlokaContentState();
}

class _CmsShlokaContentState extends State<CmsShlokaContent> {
  late final SlokaController _ctrl;
  bool _showForm = false;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<SlokaController>();
    // FIX: Always reload data when this screen is opened.
    // SlokaController is now registered with lazyPut(fenix:true) so its
    // onInit fires here (first open) with a valid auth token. Calling
    // loadAll() on every visit ensures slokas are always up-to-date.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ctrl.loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showForm) {
      return _SlokaForm(
        ctrl: _ctrl,
        onCancel: () => setState(() => _showForm = false),
        onSaved: () => setState(() => _showForm = false),
      );
    }

    final isWeb = MediaQuery.of(context).size.width >= 768;

    return Column(
      children: [
        // ── Header ────────────────────────────────────────────────
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isWeb ? 24 : 16,
            vertical: 14,
          ),
          color: CmsColors.white,
          child: Row(
            children: [
              Expanded(child: _DateSelector(ctrl: _ctrl)),
              const SizedBox(width: 12),
              Obx(
                () => _ctrl.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: CmsColors.orange,
                        ),
                      )
                    : GestureDetector(
                        onTap: _ctrl.loadAll,
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
                label: isWeb ? 'Set Daily Sloka' : 'Set',
                icon: Icons.edit_note,
                onTap: () => setState(() => _showForm = true),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: CmsColors.border),

        Expanded(
          child: Obx(() {
            if (_ctrl.isLoading) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: CmsColors.orange),
                    SizedBox(height: 14),
                    Text(
                      'Loading...',
                      style: TextStyle(
                        color: CmsColors.textSecond,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }
            return isWeb
                ? _WebLayout(
                    ctrl: _ctrl,
                    onEdit: () => setState(() => _showForm = true),
                  )
                : _MobileLayout(
                    ctrl: _ctrl,
                    onEdit: () => setState(() => _showForm = true),
                  );
          }),
        ),
      ],
    );
  }
}

// ── Date selector ─────────────────────────────────────────────────
class _DateSelector extends StatelessWidget {
  const _DateSelector({required this.ctrl});
  final SlokaController ctrl;

  @override
  Widget build(BuildContext context) => Obx(() {
    final d = ctrl.selectedDate;
    final display = SlokaModel.formatDate(d); // DD-MM-YYYY

    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: d,
          firstDate: DateTime(2020),
          lastDate: DateTime(2040),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.light(
                primary: CmsColors.orange,
                onPrimary: Colors.white,
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) ctrl.setDate(picked);
      },
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: CmsColors.bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: CmsColors.border),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: CmsColors.orange,
            ),
            const SizedBox(width: 8),
            Text(
              display,
              style: const TextStyle(
                fontSize: 13,
                color: CmsColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            const Icon(Icons.arrow_drop_down, color: CmsColors.textSecond),
          ],
        ),
      ),
    );
  });
}

// ── Layouts ───────────────────────────────────────────────────────
class _WebLayout extends StatelessWidget {
  const _WebLayout({required this.ctrl, required this.onEdit});
  final SlokaController ctrl;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: _SlokaCard(ctrl: ctrl, onEdit: onEdit),
        ),
        const SizedBox(width: 20),
        Expanded(flex: 2, child: _RecentList(ctrl: ctrl)),
      ],
    ),
  );
}

class _MobileLayout extends StatelessWidget {
  const _MobileLayout({required this.ctrl, required this.onEdit});
  final SlokaController ctrl;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        _SlokaCard(ctrl: ctrl, onEdit: onEdit),
        const SizedBox(height: 16),
        _RecentList(ctrl: ctrl),
      ],
    ),
  );
}

// ── Selected date sloka card ──────────────────────────────────────
class _SlokaCard extends StatelessWidget {
  const _SlokaCard({required this.ctrl, required this.onEdit});
  final SlokaController ctrl;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => Obx(() {
    final sloka = ctrl.todaySloka;
    final now = DateTime.now();
    final isToday =
        ctrl.selectedDate.day == now.day &&
        ctrl.selectedDate.month == now.month &&
        ctrl.selectedDate.year == now.year;
    final title = isToday ? "Today's Sloka" : 'Sloka — ${ctrl.selectedDateStr}';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CmsColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CmsColors.orange.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CmsColors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.menu_book,
                  color: CmsColors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: CmsColors.textPrimary,
                  ),
                ),
              ),
              if (sloka != null)
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: CmsColors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: CmsColors.orange.withOpacity(0.3),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 14,
                          color: CmsColors.orange,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Edit',
                          style: TextStyle(
                            color: CmsColors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(color: CmsColors.border),
          const SizedBox(height: 16),

          if (sloka == null) ...[
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.auto_stories_outlined,
                    size: 48,
                    color: CmsColors.orange.withOpacity(0.3),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No sloka set for this date',
                    style: TextStyle(fontSize: 14, color: CmsColors.textSecond),
                  ),
                  const SizedBox(height: 16),
                  CmsPrimaryButton(
                    label: 'Set Sloka for this Date',
                    icon: Icons.add,
                    onTap: onEdit,
                  ),
                ],
              ),
            ),
          ] else ...[
            // Sloka text
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CmsColors.orange.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: CmsColors.orange.withOpacity(0.15)),
              ),
              child: Text(
                sloka.sloka,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.8,
                  fontWeight: FontWeight.w500,
                  color: CmsColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 14),

            // Author
            if (sloka.author.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 14,
                    color: CmsColors.textSecond,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    sloka.author,
                    style: const TextStyle(
                      fontSize: 13,
                      color: CmsColors.textSecond,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  });
}

// ── Recent slokas list ────────────────────────────────────────────
class _RecentList extends StatelessWidget {
  const _RecentList({required this.ctrl});
  final SlokaController ctrl;

  @override
  Widget build(BuildContext context) => Obx(
    () => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CmsColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Slokas',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: CmsColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (ctrl.slokas.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No slokas yet',
                  style: TextStyle(color: CmsColors.textSecond, fontSize: 13),
                ),
              ),
            )
          else
            ...ctrl.slokas
                .take(10)
                .map(
                  (s) => GestureDetector(
                    onTap: () {
                      try {
                        final p = s.date.split('-');
                        // Handle both DD-MM-YYYY and YYYY-MM-DD
                        final d = p[0].length == 4
                            ? DateTime(
                                int.parse(p[0]),
                                int.parse(p[1]),
                                int.parse(p[2]),
                              )
                            : DateTime(
                                int.parse(p[2]),
                                int.parse(p[1]),
                                int.parse(p[0]),
                              );
                        ctrl.setDate(d);
                      } catch (_) {}
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: s.date == ctrl.selectedDateStr
                            ? CmsColors.orange.withOpacity(0.08)
                            : CmsColors.bg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: s.date == ctrl.selectedDateStr
                              ? CmsColors.orange.withOpacity(0.4)
                              : CmsColors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: s.date == ctrl.selectedDateStr
                                  ? CmsColors.orange
                                  : CmsColors.border,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.displayDate,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: s.date == ctrl.selectedDateStr
                                        ? CmsColors.orange
                                        : CmsColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  s.sloka,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: CmsColors.textSecond,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (s.isToday)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: CmsColors.orange,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Today',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
        ],
      ),
    ),
  );
}

// ════════════════════════════════════════════════════════════════
// SLOKA FORM — only 3 fields: sloka, author, date
// ════════════════════════════════════════════════════════════════
class _SlokaForm extends StatefulWidget {
  const _SlokaForm({
    required this.ctrl,
    required this.onCancel,
    required this.onSaved,
  });
  final SlokaController ctrl;
  final VoidCallback onCancel;
  final VoidCallback onSaved;

  @override
  State<_SlokaForm> createState() => _SlokaFormState();
}

class _SlokaFormState extends State<_SlokaForm> {
  late final TextEditingController _slokaCtrl;
  late final TextEditingController _authorCtrl;

  @override
  void initState() {
    super.initState();
    final existing = widget.ctrl.todaySloka;
    _slokaCtrl = TextEditingController(text: existing?.sloka ?? '');
    _authorCtrl = TextEditingController(text: existing?.author ?? '');
  }

  @override
  void dispose() {
    _slokaCtrl.dispose();
    _authorCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_slokaCtrl.text.trim().isEmpty) {
      Get.snackbar(
        'Required',
        'Sloka text is required',
        snackPosition: SnackPosition.TOP,
        backgroundColor: CmsColors.orangeDark,
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
      );
      return;
    }
    final ok = await widget.ctrl.saveSloka(
      sloka: _slokaCtrl.text.trim(),
      author: _authorCtrl.text.trim(),
    );
    if (ok) widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width >= 768;

    return Obx(() {
      final loading = widget.ctrl.isSubmitting;
      final existing = widget.ctrl.todaySloka;

      return SingleChildScrollView(
        padding: EdgeInsets.all(isWeb ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back + title
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
                  existing != null
                      ? 'Edit Sloka — ${widget.ctrl.selectedDateStr}'
                      : 'Set Sloka — ${widget.ctrl.selectedDateStr}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: CmsColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            CmsFormCard(
              title: 'Daily Sloka',
              children: [
                // date display (read-only — set from date picker on main screen)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CmsColors.orange.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: CmsColors.orange.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 15,
                        color: CmsColors.orange,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Date: ${widget.ctrl.selectedDateStr}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: CmsColors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                CmsFormField(
                  label: 'Sloka *',
                  hint: 'e.g. कर्मण्येवाधिकारस्ते मा फलेषु कदाचन...',
                  controller: _slokaCtrl,
                  maxLines: 4,
                ),
                const SizedBox(height: 12),

                CmsFormField(
                  label: 'Author / Source',
                  hint: 'e.g. Bhagavad Gita 2.47',
                  controller: _authorCtrl,
                ),
              ],
            ),
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
                            existing != null ? 'Update Sloka' : 'Save Sloka',
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

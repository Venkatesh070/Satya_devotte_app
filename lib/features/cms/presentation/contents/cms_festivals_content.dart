import 'package:flutter/material.dart';
import 'package:satya_devotte_app/features/cms/presentation/pages/cms_shell_page.dart';
import 'package:satya_devotte_app/features/cms/presentation/widgets/cms_shared_widgets.dart';

class CmsFestivalsContent extends StatefulWidget {
  const CmsFestivalsContent({super.key});

  @override
  State<CmsFestivalsContent> createState() => _CmsFestivalsContentState();
}

class _CmsFestivalsContentState extends State<CmsFestivalsContent> {
  bool _showAddForm = false;
  int _selectedMonth = DateTime.now().month;

  final _festivals = const [
    _FestivalData(
      'Maha Shivratri',
      '26 Feb 2026',
      'High',
      'Published',
      'Lord Shiva',
    ),
    _FestivalData('Holi', '14 Mar 2026', 'High', 'Published', 'Lord Krishna'),
    _FestivalData('Ram Navami', '06 Apr 2026', 'Medium', 'Draft', 'Lord Rama'),
    _FestivalData(
      'Ganesh Chaturthi',
      '27 Aug 2026',
      'High',
      'Published',
      'Lord Ganesha',
    ),
    _FestivalData(
      'Navratri',
      '02 Oct 2026',
      'High',
      'Published',
      'Goddess Durga',
    ),
    _FestivalData(
      'Diwali',
      '20 Oct 2026',
      'High',
      'Published',
      'Goddess Lakshmi',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (_showAddForm) {
      return _FestivalForm(
        onCancel: () => setState(() => _showAddForm = false),
        onSave: () => setState(() => _showAddForm = false),
      );
    }
    return _FestivalList(
      festivals: _festivals,
      selectedMonth: _selectedMonth,
      onMonthChanged: (m) => setState(() => _selectedMonth = m),
      onAdd: () => setState(() => _showAddForm = true),
    );
  }
}

// ── Festival List ─────────────────────────────────────────────────
class _FestivalList extends StatelessWidget {
  const _FestivalList({
    required this.festivals,
    required this.selectedMonth,
    required this.onMonthChanged,
    required this.onAdd,
  });
  final List<_FestivalData> festivals;
  final int selectedMonth;
  final ValueChanged<int> onMonthChanged;
  final VoidCallback onAdd;

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width >= 768;
    return Column(
      children: [
        // Header
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isWeb ? 24 : 16,
            vertical: 14,
          ),
          color: CmsColors.white,
          child: Row(
            children: [
              Expanded(child: CmsSearchBar(hint: 'Search festivals...')),
              const SizedBox(width: 12),
              CmsPrimaryButton(
                label: isWeb ? 'Add Festival' : 'Add',
                icon: Icons.add,
                onTap: onAdd,
              ),
            ],
          ),
        ),
        // Month picker
        Container(
          color: CmsColors.white,
          padding: EdgeInsets.only(
            left: isWeb ? 24 : 16,
            right: 16,
            bottom: 14,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Month',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: CmsColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(12, (i) {
                    final isSelected = selectedMonth == i + 1;
                    return GestureDetector(
                      onTap: () => onMonthChanged(i + 1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? CmsColors.orange : CmsColors.bg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? CmsColors.orange
                                : CmsColors.border,
                          ),
                        ),
                        child: Text(
                          _months[i],
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : CmsColors.textSecond,
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: CmsColors.border),
        // List
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.all(isWeb ? 24 : 16),
            itemCount: festivals.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _FestivalCard(data: festivals[i]),
          ),
        ),
      ],
    );
  }
}

class _FestivalCard extends StatelessWidget {
  const _FestivalCard({required this.data});
  final _FestivalData data;

  Color get _importanceColor {
    switch (data.importance) {
      case 'High':
        return const Color(0xFFE53935);
      case 'Medium':
        return CmsColors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CmsColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          // Date badge
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: CmsColors.orange.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  data.date.split(' ')[0],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: CmsColors.orange,
                  ),
                ),
                Text(
                  data.date.split(' ')[1].replaceAll(',', ''),
                  style: const TextStyle(
                    fontSize: 9,
                    color: CmsColors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: CmsColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data.deity,
                  style: const TextStyle(
                    fontSize: 12,
                    color: CmsColors.textSecond,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    CmsStatusBadge(status: data.status),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _importanceColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        data.importance,
                        style: TextStyle(
                          fontSize: 10,
                          color: _importanceColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              CmsActionIcon(
                icon: Icons.edit_outlined,
                color: Colors.blue,
                onTap: () {},
              ),
              const SizedBox(height: 6),
              CmsActionIcon(
                icon: Icons.delete_outline,
                color: Colors.red,
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Add Festival Form ─────────────────────────────────────────────
class _FestivalForm extends StatelessWidget {
  const _FestivalForm({required this.onCancel, required this.onSave});
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width >= 768;
    return SingleChildScrollView(
      padding: EdgeInsets.all(isWeb ? 24 : 16),
      child: Column(
        children: [
          CmsFormCard(
            title: 'Festival Details',
            children: [
              CmsFormField(
                label: 'Festival Name *',
                hint: 'e.g. Maha Shivratri',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CmsFormField(
                      label: 'Date *',
                      hint: 'e.g. 26 Feb 2026',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CmsDropdownField(
                      label: 'Importance',
                      items: const ['High', 'Medium', 'Low'],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CmsFormField(
                label: 'Description',
                hint: 'Enter festival description...',
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              CmsFormField(
                label: 'Associated Pooja (Optional)',
                hint: 'e.g. Shiva Abhishekam',
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
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
                  onPressed: onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CmsColors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Update Festival',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FestivalData {
  const _FestivalData(
    this.name,
    this.date,
    this.importance,
    this.status,
    this.deity,
  );
  final String name;
  final String date;
  final String importance;
  final String status;
  final String deity;
}

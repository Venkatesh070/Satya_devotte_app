import 'package:flutter/material.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';

/// Figma calendar design tokens.
abstract final class CalendarUi {
  static const Color background = Color(0xFFFFF5E6);
  static const Color headerOrange = Color(0xFFED5A00);
  static const Color headerOrangeDark = Color(0xFFD64A00);
  static const Color tabSelected = Color(0xFF1F4CB7);
  static const Color textPrimary = Color(0xFF3B1E08);
  static const Color textMuted = Color(0xFF8A6B4A);
  static const Color cardBorder = Color(0xFFF3E5D0);
  static const Color text = Color(0xFF1C1917);
  static const Color subText = Color(0xFF78716C);

  /// List area below filter tabs — room to scroll clear of tabs and bottom nav.
  static EdgeInsets listScrollPadding(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 96);
  }
}

/// Figma action buttons — blue (#183EA4) → orange (#E35600), left to right.
const kCalendarActionGradient = [
  Color(0xFF183EA4),
  Color(0xFFE35600),
];

const kAppHeaderImage = 'assets/images/pooja/pujaHeaderImg.png';

/// Temple header background — matches home, profile, and donations.
class CalendarAppHeader extends StatelessWidget {
  const CalendarAppHeader({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(kAppHeaderImage),
          fit: BoxFit.fill,
          alignment: Alignment.topCenter,
        ),
      ),
      child: child,
    );
  }
}

class CalendarFilterTabs extends StatelessWidget {
  const CalendarFilterTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: List.generate(labels.length, (i) {
          final selected = i == selectedIndex;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < labels.length - 1 ? 8 : 0),
              child: Material(
                color: selected ? CalendarUi.tabSelected : Colors.white,
                borderRadius: BorderRadius.circular(999),
                child: InkWell(
                  onTap: () => onSelected(i),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      border: selected
                          ? null
                          : Border.all(color: CalendarUi.cardBorder),
                    ),
                    child: Text(
                      labels[i],
                      style: AppTypography.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : CalendarUi.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

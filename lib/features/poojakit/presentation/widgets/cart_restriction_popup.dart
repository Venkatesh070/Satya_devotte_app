import 'package:flutter/material.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';

/// Popup dialog to inform user about cart category restriction
/// (Cannot mix Ayurvedic products with Puja Kits & Sathya Books).
void showCartRestrictionPopup(
  BuildContext context, {
  String message =
      'You cannot add Ayurvedic products along with Sathya Books and Puja Kits.',
}) {
  showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: const Color(0x7F000000),
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topRight,
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 12, right: 12),
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
            decoration: BoxDecoration(
              color: const Color(0xFFFCF7EF),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Opps!',
                  style: AppTypography.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1D160E),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  style: AppTypography.inter(
                    fontSize: 13,
                    height: 1.45,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF78716C),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFFFCF7EF),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0x1A000000)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: Color(0xFF1C1C1C),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

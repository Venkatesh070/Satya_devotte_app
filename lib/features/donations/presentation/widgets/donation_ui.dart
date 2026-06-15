import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/donations/data/models/donation_contribution.dart';
import 'package:satya_devotte_app/shared/widgets/chakra_loading_indicator.dart';

/// Design tokens from Sathya Devotee Figma (profile + donations).
abstract final class DonationUi {
  static const Color background = Color(0xFFFFF5E6);
  static const Color profileBackground = Color(0xFFFFF5E6);
  static const Color headerOrange = Color(0xFFED5A00);
  static const Color headerOrangeDark = Color(0xFFD64A00);
  static const Color cardFill = Color(0XFFFCF7EF);
  static const Color cardBorder = Color(0xFFF3E5D0);
  static const Color textPrimary = Color(0xFF4A1C00);
  static const Color textMuted = Color(0xFF875131);
  static const Color successGreen = Color(0xFF1F8A4C);
  static const Color amountBlue = Color(0xFF1F4CB7);
  static const Color chevron = Color(0xFFEAD9BC);
  static const Color sectionLabel = Color(0xFF8A6B4A);
  static const Color text = Color(0xFF1C1917);

  static String formatCurrency(num value) {
    return NumberFormat.currency(
      symbol: 'R ',
      decimalDigits: value.truncateToDouble() == value ? 0 : 2,
    ).format(value);
  }
}

/// Cream app bar — "Donations", "Record of Donations", etc.
class DonationSimpleAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const DonationSimpleAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.trailing,
  });

  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: DonationUi.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: onBack != null
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              color: DonationUi.textPrimary,
              onPressed: onBack,
            )
          : null,
      title: Text(
        title,
        style: AppTypography.lora(
          fontSize: 24,
          fontWeight: FontWeight.w500,
          color: DonationUi.textPrimary,
        ),
      ),
      centerTitle: false,
      actions: trailing != null ? [trailing!] : null,
    );
  }
}

/// Profile tab header — temple image + overlapping avatar (Figma screen 1).
class ProfileCurvedHeader extends StatelessWidget {
  const ProfileCurvedHeader({
    super.key,
    required this.name,
    required this.initials,
    this.onViewProfile,
  });

  final String name;
  final String initials;
  final VoidCallback? onViewProfile;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            height: 180,
            width: double.infinity,
            child: Image.asset(
              'assets/images/appHeaderImg.png',
              fit: BoxFit.fill,
              alignment: Alignment.topCenter,
            ),
          ),
          Positioned(
            bottom: -56,
            child: Column(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: AppTypography.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: DonationUi.headerOrange,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  name,
                  style: AppTypography.lora(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: DonationUi.textPrimary,
                  ),
                ),
                if (onViewProfile != null) ...[
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: onViewProfile,
                    child: Text(
                      'View Profile',
                      style: AppTypography.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: DonationUi.headerOrange,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Grouped menu block — "My Profile" / "Settings" sections in one card.
class ProfileSectionCard extends StatelessWidget {
  const ProfileSectionCard({
    super.key,
    required this.title,
    required this.items,
  });

  final String title;
  final List<ProfileMenuRowData> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: AppTypography.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: DonationUi.sectionLabel,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: DonationUi.cardFill,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: DonationUi.cardBorder),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                ProfileMenuRow(data: items[i]),
                if (i < items.length - 1)
                  const Divider(
                    height: 1,
                    indent: 52,
                    endIndent: 16,
                    color: DonationUi.cardBorder,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class ProfileMenuRowData {
  const ProfileMenuRowData({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;
}

class ProfileMenuRow extends StatelessWidget {
  const ProfileMenuRow({super.key, required this.data});

  final ProfileMenuRowData data;

  @override
  Widget build(BuildContext context) {
    final color = data.isDestructive
        ? const Color(0xFFB10F1A)
        : DonationUi.textPrimary;
    final iconColor = data.isDestructive
        ? const Color(0xFFB10F1A)
        : DonationUi.headerOrange;

    return InkWell(
      onTap: data.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(data.icon, size: 22, color: iconColor),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                data.label,
                style: AppTypography.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: data.isDestructive
                  ? const Color(0xFFE8C4C4)
                  : DonationUi.chevron,
            ),
          ],
        ),
      ),
    );
  }
}

/// History pill — Figma: white capsule, thin border, clock + "History".
class DonationHistoryChip extends StatelessWidget {
  const DonationHistoryChip({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: DonationUi.cardBorder, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF183EA4), Color(0xFFE35600)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                blendMode: BlendMode.srcIn,
                child: Icon(
                  Icons.history_rounded,
                  size: 18,
                  color: Colors.white, // must be opaque white
                ),
              ),
              const SizedBox(width: 6),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF183EA4), Color(0xFFE35600)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                blendMode: BlendMode.srcIn,
                child: Text(
                  'History',
                  style: AppTypography.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors
                        .white, // must be white/opaque for ShaderMask to work
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// @deprecated Figma Donations screen uses [DonationSummaryCard] only.
class DonationsOverviewCard extends StatelessWidget {
  const DonationsOverviewCard({
    super.key,
    required this.totalLabel,
    required this.totalValue,
    required this.onDonate,
  });

  final String totalLabel;
  final String totalValue;
  final VoidCallback onDonate;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DonationUi.cardFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DonationUi.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            totalLabel,
            style: AppTypography.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: DonationUi.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            totalValue,
            style: AppTypography.lora(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: DonationUi.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          DonationOrangeButton(label: 'Contribute Now', onPressed: onDonate),
        ],
      ),
    );
  }
}

class DonationOrangeButton extends StatelessWidget {
  const DonationOrangeButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: DonationUi.headerOrange,
          foregroundColor: Colors.white,
          disabledBackgroundColor: DonationUi.headerOrange.withOpacity(0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const ChakraLoadingIndicator(size: 24, color: Colors.white)
            : Text(
                label,
                style: AppTypography.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}

/// Recent donation row — thumbnail, title, date, amount (Figma overview list).
class RecentDonationTile extends StatelessWidget {
  const RecentDonationTile({super.key, required this.contribution, this.onTap});

  final DonationContribution contribution;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFEADCC3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.volunteer_activism_outlined,
                color: Color(0xFF8C5A2A),
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contribution.donationTitle.isEmpty
                        ? 'General Donation'
                        : contribution.donationTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: DonationUi.textPrimary,
                    ),
                  ),
                  if (contribution.formattedDate.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      contribution.formattedDate,
                      style: AppTypography.inter(
                        fontSize: 12,
                        color: DonationUi.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Text(
              contribution.formattedAmount,
              style: AppTypography.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: DonationUi.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// History of donations row — Figma: purpose bold, date • time; amount + txn id.
class RecordDonationTile extends StatelessWidget {
  const RecordDonationTile({super.key, required this.contribution, this.onTap});

  final DonationContribution contribution;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final title = contribution.donationTitle.isEmpty
        ? 'General Donation'
        : contribution.donationTitle;
    final dateLine = contribution.formattedDateHistoryLine;
    final txnLine = contribution.displayTransactionLine;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Material(
        color: DonationUi.cardFill,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: DonationUi.cardFill,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: DonationUi.textPrimary,
                        ),
                      ),
                      if (dateLine.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          dateLine,
                          style: AppTypography.inter(
                            fontSize: 12,
                            height: 1.35,
                            color: DonationUi.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      contribution.formattedAmount,
                      style: AppTypography.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: DonationUi.textPrimary,
                      ),
                    ),
                    if (txnLine.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        txnLine,
                        textAlign: TextAlign.right,
                        style: AppTypography.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: DonationUi.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DonationSectionTitle extends StatelessWidget {
  const DonationSectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: AppTypography.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: DonationUi.textPrimary,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// @deprecated Use [DonationOrangeButton]. Kept as alias for gradual migration.
typedef DonationPrimaryButton = DonationOrangeButton;

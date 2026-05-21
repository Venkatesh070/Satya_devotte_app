import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/donations/data/models/donation.dart';
import 'package:satya_devotte_app/features/donations/presentation/widgets/donation_ui.dart';

/// Figma cause row — thumbnail, title, chevron only.
class DonationCard extends StatelessWidget {
  const DonationCard({super.key, required this.donation, required this.onTap});

  final Donation donation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DonationUi.cardFill,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: DonationUi.cardBorder),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: _Image(url: donation.imageUrl),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      donation.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.lora(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: DonationUi.text,
                        height: 1.25,
                      ),
                    ),
                    if (donation.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        donation.description.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.inter(
                          fontSize: 12,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                          color: Color(0XFF78716C),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: DonationUi.textMuted,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Image extends StatelessWidget {
  const _Image({required this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: const Color(0xFFEADCC3),
      child: const Center(
        child: Icon(
          Icons.volunteer_activism_outlined,
          color: Color(0xFF8C5A2A),
          size: 24,
        ),
      ),
    );
    if (url == null || url!.isEmpty) return placeholder;
    if (url!.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: url!,
        fit: BoxFit.cover,
        placeholder: (_, __) => placeholder,
        errorWidget: (_, __, ___) => placeholder,
      );
    }
    return Image.asset(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => placeholder,
    );
  }
}

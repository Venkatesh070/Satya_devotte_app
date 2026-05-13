import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/donations/data/models/donation.dart';

class DonationCard extends StatelessWidget {
  const DonationCard({
    super.key,
    required this.donation,
    required this.onTap,
    required this.onDonate,
  });

  final Donation donation;
  final VoidCallback onTap;
  final VoidCallback onDonate;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 110, // Fixed height for a neat horizontal layout
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEAE3D2)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            // Left: Image
            SizedBox(
              width: 100,
              height: double.infinity,
              child: _Image(url: donation.imageUrl),
            ),
            // Middle: Text Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      donation.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.lora(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (donation.description.isNotEmpty)
                      Text(
                        donation.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.inter(
                          fontSize: 12,
                          color: const Color(0xFF6B5841),
                          height: 1.3,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Right: Donate Button
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _DonateButton(onTap: onDonate),
            ),
          ],
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
          size: 24, // Smaller icon for horizontal card
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
    return Image.asset(url!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => placeholder);
  }
}

class _DonateButton extends StatelessWidget {
  const _DonateButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFB10F33),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minimumSize: const Size(80, 36),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        elevation: 0,
      ),
      child: const Text(
        'Donate',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );
  }
}

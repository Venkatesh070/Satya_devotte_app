import 'package:flutter/material.dart';

import 'package:satya_devotte_app/features/donations/data/models/donation.dart';
import 'package:satya_devotte_app/features/donations/presentation/pages/make_donation_screen.dart';

/// Opens the Figma "Make a Donation" bottom sheet.
class DonateAmountSheet {
  DonateAmountSheet._();

  static Future<void> show(
    BuildContext context, {
    required Donation donation,
  }) {
    return MakeDonationScreen.show(context, donation: donation);
  }
}

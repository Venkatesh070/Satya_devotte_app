import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:satya_devotte_app/core/services/external_donation_launcher.dart';
import 'package:satya_devotte_app/core/utils/toast_util.dart';
import 'package:satya_devotte_app/features/donations/data/models/donation.dart';
import 'package:satya_devotte_app/shared/widgets/leaving_app_dialog.dart';

/// Opens voluntary donations on the public Sathya website (Safari / Chrome).
///
/// There is no in-app donation checkout or payment WebView — App Store
/// Guideline 3.2.2(iv). The optional [donation] argument is accepted for
/// call-site compatibility but is not used; the website handles amount
/// selection and PayFast.
class MakeDonationScreen {
  MakeDonationScreen._();

  /// Displays the "You're leaving the Sathya app" confirmation dialog before
  /// opening the public donation page in Safari / Chrome.
  static Future<void> show(BuildContext context, {Donation? donation}) async {
    final targetUrl = ExternalDonationLauncher.buildDonationPageUrl();
    final confirmed = await LeavingAppDialog.show(
      context,
      targetUrl: targetUrl,
    );
    if (confirmed != true) return;

    final opened = await ExternalDonationLauncher.openDonationPage();
    if (!opened && context.mounted) {
      ToastUtil.showError(
        'Could not open the donation website. Please try again.',
        title: 'Donate',
      );
    }
  }

  /// Back-compat for call sites that used navigation.
  static Future<void> open({Donation? donation, BuildContext? context}) {
    final ctx = context ?? Get.context;
    if (ctx == null) {
      return ExternalDonationLauncher.openDonationPage().then((_) {});
    }
    return show(ctx, donation: donation);
  }
}

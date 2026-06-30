import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';

/// Login screen footer — version, tagline, Redin Consulting logo.
class LoginFooter extends StatelessWidget {
  const LoginFooter({super.key});

  static const _creamMuted = Color(0xFF78716C);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.data?.version ?? '1.0.0';
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/redin_logo.png',
              width: 116,
              height: 32,
              fit: BoxFit.contain,
            ),
          ],
        );
      },
    );
  }
}

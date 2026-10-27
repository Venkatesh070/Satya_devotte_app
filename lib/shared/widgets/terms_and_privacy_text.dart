import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:satya_devotte_app/core/utils/toast_util.dart';
import 'package:url_launcher/url_launcher.dart';

const String kPrivacyPolicyUrl = 'https://sathya-app-privacy.netlify.app/';
const String kTermsConditionsUrl =
    'https://sathya-terms-and-conditions.netlify.app/';

Future<void> launchPrivacyPolicy() async {
  final uri = Uri.parse(kPrivacyPolicyUrl);
  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched) {
    ToastUtil.showInfo('Could not open Privacy Policy link.');
  }
}

Future<void> launchTermsAndConditions() async {
  final uri = Uri.parse(kTermsConditionsUrl);
  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched) {
    ToastUtil.showInfo('Could not open Terms & Conditions link.');
  }
}

Future<void> launchPopiaCompliance() async {
  // POPIA compliance information is incorporated into the Sathya Privacy Policy.
  final uri = Uri.parse(kPrivacyPolicyUrl);
  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched) {
    ToastUtil.showInfo('Could not open POPIA Compliance link.');
  }
}

/// Reusable disclaimer text with clickable underlined links for
/// Terms & Conditions, Privacy Policy, and POPIA Compliance.
class TermsAndPrivacyPolicyText extends StatelessWidget {
  const TermsAndPrivacyPolicyText({
    super.key,
    this.textColor,
    this.linkColor,
    this.fontSize = 11.0,
    this.textAlign = TextAlign.center,
  });

  final Color? textColor;
  final Color? linkColor;
  final double fontSize;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final baseColor = textColor ?? const Color(0xFF57534E);
    final linkStyleColor = linkColor ?? baseColor;

    final baseStyle = TextStyle(
      color: baseColor,
      fontSize: fontSize,
      fontWeight: FontWeight.w400,
      height: 1.35,
    );

    final linkStyle = TextStyle(
      color: linkStyleColor,
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.underline,
      decorationColor: linkStyleColor,
      height: 1.35,
    );

    return RichText(
      textAlign: textAlign,
      text: TextSpan(
        style: baseStyle,
        children: [
          const TextSpan(text: 'By signing up you are accepting our '),
          TextSpan(
            text: 'terms and conditions',
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () => launchTermsAndConditions(),
          ),
          const TextSpan(text: ', '),
          TextSpan(
            text: 'privacy policy',
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () => launchPrivacyPolicy(),
          ),
          const TextSpan(text: ', and '),
          TextSpan(
            text: 'POPIA compliance',
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () => launchPopiaCompliance(),
          ),
          const TextSpan(text: '.'),
        ],
      ),
    );
  }
}

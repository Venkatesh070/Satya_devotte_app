import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:satya_devotte_app/core/utils/toast_util.dart';
import 'package:url_launcher/url_launcher.dart';

const String kPrivacyPolicyUrl = 'https://sathya-app-privacy.netlify.app/';
const String kTermsConditionsUrl =
    'https://sathya-terms-and-conditions.netlify.app/';

Future<void> _safeLaunchUrl(String url, String label) async {
  final uri = Uri.parse(url);
  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  } catch (e) {
    debugPrint('Could not open $label link ($url): $e');
    try {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    } catch (_) {
      ToastUtil.showInfo('Could not open $label link.');
    }
  }
}

Future<void> launchPrivacyPolicy() async {
  await _safeLaunchUrl(kPrivacyPolicyUrl, 'Privacy Policy');
}

Future<void> launchTermsAndConditions() async {
  await _safeLaunchUrl(kTermsConditionsUrl, 'Terms & Conditions');
}

Future<void> launchPopiaCompliance() async {
  // POPIA compliance information is incorporated into the Sathya Privacy Policy.
  await launchPrivacyPolicy();
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
    this.prefixWidget,
    this.onNonLinkTap,
  });

  final Color? textColor;
  final Color? linkColor;
  final double fontSize;
  final TextAlign textAlign;
  final Widget? prefixWidget;
  final VoidCallback? onNonLinkTap;

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

    final nonLinkRecognizer = onNonLinkTap != null
        ? (TapGestureRecognizer()..onTap = onNonLinkTap)
        : null;

    return RichText(
      textAlign: textAlign,
      text: TextSpan(
        style: baseStyle,
        children: [
          if (prefixWidget != null)
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: prefixWidget!,
            ),
          TextSpan(
            text: 'By signing up you are accepting our ',
            recognizer: nonLinkRecognizer,
          ),
          TextSpan(
            text: 'terms and conditions',
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () => launchTermsAndConditions(),
          ),
          TextSpan(
            text: ', ',
            recognizer: nonLinkRecognizer,
          ),
          TextSpan(
            text: 'privacy policy',
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () => launchPrivacyPolicy(),
          ),
          TextSpan(
            text: ' and ',
            recognizer: nonLinkRecognizer,
          ),
          TextSpan(
            text: 'POPIA compliance',
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () => launchPopiaCompliance(),
          ),
          TextSpan(
            text: '.',
            recognizer: nonLinkRecognizer,
          ),
        ],
      ),
    );
  }
}

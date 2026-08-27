import 'package:flutter/material.dart';

import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/core/utils/rich_text_util.dart';
import 'package:satya_devotte_app/features/cms/presentation/pages/cms_shell_page.dart';
import 'package:satya_devotte_app/shared/widgets/rich_text_display.dart';

enum StepRichTextVariant { wizard, detail, cms }

/// Renders puja step rich text, including optional Recite blocks.
class StepRichTextDisplay extends StatelessWidget {
  const StepRichTextDisplay(
    this.value, {
    super.key,
    this.variant = StepRichTextVariant.detail,
  });

  const StepRichTextDisplay.wizard(this.value, {super.key})
      : variant = StepRichTextVariant.wizard;

  const StepRichTextDisplay.detail(this.value, {super.key})
      : variant = StepRichTextVariant.detail;

  const StepRichTextDisplay.cms(this.value, {super.key})
      : variant = StepRichTextVariant.cms;

  final String? value;
  final StepRichTextVariant variant;

  @override
  Widget build(BuildContext context) {
    final v = value;
    if (v == null || v.trim().isEmpty) return const SizedBox.shrink();

    // Recite cards appear only when the CMS Recite button marked text
    // (`attributes.recite === true`). Never invent Recite from wording alone.
    if (!isDeltaJson(v) || !deltaHasRecite(v)) {
      if (variant == StepRichTextVariant.wizard ||
          variant == StepRichTextVariant.detail) {
        return _InstructionCard(deltaJson: v, variant: variant);
      }
      return RichTextDisplay(v, style: _instructionTextStyle(variant));
    }

    final segments = parseDeltaSegments(v).where((s) => !s.isEmpty).toList();
    if (segments.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < segments.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == segments.length - 1 ? 0 : 14),
            child: segments[i].isRecite
                ? _ReciteCard(
                    deltaJson: segments[i].deltaJson,
                    variant: variant,
                  )
                : _InstructionCard(
                    deltaJson: segments[i].deltaJson,
                    variant: variant,
                  ),
          ),
      ],
    );
  }

  static TextStyle _instructionTextStyle(StepRichTextVariant variant) {
    switch (variant) {
      case StepRichTextVariant.wizard:
        return AppTypography.inter(
          fontSize: 15,
          color: const Color(0xFFFCF7EF),
          height: 1.6,
        );
      case StepRichTextVariant.detail:
        return AppTypography.inter(
          fontSize: 13,
          height: 1.45,
          color: const Color(0xFF4A1C00),
        );
      case StepRichTextVariant.cms:
        return const TextStyle(
          fontSize: 13,
          height: 1.4,
          color: CmsColors.textPrimary,
        );
    }
  }
}

class _InstructionCard extends StatelessWidget {
  const _InstructionCard({required this.deltaJson, required this.variant});

  final String deltaJson;
  final StepRichTextVariant variant;

  @override
  Widget build(BuildContext context) {
    final textStyle = StepRichTextDisplay._instructionTextStyle(variant);
    if (variant == StepRichTextVariant.cms) {
      return RichTextDisplay(deltaJson, style: textStyle);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: variant == StepRichTextVariant.wizard
            ? const Color(0xFFFCF7EF).withOpacity(0.1)
            : const Color(0xFFFFF8F0),
        borderRadius: BorderRadius.circular(12),
        border: variant == StepRichTextVariant.detail
            ? Border.all(color: const Color(0xFFE8D5B7))
            : null,
      ),
      child: RichTextDisplay(deltaJson, style: textStyle),
    );
  }
}

class _ReciteCard extends StatelessWidget {
  const _ReciteCard({required this.deltaJson, required this.variant});

  final String deltaJson;
  final StepRichTextVariant variant;

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case StepRichTextVariant.wizard:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFB63A19).withValues(alpha: 0.48),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFFFD180).withValues(alpha: 0.16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Recite :',
                textAlign: TextAlign.center,
                style: AppTypography.lora(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFFFD180),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: RichTextDisplay(
                  deltaJson,
                  textAlign: TextAlign.center,
                  style: AppTypography.lora(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFFFD180),
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        );
      case StepRichTextVariant.detail:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFB63A19).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFB63A19).withValues(alpha: 0.25),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Recite :',
                textAlign: TextAlign.center,
                style: AppTypography.lora(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFB63A19),
                ),
              ),
              const SizedBox(height: 6),
              RichTextDisplay(
                deltaJson,
                textAlign: TextAlign.center,
                style: AppTypography.lora(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF6B2A0A),
                  height: 1.45,
                ),
              ),
            ],
          ),
        );
      case StepRichTextVariant.cms:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: CmsColors.orange.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: CmsColors.orange.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Recite :',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: CmsColors.orange,
                ),
              ),
              const SizedBox(height: 4),
              RichTextDisplay(
                deltaJson,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                  color: CmsColors.textPrimary,
                ),
              ),
            ],
          ),
        );
    }
  }
}

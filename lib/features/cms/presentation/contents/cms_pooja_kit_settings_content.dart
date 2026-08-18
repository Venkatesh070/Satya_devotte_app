// Pooja Kit → Ecommerce Settings (VAT number + percentage).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:satya_devotte_app/features/cms/data/models/ecommerce_settings_model.dart';
import 'package:satya_devotte_app/features/cms/presentation/controllers/ecommerce_settings_controller.dart';
import 'package:satya_devotte_app/features/cms/presentation/pages/cms_shell_page.dart';
import 'package:satya_devotte_app/features/cms/presentation/widgets/cms_shared_widgets.dart';

class CmsPoojaKitSettingsContent extends StatefulWidget {
  const CmsPoojaKitSettingsContent({super.key});

  @override
  State<CmsPoojaKitSettingsContent> createState() =>
      _CmsPoojaKitSettingsContentState();
}

class _CmsPoojaKitSettingsContentState extends State<CmsPoojaKitSettingsContent> {
  late final EcommerceSettingsController _ctrl;
  late final TextEditingController _vatNumberCtrl;
  late final TextEditingController _vatPercentCtrl;
  late final Worker _settingsWorker;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<EcommerceSettingsController>();
    _vatNumberCtrl = TextEditingController();
    _vatPercentCtrl = TextEditingController();
    _settingsWorker = ever<EcommerceSettings?>(
      _ctrl.settingsRx,
      (_) => _syncFieldsFromSettings(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ctrl.load(force: true);
      _syncFieldsFromSettings();
    });
  }

  void _syncFieldsFromSettings() {
    if (!mounted) return;
    final settings = _ctrl.settings;
    if (settings == null) return;
    _vatNumberCtrl.text = settings.vatNumber;
    final pct = settings.vatPercent;
    _vatPercentCtrl.text = pct == pct.roundToDouble()
        ? pct.toStringAsFixed(0)
        : pct.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _settingsWorker.dispose();
    _vatNumberCtrl.dispose();
    _vatPercentCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final pct = double.tryParse(_vatPercentCtrl.text.trim());
    if (pct == null) return;
    await _ctrl.saveSettings(
      vatNumber: _vatNumberCtrl.text.trim(),
      vatPercent: pct,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width >= 768;

    return Obx(() {
      if (_ctrl.isLoading && _ctrl.settings == null) {
        return const Center(
          child: CircularProgressIndicator(color: CmsColors.orange),
        );
      }

      if (_ctrl.error != null && _ctrl.settings == null) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: CmsColors.red, size: 36),
                const SizedBox(height: 12),
                Text(
                  _ctrl.error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: CmsColors.textPrimary),
                ),
                const SizedBox(height: 16),
                CmsPrimaryButton(
                  label: 'Retry',
                  icon: Icons.refresh,
                  onTap: () => _ctrl.load(force: true),
                ),
              ],
            ),
          ),
        );
      }

      return SingleChildScrollView(
        padding: EdgeInsets.all(isWeb ? 24 : 16),
        child: Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isWeb ? 560 : double.infinity),
            child: Form(
              key: _formKey,
              child: CmsFormCard(
                title: 'VAT settings',
                children: [
                  const Text(
                    'Set the store VAT registration number and the VAT percentage '
                    'applied to product prices at checkout.',
                    style: TextStyle(
                      fontSize: 12,
                      color: CmsColors.textSecond,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _vatNumberCtrl,
                    decoration: const InputDecoration(
                      labelText: 'VAT Number',
                      hintText: 'e.g. 4123456789',
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.next,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-/ ]')),
                      LengthLimitingTextInputFormatter(64),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _vatPercentCtrl,
                    decoration: const InputDecoration(
                      labelText: 'VAT percentage',
                      hintText: 'e.g. 15',
                      suffixText: '%',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    validator: (value) {
                      final raw = (value ?? '').trim();
                      if (raw.isEmpty) return 'Enter VAT percentage';
                      final n = double.tryParse(raw);
                      if (n == null) return 'Enter a valid number';
                      if (n < 0 || n > 100) {
                        return 'Must be between 0 and 100';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: CmsPrimaryButton(
                      label: _ctrl.isSaving ? 'Saving…' : 'Save settings',
                      icon: Icons.save_outlined,
                      isLoading: _ctrl.isSaving,
                      onTap: _ctrl.isSaving ? () {} : _save,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

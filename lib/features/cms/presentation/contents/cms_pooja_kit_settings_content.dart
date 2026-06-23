// Pooja Kit → Ecommerce Settings (delivery fee / charges).

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
  late final TextEditingController _feeCtrl;
  late final Worker _settingsWorker;
  final _formKey = GlobalKey<FormState>();
  bool _isEnabled = true;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<EcommerceSettingsController>();
    _feeCtrl = TextEditingController();
    _settingsWorker = ever<EcommerceSettings?>(
      _ctrl.settingsRx,
      (_) => _syncFieldsFromSettings(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncFieldsFromSettings());
  }

  void _syncFieldsFromSettings() {
    if (!mounted) return;
    final settings = _ctrl.settings;
    if (settings == null) return;
    final fee = settings.deliveryFee;
    setState(() {
      _isEnabled = settings.isEnabled;
    });
    _feeCtrl.text = fee == fee.roundToDouble()
        ? fee.toStringAsFixed(0)
        : fee.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _settingsWorker.dispose();
    _feeCtrl.dispose();
    super.dispose();
  }

  double? _parseFee() {
    final raw = _feeCtrl.text.trim();
    if (raw.isEmpty) return 0;
    return double.tryParse(raw);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final fee = _parseFee();
    if (fee == null) return;
    await _ctrl.saveSettings(deliveryFee: fee);
  }

  Future<void> _onEnabledChanged(bool value) async {
    if (_ctrl.isTogglingEnabled || _ctrl.isSaving) return;
    final previous = _isEnabled;
    setState(() => _isEnabled = value);
    final fee = _parseFee() ?? _ctrl.deliveryFee;
    final ok = await _ctrl.updateDeliveryEnabled(
      isEnabled: value,
      deliveryFee: fee,
    );
    if (!ok && mounted) {
      setState(() => _isEnabled = previous);
    }
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
                title: 'Delivery fee / charges',
                children: [
                  const Text(
                    'Set the flat delivery charge applied to product orders. '
                    'Currency is fixed to ZAR.',
                    style: TextStyle(
                      fontSize: 12,
                      color: CmsColors.textSecond,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Delivery charges',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: CmsColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isEnabled
                                  ? 'Charges apply at checkout'
                                  : 'Charges are disabled for all orders',
                              style: const TextStyle(
                                fontSize: 11,
                                color: CmsColors.textSecond,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_ctrl.isTogglingEnabled)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: CmsColors.orange,
                          ),
                        )
                      else
                        Switch(
                          value: _isEnabled,
                          activeColor: CmsColors.orange,
                          onChanged: _ctrl.isSaving
                              ? null
                              : _onEnabledChanged,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        flex: 2,
                        child: _ReadOnlyCurrencyField(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Delivery fee',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: CmsColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _feeCtrl,
                              enabled: !_ctrl.isSaving && !_ctrl.isTogglingEnabled,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d{0,2}'),
                                ),
                              ],
                              style: const TextStyle(
                                fontSize: 13,
                                color: CmsThemeColors.inputText,
                              ),
                              decoration: const InputDecoration(
                                hintText: '0.00',
                                hintStyle: TextStyle(
                                  color: CmsThemeColors.inputHint,
                                  fontSize: 13,
                                ),
                                filled: true,
                                fillColor: CmsColors.bg,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(8),
                                  ),
                                  borderSide: BorderSide(color: CmsColors.border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(8),
                                  ),
                                  borderSide: BorderSide(color: CmsColors.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(8),
                                  ),
                                  borderSide: BorderSide(color: CmsColors.orange),
                                ),
                              ),
                              validator: (v) {
                                final text = (v ?? '').trim();
                                if (text.isEmpty) return null;
                                final n = double.tryParse(text);
                                if (n == null) return 'Enter a valid number';
                                if (n < 0) return 'Cannot be negative';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: CmsPrimaryButton(
                      label: 'Set Delivery Fee',
                      icon: Icons.save_outlined,
                      isLoading: _ctrl.isSaving,
                      onTap: _ctrl.isTogglingEnabled ? () {} : _save,
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

class _ReadOnlyCurrencyField extends StatelessWidget {
  const _ReadOnlyCurrencyField();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Currency',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: CmsColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: CmsColors.border),
          ),
          child: const Text(
            'ZAR',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: CmsColors.textSecond,
            ),
          ),
        ),
      ],
    );
  }
}

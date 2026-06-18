import 'package:dio/dio.dart';
import 'package:get/get.dart';

import 'package:satya_devotte_app/features/cms/data/datasources/ecommerce_settings_remote_datasource.dart';
import 'package:satya_devotte_app/features/cms/data/models/ecommerce_settings_model.dart';
import 'package:satya_devotte_app/features/cms/presentation/widgets/cms_shared_widgets.dart';

class EcommerceSettingsController extends GetxController {
  EcommerceSettingsController(this._ds);
  final EcommerceSettingsRemoteDataSource _ds;

  static const defaultCurrency = 'ZAR';

  final _isLoading = false.obs;
  final _isSaving = false.obs;
  final _isTogglingEnabled = false.obs;
  final _error = RxnString();
  final _settings = Rxn<EcommerceSettings>();

  bool get isLoading => _isLoading.value;
  bool get isSaving => _isSaving.value;
  bool get isTogglingEnabled => _isTogglingEnabled.value;
  String? get error => _error.value;
  EcommerceSettings? get settings => _settings.value;
  Rxn<EcommerceSettings> get settingsRx => _settings;
  String get currency => _settings.value?.currency ?? defaultCurrency;
  double get deliveryFee => _settings.value?.deliveryFee ?? 0;
  bool get isDeliveryEnabled => _settings.value?.isEnabled ?? true;

  Future<void> load({bool force = false}) async {
    if (_isLoading.value) return;
    if (!force && _settings.value != null) return;
    _isLoading.value = true;
    _error.value = null;
    try {
      _settings.value = await _ds.getSettings();
    } on DioException catch (e) {
      _error.value = _msg(e);
    } catch (_) {
      _error.value = 'Failed to load ecommerce settings.';
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> updateDeliveryEnabled({
    required bool isEnabled,
    required double deliveryFee,
  }) async {
    if (_isTogglingEnabled.value || _isSaving.value) return false;
    if (deliveryFee < 0) {
      showCmsSnackbar(
        title: 'Invalid amount',
        message: 'Delivery fee cannot be negative.',
        isError: true,
      );
      return false;
    }

    _isTogglingEnabled.value = true;
    try {
      final current = _settings.value;
      final payload = (current ?? const EcommerceSettings(deliveryFee: 0))
          .copyWith(
            deliveryFee: deliveryFee,
            currency: defaultCurrency,
            isEnabled: isEnabled,
          );
      _settings.value = await _ds.updateSettings(payload);
      showCmsSnackbar(
        title: isEnabled ? 'Enabled' : 'Disabled',
        message: isEnabled
            ? 'Delivery charges are now enabled.'
            : 'Delivery charges are now disabled.',
      );
      return true;
    } on DioException catch (e) {
      showCmsSnackbar(
        title: 'Update failed',
        message: _msg(e),
        isError: true,
      );
      return false;
    } catch (_) {
      showCmsSnackbar(
        title: 'Update failed',
        message: 'Could not update delivery charge status. Please try again.',
        isError: true,
      );
      return false;
    } finally {
      _isTogglingEnabled.value = false;
    }
  }

  Future<bool> saveSettings({
    required double deliveryFee,
  }) async {
    if (_isSaving.value || _isTogglingEnabled.value) return false;
    if (deliveryFee < 0) {
      showCmsSnackbar(
        title: 'Invalid amount',
        message: 'Delivery fee cannot be negative.',
        isError: true,
      );
      return false;
    }
    _isSaving.value = true;
    try {
      final current = _settings.value;
      final payload = (current ?? const EcommerceSettings(deliveryFee: 0))
          .copyWith(
            deliveryFee: deliveryFee,
            currency: defaultCurrency,
            isEnabled: current?.isEnabled ?? true,
          );
      _settings.value = await _ds.updateSettings(payload);
      showCmsSnackbar(
        title: 'Saved',
        message: 'Delivery fee updated successfully.',
      );
      return true;
    } on DioException catch (e) {
      showCmsSnackbar(
        title: 'Save failed',
        message: _msg(e),
        isError: true,
      );
      return false;
    } catch (_) {
      showCmsSnackbar(
        title: 'Save failed',
        message: 'Could not update delivery fee. Please try again.',
        isError: true,
      );
      return false;
    } finally {
      _isSaving.value = false;
    }
  }

  String _msg(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final m = data['message'];
      if (m is String && m.isNotEmpty) return m;
    }
    return e.message ?? 'Network error. Please try again.';
  }
}

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
  final _error = RxnString();
  final _settings = Rxn<EcommerceSettings>();

  bool get isLoading => _isLoading.value;
  bool get isSaving => _isSaving.value;
  String? get error => _error.value;
  EcommerceSettings? get settings => _settings.value;
  Rxn<EcommerceSettings> get settingsRx => _settings;

  @override
  void onInit() {
    super.onInit();
    load();
  }

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

  Future<bool> saveSettings({
    required String vatNumber,
    required double vatPercent,
  }) async {
    if (_isSaving.value) return false;
    if (vatPercent < 0 || vatPercent > 100) {
      showCmsSnackbar(
        title: 'Invalid VAT %',
        message: 'VAT percentage must be between 0 and 100.',
        isError: true,
      );
      return false;
    }

    _isSaving.value = true;
    try {
      final current = _settings.value ?? const EcommerceSettings();
      final payload = current.copyWith(
        vatNumber: vatNumber.trim(),
        vatPercent: vatPercent,
        currency: defaultCurrency,
      );
      _settings.value = await _ds.updateSettings(payload);
      showCmsSnackbar(
        title: 'Saved',
        message: 'VAT settings updated successfully.',
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
        message: 'Could not update VAT settings. Please try again.',
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

// Admin / super-admin: paginated table of every contribution across the
// platform.
//
// Backed by GET /api/v1/donations/contributions/all
// Filter (paymentStatus): ALL | PAID | PENDING | FAILED
import 'package:dio/dio.dart';
import 'package:get/get.dart';

import 'package:satya_devotte_app/features/cms/data/datasources/donation_remote_datasource.dart';
import 'package:satya_devotte_app/features/donations/data/models/donation_contribution.dart';

class CmsContributionsController extends GetxController {
  CmsContributionsController(this._ds);
  final DonationRemoteDataSource _ds;

  static const filters = <String>['ALL', 'PAID', 'PENDING', 'FAILED'];

  final _items = <DonationContribution>[].obs;
  final _isLoading = false.obs;
  final _error = RxnString();

  final _page = 1.obs;
  final _limit = 10.obs;
  final _total = 0.obs;
  final _totalPages = 1.obs;
  final _filter = 'ALL'.obs; // show every contribution by default

  List<DonationContribution> get items => _items;
  bool get isLoading => _isLoading.value;
  String? get error => _error.value;

  int get page => _page.value;
  int get limit => _limit.value;
  int get total => _total.value;
  int get totalPages => _totalPages.value;
  String get filter => _filter.value;

  bool get isEmpty =>
      !_isLoading.value && _error.value == null && _items.isEmpty;

  @override
  void onInit() {
    super.onInit();
    refreshContributions();
  }

  String? get _paymentStatusFilter =>
      _filter.value == 'ALL' ? null : _filter.value;

  Future<void> refreshContributions() => _load(page: 1);

  Future<void> goToPage(int target) async {
    if (target < 1) target = 1;
    if (target > _totalPages.value) target = _totalPages.value;
    if (target == _page.value && _items.isNotEmpty) return;
    await _load(page: target);
  }

  Future<void> nextPage() => goToPage(_page.value + 1);
  Future<void> prevPage() => goToPage(_page.value - 1);

  void setFilter(String f) {
    final v = f.toUpperCase();
    if (!filters.contains(v) || _filter.value == v) return;
    _filter.value = v;
    refreshContributions();
  }

  void setLimit(int v) {
    if (v <= 0 || v == _limit.value) return;
    _limit.value = v;
    refreshContributions();
  }

  Future<void> _load({required int page}) async {
    _isLoading.value = true;
    _error.value = null;
    try {
      final res = await _ds.getAllContributions(
        page: page,
        limit: _limit.value,
        paymentStatus: _paymentStatusFilter,
      );
      _items.assignAll(res.items);
      _page.value = res.page;
      _limit.value = res.limit;
      _total.value = res.total;
      _totalPages.value = res.totalPages;
    } on DioException catch (e) {
      _error.value = _messageFromDio(e);
    } catch (_) {
      _error.value = 'Failed to load contributions.';
    } finally {
      _isLoading.value = false;
    }
  }

  String _messageFromDio(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final m = data['message'];
      if (m is String && m.isNotEmpty) return m;
    }
    return e.message ?? 'Network error. Please try again.';
  }
}

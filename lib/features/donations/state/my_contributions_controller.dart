// Paginated history of the signed-in user's contributions, with a
// status filter (ALL / PAID / PENDING / FAILED).
import 'package:get/get.dart';

import 'package:satya_devotte_app/features/donations/data/donation_exception.dart';
import 'package:satya_devotte_app/features/donations/data/donations_repository.dart';
import 'package:satya_devotte_app/features/donations/data/models/donation_contribution.dart';

class MyContributionsController extends GetxController {
  MyContributionsController(this._repo);
  final DonationsRepository _repo;

  static const _pageSize = 10;
  static const filters = <String>['ALL', 'PAID', 'PENDING', 'FAILED'];

  final _items = <DonationContribution>[].obs;
  final _isLoading = false.obs;
  final _isLoadingMore = false.obs;
  final _error = RxnString();
  final _page = 1.obs;
  final _totalPages = 1.obs;
  final _filter = 'ALL'.obs;

  List<DonationContribution> get items => _items;
  bool get isLoading => _isLoading.value;
  bool get isLoadingMore => _isLoadingMore.value;
  String? get error => _error.value;
  int get page => _page.value;
  int get totalPages => _totalPages.value;
  String get filter => _filter.value;
  bool get hasMore => _page.value < _totalPages.value;
  bool get isEmpty => !_isLoading.value && _error.value == null && _items.isEmpty;

  @override
  void onInit() {
    super.onInit();
    refreshContributions();
  }

  String? get _paymentStatusFilter =>
      _filter.value == 'ALL' ? null : _filter.value;

  Future<void> refreshContributions() async {
    _isLoading.value = true;
    _error.value = null;
    try {
      final res = await _repo.listMyContributions(
        page: 1,
        limit: _pageSize,
        paymentStatus: _paymentStatusFilter,
      );
      _items.assignAll(res.items);
      _page.value = 1;
      _totalPages.value = res.totalPages < 1 ? 1 : res.totalPages;
    } on DonationException catch (e) {
      _error.value = e.message;
    } catch (_) {
      _error.value = 'Failed to load your contributions.';
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore.value || !hasMore) return;
    _isLoadingMore.value = true;
    final next = _page.value + 1;
    try {
      final res = await _repo.listMyContributions(
        page: next,
        limit: _pageSize,
        paymentStatus: _paymentStatusFilter,
      );
      _items.addAll(res.items);
      _page.value = next;
      _totalPages.value = res.totalPages < 1 ? 1 : res.totalPages;
    } on DonationException catch (e) {
      _error.value = e.message;
    } catch (_) {
      // Silent — keep already-loaded items visible.
    } finally {
      _isLoadingMore.value = false;
    }
  }

  void setFilter(String f) {
    final v = f.toUpperCase();
    if (!filters.contains(v) || _filter.value == v) return;
    _filter.value = v;
    refreshContributions();
  }
}

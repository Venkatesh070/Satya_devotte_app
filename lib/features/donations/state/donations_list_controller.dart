// Drives the user-facing donations list screen.
import 'package:get/get.dart';

import 'package:satya_devotte_app/features/donations/data/donation_exception.dart';
import 'package:satya_devotte_app/features/donations/data/donations_repository.dart';
import 'package:satya_devotte_app/features/donations/data/models/donation.dart';

class DonationsListController extends GetxController {
  DonationsListController(this._repo);
  final DonationsRepository _repo;

  final _items = <Donation>[].obs;
  final _isLoading = false.obs;
  final _error = RxnString();

  List<Donation> get items => _items;
  bool get isLoading => _isLoading.value;
  String? get error => _error.value;
  bool get isEmpty => !_isLoading.value && _error.value == null && _items.isEmpty;

  @override
  void onInit() {
    super.onInit();
    refreshDonations();
  }

  Future<void> refreshDonations() async {
    _isLoading.value = true;
    _error.value = null;
    try {
      final list = await _repo.listDonations();
      _items.assignAll(list);
    } on DonationException catch (e) {
      _error.value = e.message;
    } catch (_) {
      _error.value = 'Something went wrong while loading donations.';
    } finally {
      _isLoading.value = false;
    }
  }
}

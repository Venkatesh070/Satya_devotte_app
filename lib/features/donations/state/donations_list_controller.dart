// Drives the user-facing donations list screen.
import 'package:get/get.dart';

import 'package:satya_devotte_app/features/donations/data/donation_exception.dart';
import 'package:satya_devotte_app/features/donations/data/donations_repository.dart';
import 'package:satya_devotte_app/features/donations/data/models/donation.dart';

import 'package:satya_devotte_app/features/donations/data/models/donation_contribution.dart';

class DonationsListController extends GetxController {
  DonationsListController(this._repo);
  final DonationsRepository _repo;

  final _items = <Donation>[].obs;
  final _contributions = <DonationContribution>[].obs;
  final _isLoading = false.obs;
  final _error = RxnString();

  List<Donation> get items => _items;
  List<DonationContribution> get contributions => _contributions;
  bool get isLoading => _isLoading.value;
  String? get error => _error.value;
  bool get isEmpty => !_isLoading.value && _error.value == null && _items.isEmpty;

  double get totalDonated => _contributions
      .where((c) => c.status == ContributionStatus.paid)
      .fold(0.0, (sum, c) => sum + c.amount.toDouble());

  int get contributionsCount =>
      _contributions.where((c) => c.status == ContributionStatus.paid).length;

  @override
  void onInit() {
    super.onInit();
    refreshDonations();
    fetchContributions();
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

  Future<void> fetchContributions() async {
    try {
      // Fetch a large enough batch to compute summary, or ideally we'd have a summary endpoint
      final res = await _repo.listMyContributions(page: 1, limit: 100);
      _contributions.assignAll(res.items);
    } catch (_) {
      // Silent error for summary
    }
  }
}

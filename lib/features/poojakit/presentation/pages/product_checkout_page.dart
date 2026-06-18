// lib/features/poojakit/presentation/pages/product_checkout_page.dart

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/core/services/location_service.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/core/utils/toast_util.dart';
import 'package:satya_devotte_app/features/cms/models/product_model.dart';
import 'package:satya_devotte_app/features/poojakit/data/models/address_model.dart';
import 'package:satya_devotte_app/features/poojakit/state/poojakit_checkout_controller.dart';
import 'package:satya_devotte_app/features/profile/presentation/controllers/profile_controller.dart';
import 'package:satya_devotte_app/shared/widgets/gradient_outline_input_border.dart';

class ProductCheckoutPage extends StatefulWidget {
  const ProductCheckoutPage({super.key});

  @override
  State<ProductCheckoutPage> createState() => _ProductCheckoutPageState();
}

class _ProductCheckoutPageState extends State<ProductCheckoutPage> {
  ProductModel? _product;
  final int _quantity = 1;

  final _searchCtrl = TextEditingController();
  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _houseCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _provinceCtrl = TextEditingController();
  final _postalCodeCtrl = TextEditingController();
  final _countryCtrl = TextEditingController(text: 'South Africa');

  late final PoojaKitCheckoutController _checkoutCtrl;
  Timer? _searchDebounce;
  int _suggestionRequestId = 0;
  bool _showMapPicker = true;
  bool _isLocating = false;
  bool _isSearching = false;
  bool _isLoadingSuggestions = false;
  bool _isResolvingPin = false;
  bool _isEditingReceiver = true;
  Alignment _pinAlignment = const Alignment(0.08, 0.05);
  _PickedLocation? _pickedLocation;
  List<_LocationSuggestion> _suggestions = const [];
  double _mapCenterLat = -26.2041;
  double _mapCenterLng = 28.0473;
  static const int _mapZoom = 16;

  String get _locationPreview {
    final picked = _pickedLocation;
    if (picked == null) return 'Place the pin at exact delivery location';
    return picked.address;
  }

  @override
  void initState() {
    super.initState();
    final arg = Get.arguments;
    if (arg is ProductModel) {
      _product = arg;
    }
    _checkoutCtrl = Get.find<PoojaKitCheckoutController>();
    _hydrateSavedAddress();
    unawaited(_hydrateReceiverFromProfile());
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _houseCtrl.dispose();
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    _provinceCtrl.dispose();
    _postalCodeCtrl.dispose();
    _countryCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchCtrl.text.trim();
    _searchDebounce?.cancel();
    if (query.length < 3) {
      setState(() {
        _suggestions = const [];
        _isLoadingSuggestions = false;
      });
      return;
    }

    setState(() => _isLoadingSuggestions = true);
    _searchDebounce = Timer(
      const Duration(milliseconds: 450),
      () => _loadSuggestions(query),
    );
  }

  Future<void> _loadSuggestions(String query) async {
    final requestId = ++_suggestionRequestId;
    try {
      final matches = await locationFromAddress(query);
      if (!mounted || requestId != _suggestionRequestId) return;

      final suggestions = <_LocationSuggestion>[];
      for (final match in matches.take(5)) {
        suggestions.add(
          await _suggestionFromCoordinates(
            match.latitude,
            match.longitude,
            fallback: query,
          ),
        );
      }

      if (!mounted || requestId != _suggestionRequestId) return;
      setState(() => _suggestions = suggestions);
    } catch (_) {
      if (!mounted || requestId != _suggestionRequestId) return;
      setState(() => _suggestions = const []);
    } finally {
      if (mounted && requestId == _suggestionRequestId) {
        setState(() => _isLoadingSuggestions = false);
      }
    }
  }

  Future<_LocationSuggestion> _suggestionFromCoordinates(
    double lat,
    double lng, {
    required String fallback,
  }) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final title = [
          p.name,
          p.street,
        ].where((e) => (e ?? '').trim().isNotEmpty).join(', ');
        final subtitle = [
          p.locality,
          p.administrativeArea,
          p.postalCode,
          p.country,
        ].where((e) => (e ?? '').trim().isNotEmpty).join(', ');
        return _LocationSuggestion(
          latitude: lat,
          longitude: lng,
          title: title.trim().isEmpty ? fallback : title,
          subtitle: subtitle,
        );
      }
    } catch (_) {}

    return _LocationSuggestion(
      latitude: lat,
      longitude: lng,
      title: fallback,
      subtitle: '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
    );
  }

  void _hydrateSavedAddress() {
    final address = _checkoutCtrl.shippingAddress;
    if (address == null) return;
    _fullNameCtrl.text = address.fullName;
    _phoneCtrl.text = address.phone;
    _streetCtrl.text = address.addressLine1;
    _cityCtrl.text = address.city;
    _provinceCtrl.text = address.state;
    _postalCodeCtrl.text = address.postalCode;
    _countryCtrl.text = address.country;
    _pickedLocation = _PickedLocation(
      latitude: null,
      longitude: null,
      address: _addressPreview(address),
    );
    _isEditingReceiver =
        address.fullName.trim().isEmpty || address.phone.trim().isEmpty;
  }

  Future<void> _hydrateReceiverFromProfile() async {
    if (_fullNameCtrl.text.trim().isNotEmpty &&
        _phoneCtrl.text.trim().isNotEmpty) {
      return;
    }
    if (!Get.isRegistered<ProfileController>()) return;

    final profileCtrl = Get.find<ProfileController>();
    if (profileCtrl.resolvedUser == null && !profileCtrl.isLoading) {
      await profileCtrl.loadProfile();
    }
    final user = profileCtrl.resolvedUser;
    if (!mounted || user == null) return;

    final name = _firstNonEmpty(user, const [
      'fullName',
      'name',
      'displayName',
      'userName',
    ]);
    final phone = _firstNonEmpty(user, const [
      'phone',
      'mobile',
      'phoneNumber',
      'mobileNumber',
      'contactNumber',
    ]);

    setState(() {
      if (_fullNameCtrl.text.trim().isEmpty && name.isNotEmpty) {
        _fullNameCtrl.text = name;
      }
      if (_phoneCtrl.text.trim().isEmpty && phone.isNotEmpty) {
        _phoneCtrl.text = phone;
      }
      _isEditingReceiver =
          _fullNameCtrl.text.trim().isEmpty || _phoneCtrl.text.trim().isEmpty;
    });
  }

  String _firstNonEmpty(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return '';
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      final pos = await LocationService().getCurrentPosition();
      await _setPickedFromCoordinates(pos.latitude, pos.longitude);
      _pinAlignment = const Alignment(0.08, 0.05);
    } catch (e) {
      _showLocationError(e);
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _searchLocation() async {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _isSearching = true);
    try {
      final matches = await locationFromAddress(query);
      if (matches.isEmpty) {
        throw Exception('No matching location found.');
      }
      final first = matches.first;
      await _setPickedFromCoordinates(first.latitude, first.longitude);
      _pinAlignment = const Alignment(0.08, 0.05);
      setState(() => _suggestions = const []);
    } catch (e) {
      _showLocationError(e);
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _selectSuggestion(_LocationSuggestion suggestion) async {
    FocusScope.of(context).unfocus();
    _searchCtrl
      ..removeListener(_onSearchChanged)
      ..text = suggestion.displayText
      ..addListener(_onSearchChanged);
    setState(() {
      _suggestions = const [];
      _isSearching = true;
    });
    try {
      await _setPickedFromCoordinates(
        suggestion.latitude,
        suggestion.longitude,
      );
      _pinAlignment = const Alignment(0.08, 0.05);
    } catch (e) {
      _showLocationError(e);
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _setPickedFromCoordinates(double lat, double lng) async {
    final placemarks = await placemarkFromCoordinates(lat, lng);
    if (placemarks.isEmpty) {
      setState(() {
        _mapCenterLat = lat;
        _mapCenterLng = lng;
        _pickedLocation = _PickedLocation(
          latitude: lat,
          longitude: lng,
          address:
              'Selected location: ${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
        );
      });
      return;
    }

    final p = placemarks.first;
    final street = [
      p.street,
      p.subLocality,
    ].where((e) => (e ?? '').trim().isNotEmpty).join(', ');
    final city = p.locality ?? p.subAdministrativeArea ?? '';
    final province = p.administrativeArea ?? '';
    final postal = p.postalCode ?? '';
    final country = (p.country ?? '').trim().isEmpty
        ? _countryCtrl.text
        : p.country!;
    final address = [
      street,
      city,
      province,
      postal,
      country,
    ].where((e) => e.trim().isNotEmpty).join(', ');

    setState(() {
      _mapCenterLat = lat;
      _mapCenterLng = lng;
      _streetCtrl.text = street;
      _cityCtrl.text = city;
      _provinceCtrl.text = province;
      _postalCodeCtrl.text = postal;
      _countryCtrl.text = country;
      _pickedLocation = _PickedLocation(
        latitude: lat,
        longitude: lng,
        address: address.isEmpty
            ? 'Selected location: ${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}'
            : address,
      );
    });
  }

  void _movePin(Offset localPosition, Size size) {
    final x = ((localPosition.dx / size.width) * 2 - 1).clamp(-0.82, 0.82);
    final y = ((localPosition.dy / size.height) * 2 - 1).clamp(-0.65, 0.42);
    setState(() {
      _pinAlignment = Alignment(x.toDouble(), y.toDouble());
      _isResolvingPin = true;
    });
  }

  Future<void> _resolveMovedPin() async {
    final worldPixels = 256 * math.pow(2, _mapZoom).toDouble();
    final lngPerPixel = 360 / worldPixels;
    final latPerPixel =
        lngPerPixel * math.cos(_mapCenterLat * math.pi / 180).abs();
    final pixelDx = _pinAlignment.x * 180;
    final pixelDy = _pinAlignment.y * 320;
    final lat = _mapCenterLat - (pixelDy * latPerPixel);
    final lng = _mapCenterLng + (pixelDx * lngPerPixel);
    try {
      await _setPickedFromCoordinates(lat, lng);
    } catch (_) {
      setState(() {
        _mapCenterLat = lat;
        _mapCenterLng = lng;
        _pickedLocation = _PickedLocation(
          latitude: lat,
          longitude: lng,
          address:
              'Pinned location: ${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
        );
      });
    } finally {
      if (mounted) setState(() => _isResolvingPin = false);
    }
  }

  void _confirmMapLocation() {
    if (_pickedLocation == null) {
      ToastUtil.showInfo(
        'Search, use current location, or move the pin before continuing.',
      );
      return;
    }
    setState(() => _showMapPicker = false);
  }

  Future<void> _saveAddress() async {
    final address = _buildAddress();
    if (address == null) return;
    _checkoutCtrl.saveShippingAddress(address);

    if (_product == null) {
      Get.back();
      return;
    }

    final init = await _checkoutCtrl.initiate(
      productId: _product!.id,
      quantity: _quantity,
      shippingAddress: address,
    );
    if (init != null) {
      Get.toNamed(AppRoutes.poojaKitPayment, arguments: init);
      return;
    }

    ToastUtil.showError(_checkoutCtrl.lastError ?? 'Failed to initiate order');
  }

  AddressModel? _buildAddress() {
    if (_fullNameCtrl.text.trim().isEmpty ||
        _phoneCtrl.text.trim().isEmpty ||
        _houseCtrl.text.trim().isEmpty ||
        _streetCtrl.text.trim().isEmpty ||
        _provinceCtrl.text.trim().isEmpty) {
      ToastUtil.showInfo(
        'Please fill receiver details, house, street, and province.',
      );
      return null;
    }

    return AddressModel(
      fullName: _fullNameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      addressLine1: [
        _houseCtrl.text.trim(),
        _streetCtrl.text.trim(),
      ].where((e) => e.isNotEmpty).join(', '),
      city: _cityCtrl.text.trim(),
      state: _provinceCtrl.text.trim(),
      postalCode: _postalCodeCtrl.text.trim(),
      country: _countryCtrl.text.trim().isEmpty
          ? 'South Africa'
          : _countryCtrl.text.trim(),
    );
  }

  String _addressPreview(AddressModel address) {
    return [
      address.addressLine1,
      address.city,
      address.postalCode,
      address.country,
    ].where((e) => e.trim().isNotEmpty).join(', ');
  }

  void _showLocationError(Object e) {
    ToastUtil.showError(e.toString().replaceFirst('Exception: ', ''));
  }

  @override
  Widget build(BuildContext context) {
    if (_showMapPicker) {
      return _LocationPickerView(
        searchCtrl: _searchCtrl,
        locationText: _locationPreview,
        pinAlignment: _pinAlignment,
        centerLat: _mapCenterLat,
        centerLng: _mapCenterLng,
        zoom: _mapZoom,
        isLocating: _isLocating,
        isSearching: _isSearching,
        isLoadingSuggestions: _isLoadingSuggestions,
        isResolvingPin: _isResolvingPin,
        suggestions: _suggestions,
        onBack: () => Get.back(),
        onSearch: _searchLocation,
        onSuggestionTap: _selectSuggestion,
        onCurrentLocationTap: _fetchCurrentLocation,
        onMovePin: _movePin,
        onResolvePin: _resolveMovedPin,
        onConfirm: _confirmMapLocation,
      );
    }

    final singleProduct = _product != null;

    return Scaffold(
      backgroundColor: AppColors.appBgColor,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(onBack: () => setState(() => _showMapPicker = true)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Location Details',
                      style: AppTypography.lora(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF4A1C00),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Enter your address details for delivery',
                      style: AppTypography.inter(
                        fontSize: 10,
                        color: const Color(0xFF6C5B46),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _ReceiverCard(
                      fullNameCtrl: _fullNameCtrl,
                      phoneCtrl: _phoneCtrl,
                      isEditing: _isEditingReceiver,
                      onEditPhone: () =>
                          setState(() => _isEditingReceiver = true),
                    ),
                    const SizedBox(height: 14),
                    _InputLabel(
                      label: 'House / Flat / Floor & Building',
                      child: _AddressInput(
                        controller: _houseCtrl,
                        hint: 'Enter your house/flat number',
                      ),
                    ),
                    const SizedBox(height: 14),
                    _InputLabel(
                      label: 'Street',
                      child: _AddressInput(
                        controller: _streetCtrl,
                        hint: 'Enter building name and street',
                      ),
                    ),
                    const SizedBox(height: 14),
                    _InputLabel(
                      label: 'Select Province',
                      child: _AddressInput(
                        controller: _provinceCtrl,
                        hint: 'Select',
                        suffixIcon: Icons.keyboard_arrow_down,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _InputLabel(
                            label: 'City',
                            child: _AddressInput(
                              controller: _cityCtrl,
                              hint: 'City',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _InputLabel(
                            label: 'Postal Code',
                            child: _AddressInput(
                              controller: _postalCodeCtrl,
                              hint: 'Code',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _InputLabel(
                      label: 'Country',
                      child: _AddressInput(
                        controller: _countryCtrl,
                        hint: 'Country',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Obx(() {
              final loading = _checkoutCtrl.isInitiating;
              return _GradientCtaBar(
                enabled: !loading,
                label: loading
                    ? 'Please wait...'
                    : (singleProduct ? 'Proceed to Payment' : 'Save address'),
                onTap: loading ? null : _saveAddress,
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _LocationPickerView extends StatelessWidget {
  const _LocationPickerView({
    required this.searchCtrl,
    required this.locationText,
    required this.pinAlignment,
    required this.centerLat,
    required this.centerLng,
    required this.zoom,
    required this.isLocating,
    required this.isSearching,
    required this.isLoadingSuggestions,
    required this.isResolvingPin,
    required this.suggestions,
    required this.onBack,
    required this.onSearch,
    required this.onSuggestionTap,
    required this.onCurrentLocationTap,
    required this.onMovePin,
    required this.onResolvePin,
    required this.onConfirm,
  });

  final TextEditingController searchCtrl;
  final String locationText;
  final Alignment pinAlignment;
  final double centerLat;
  final double centerLng;
  final int zoom;
  final bool isLocating;
  final bool isSearching;
  final bool isLoadingSuggestions;
  final bool isResolvingPin;
  final List<_LocationSuggestion> suggestions;
  final VoidCallback onBack;
  final VoidCallback onSearch;
  final ValueChanged<_LocationSuggestion> onSuggestionTap;
  final VoidCallback onCurrentLocationTap;
  final void Function(Offset localPosition, Size size) onMovePin;
  final VoidCallback onResolvePin;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final mapSize = constraints.biggest;
            return GestureDetector(
              onTapDown: (details) => onMovePin(details.localPosition, mapSize),
              onPanUpdate: (details) =>
                  onMovePin(details.localPosition, mapSize),
              onPanEnd: (_) => onResolvePin(),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: _TileMapBackground(
                      centerLat: centerLat,
                      centerLng: centerLng,
                      zoom: zoom,
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.02),
                      ),
                    ),
                  ),
                  Align(
                    alignment: pinAlignment,
                    child: const Icon(
                      Icons.location_on,
                      color: Color(0xFFFF5A52),
                      size: 44,
                    ),
                  ),
                  Positioned(
                    left: 14,
                    top: 12,
                    child: _CircleIconButton(
                      icon: Icons.arrow_back,
                      onTap: onBack,
                    ),
                  ),
                  Positioned(
                    left: 18,
                    right: 18,
                    top: 72,
                    child: _SearchWithSuggestions(
                      controller: searchCtrl,
                      isSearching: isSearching,
                      isLoadingSuggestions: isLoadingSuggestions,
                      suggestions: suggestions,
                      onSearch: onSearch,
                      onSuggestionTap: onSuggestionTap,
                    ),
                  ),
                  Positioned(
                    left: 18,
                    right: 18,
                    bottom: 18,
                    child: _MapBottomSheet(
                      locationText: locationText,
                      isLocating: isLocating,
                      isResolvingPin: isResolvingPin,
                      onCurrentLocationTap: onCurrentLocationTap,
                      onConfirm: onConfirm,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SearchWithSuggestions extends StatelessWidget {
  const _SearchWithSuggestions({
    required this.controller,
    required this.isSearching,
    required this.isLoadingSuggestions,
    required this.suggestions,
    required this.onSearch,
    required this.onSuggestionTap,
  });

  final TextEditingController controller;
  final bool isSearching;
  final bool isLoadingSuggestions;
  final List<_LocationSuggestion> suggestions;
  final VoidCallback onSearch;
  final ValueChanged<_LocationSuggestion> onSuggestionTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          elevation: 4,
          shadowColor: const Color(0x18000000),
          child: TextField(
            controller: controller,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => onSearch(),
            style: AppTypography.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF4A1C00),
            ),
            decoration: InputDecoration(
              hintText: 'search',
              hintStyle: AppTypography.inter(
                fontSize: 12,
                color: const Color(0xFF9B958E),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              suffixIcon: IconButton(
                onPressed: isSearching ? null : onSearch,
                icon: isSearching || isLoadingSuggestions
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search, size: 20),
              ),
            ),
          ),
        ),
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Material(
            color: Colors.white,
            elevation: 8,
            shadowColor: const Color(0x22000000),
            borderRadius: BorderRadius.circular(10),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 230),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 6),
                shrinkWrap: true,
                itemCount: suggestions.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: Color(0x0F000000)),
                itemBuilder: (context, index) {
                  final suggestion = suggestions[index];
                  return InkWell(
                    onTap: () => onSuggestionTap(suggestion),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 18,
                            color: Color(0xFF253FA8),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  suggestion.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF4A1C00),
                                  ),
                                ),
                                if (suggestion.subtitle.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    suggestion.subtitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.inter(
                                      fontSize: 9.5,
                                      height: 1.25,
                                      color: const Color(0xFF6C5B46),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _MapBottomSheet extends StatelessWidget {
  const _MapBottomSheet({
    required this.locationText,
    required this.isLocating,
    required this.isResolvingPin,
    required this.onCurrentLocationTap,
    required this.onConfirm,
  });

  final String locationText;
  final bool isLocating;
  final bool isResolvingPin;
  final VoidCallback onCurrentLocationTap;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          OutlinedButton.icon(
            onPressed: isLocating ? null : onCurrentLocationTap,
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF4A1C00),
              side: const BorderSide(color: Color(0xFFE8E0D6)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: isLocating
                ? const SizedBox(
                    width: 13,
                    height: 13,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location, size: 14),
            label: Text(
              isLocating ? 'Locating...' : 'Current Location',
              style: AppTypography.inter(
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1F000000),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isResolvingPin
                      ? 'Finding address...'
                      : 'Place the pin at exact delivery location',
                  style: AppTypography.inter(
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFF9B958E),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: Color(0xFF253FA8),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        locationText,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.inter(
                          fontSize: 10,
                          height: 1.35,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF4A1C00),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _GradientButton(label: 'Confirm and Proceed', onTap: onConfirm),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: _CircleIconButton(icon: Icons.arrow_back, onTap: onBack),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 5,
      shadowColor: const Color(0x22000000),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 19, color: const Color(0xFF1C1C1C)),
        ),
      ),
    );
  }
}

class _TileMapBackground extends StatelessWidget {
  const _TileMapBackground({
    required this.centerLat,
    required this.centerLng,
    required this.zoom,
  });

  final double centerLat;
  final double centerLng;
  final int zoom;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height;
        final center = _latLngToTilePoint(centerLat, centerLng, zoom);
        final centerPixel = Offset(center.x * 256, center.y * 256);
        final topLeft = centerPixel - Offset(width / 2, height / 2);
        final startX = (topLeft.dx / 256).floor() - 1;
        final endX = ((topLeft.dx + width) / 256).ceil() + 1;
        final startY = (topLeft.dy / 256).floor() - 1;
        final endY = ((topLeft.dy + height) / 256).ceil() + 1;
        final maxTile = math.pow(2, zoom).toInt();
        final tiles = <Widget>[];

        for (var x = startX; x <= endX; x++) {
          for (var y = startY; y <= endY; y++) {
            if (y < 0 || y >= maxTile) continue;
            final wrappedX = ((x % maxTile) + maxTile) % maxTile;
            final left = (x * 256) - topLeft.dx;
            final top = (y * 256) - topLeft.dy;
            tiles.add(
              Positioned(
                left: left,
                top: top,
                width: 256,
                height: 256,
                child: Image.network(
                  'https://tile.openstreetmap.org/$zoom/$wrappedX/$y.png',
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.low,
                  errorBuilder: (_, _, _) => const _MapTileFallback(),
                ),
              ),
            );
          }
        }

        return ColoredBox(
          color: const Color(0xFFE8EDF1),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              ...tiles,
              const Positioned(
                right: 8,
                bottom: 6,
                child: Text(
                  'OpenStreetMap',
                  style: TextStyle(
                    fontSize: 8,
                    color: Color(0x994A4A4A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MapTileFallback extends StatelessWidget {
  const _MapTileFallback();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MapTileFallbackPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _MapTileFallbackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    final mainRoad = Paint()
      ..color = const Color(0xFFBFD0DE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    final minor = Paint()
      ..color = const Color(0xFFD4DEE8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawColor(const Color(0xFFE8EDF1), BlendMode.src);
    canvas.drawLine(const Offset(-20, 44), Offset(size.width + 20, 18), road);
    canvas.drawLine(
      Offset(10, size.height * .62),
      Offset(size.width + 20, size.height * .42),
      road,
    );
    canvas.drawLine(
      Offset(size.width * .2, -10),
      Offset(size.width * .6, size.height + 10),
      mainRoad,
    );
    canvas.drawLine(
      Offset(-10, size.height * .82),
      Offset(size.width + 10, size.height * .70),
      minor,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

_TilePoint _latLngToTilePoint(double lat, double lng, int zoom) {
  final sinLat = math.sin(lat * math.pi / 180).clamp(-0.9999, 0.9999);
  final scale = math.pow(2, zoom).toDouble();
  final x = (lng + 180) / 360 * scale;
  final y =
      (0.5 - math.log((1 + sinLat) / (1 - sinLat)) / (4 * math.pi)) * scale;
  return _TilePoint(x, y);
}

class _TilePoint {
  const _TilePoint(this.x, this.y);

  final double x;
  final double y;
}

class _ReceiverCard extends StatelessWidget {
  const _ReceiverCard({
    required this.fullNameCtrl,
    required this.phoneCtrl,
    required this.isEditing,
    required this.onEditPhone,
  });

  final TextEditingController fullNameCtrl;
  final TextEditingController phoneCtrl;
  final bool isEditing;
  final VoidCallback onEditPhone;

  @override
  Widget build(BuildContext context) {
    final name = fullNameCtrl.text.trim();
    final phone = phoneCtrl.text.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Receiver details',
            style: AppTypography.inter(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF4A1C00),
            ),
          ),
          const SizedBox(height: 12),
          if (!isEditing) ...[
            _ReceiverInfoRow(label: 'Name', value: name),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _ReceiverInfoRow(label: 'Phone number', value: phone),
                ),
                TextButton.icon(
                  onPressed: onEditPhone,
                  icon: const Icon(Icons.edit_outlined, size: 14),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFE95700),
                    textStyle: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Text(
              'Enter receiver details to continue.',
              style: AppTypography.inter(
                fontSize: 9.5,
                color: const Color(0xFF8B765D),
              ),
            ),
            const SizedBox(height: 10),
            _AddressInput(controller: fullNameCtrl, hint: 'Name'),
            const SizedBox(height: 10),
            _AddressInput(
              controller: phoneCtrl,
              hint: 'Phone number',
              keyboardType: TextInputType.phone,
            ),
          ],
        ],
      ),
    );
  }
}

class _ReceiverInfoRow extends StatelessWidget {
  const _ReceiverInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: AppTypography.inter(
              fontSize: 10,
              color: const Color(0xFF4A1C00),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? 'Not provided' : value,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.inter(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF4A1C00),
            ),
          ),
        ),
      ],
    );
  }
}

class _InputLabel extends StatelessWidget {
  const _InputLabel({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.inter(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF6C3D1F),
          ),
        ),
        const SizedBox(height: 7),
        child,
      ],
    );
  }
}

class _AddressInput extends StatelessWidget {
  const _AddressInput({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final IconData? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: AppTypography.inter(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF4A1C00),
      ),
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle: AppTypography.inter(
          fontSize: 11,
          color: const Color(0xFFB7AAA0),
        ),
        suffixIcon: suffixIcon == null
            ? null
            : Icon(suffixIcon, size: 18, color: const Color(0xFF6C5B46)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.inputBorderColor),
        ),
        focusedBorder: GradientOutlineInputBorder(
          gradient: AppColors.inputBorderGradient,
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE95700)),
        ),
      ),
    );
  }
}

class _GradientCtaBar extends StatelessWidget {
  const _GradientCtaBar({
    required this.label,
    required this.onTap,
    required this.enabled,
  });

  final String label;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
        child: _GradientButton(
          label: label,
          onTap: enabled ? onTap : null,
          enabled: enabled,
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        height: 48,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: enabled
              ? const LinearGradient(
                  colors: [AppColors.gradientStart, AppColors.gradientEnd],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : const LinearGradient(
                  colors: [Color(0xFFB8B1AA), Color(0xFFB8B1AA)],
                ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTypography.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _PickedLocation {
  const _PickedLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  final double? latitude;
  final double? longitude;
  final String address;
}

class _LocationSuggestion {
  const _LocationSuggestion({
    required this.latitude,
    required this.longitude,
    required this.title,
    required this.subtitle,
  });

  final double latitude;
  final double longitude;
  final String title;
  final String subtitle;

  String get displayText {
    if (subtitle.trim().isEmpty) return title;
    return '$title, $subtitle';
  }
}

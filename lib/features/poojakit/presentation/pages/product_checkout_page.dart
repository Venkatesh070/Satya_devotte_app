// lib/features/poojakit/presentation/pages/product_checkout_page.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geocoding/geocoding.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/core/services/location_service.dart';
import 'package:satya_devotte_app/features/cms/models/product_model.dart';
import 'package:satya_devotte_app/features/poojakit/data/models/address_model.dart';
import 'package:satya_devotte_app/features/poojakit/state/poojakit_checkout_controller.dart';
import 'package:satya_devotte_app/features/poojakit/state/cart_controller.dart';
class ProductCheckoutPage extends StatefulWidget {
  const ProductCheckoutPage({super.key});

  @override
  State<ProductCheckoutPage> createState() => _ProductCheckoutPageState();
}

class _ProductCheckoutPageState extends State<ProductCheckoutPage> {
  ProductModel? _product;
  int _quantity = 1;
  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressLine1Ctrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _postalCodeCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  bool _isLocating = false;

  late final PoojaKitCheckoutController _checkoutCtrl;
  late final CartController _cartCtrl;

  @override
  void initState() {
    super.initState();
    final arg = Get.arguments;
    if (arg is ProductModel) {
      _product = arg;
    }
    _checkoutCtrl = Get.find<PoojaKitCheckoutController>();
    _cartCtrl = Get.find<CartController>();
    _checkoutCtrl.reset();
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressLine1Ctrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _postalCodeCtrl.dispose();
    _countryCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      final pos = await LocationService().getCurrentPosition();
      final placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        setState(() {
          final street = p.street ?? '';
          final subLoc = p.subLocality ?? '';
          _addressLine1Ctrl.text = street.isNotEmpty && subLoc.isNotEmpty
              ? '$street, $subLoc'
              : (street.isNotEmpty ? street : subLoc);
          _cityCtrl.text = p.locality ?? '';
          _stateCtrl.text = p.administrativeArea ?? '';
          _postalCodeCtrl.text = p.postalCode ?? '';
          _countryCtrl.text = p.country ?? '';
        });
      }
    } catch (e) {
      Get.snackbar(
        'Location Error',
        'Could not get your current location. Please enter manually.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      setState(() => _isLocating = false);
    }
  }

  void _increment() {
    if (_product != null && _quantity < _product!.stockQuantity) {
      setState(() => _quantity++);
    }
  }

  void _decrement() {
    if (_quantity > 1) {
      setState(() => _quantity--);
    }
  }

  Future<void> _handleCheckout() async {
    if (_fullNameCtrl.text.trim().isEmpty ||
        _phoneCtrl.text.trim().isEmpty ||
        _addressLine1Ctrl.text.trim().isEmpty ||
        _cityCtrl.text.trim().isEmpty ||
        _stateCtrl.text.trim().isEmpty ||
        _postalCodeCtrl.text.trim().isEmpty ||
        _countryCtrl.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Please fill all required address fields',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final shippingAddress = AddressModel(
      fullName: _fullNameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      addressLine1: _addressLine1Ctrl.text.trim(),
      city: _cityCtrl.text.trim(),
      state: _stateCtrl.text.trim(),
      postalCode: _postalCodeCtrl.text.trim(),
      country: _countryCtrl.text.trim(),
    );

    dynamic init;
    if (_product != null) {
      init = await _checkoutCtrl.initiate(
        productId: _product!.id,
        quantity: _quantity,
        shippingAddress: shippingAddress,
        notes: _notesCtrl.text.trim(),
      );
    } else {
      init = await _checkoutCtrl.initiateCartCheckout(
        shippingAddress: shippingAddress,
        notes: _notesCtrl.text.trim(),
      );
    }

    if (init != null) {
      if (_product == null) {
        // Clear cart after successful cart checkout initiation
        _cartCtrl.clearCart();
      }
      Get.toNamed(AppRoutes.poojaKitPayment, arguments: init);
    } else {
      Get.snackbar(
        'Error',
        _checkoutCtrl.lastError ?? 'Failed to initiate order',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isSingleProduct = _product != null;
    final String currency = isSingleProduct
        ? _product!.currency
        : (_cartCtrl.cart?.currency ?? 'ZAR');
    final num totalPrice = isSingleProduct
        ? (_product!.effectivePrice * _quantity)
        : (_cartCtrl.cart?.totalAmount ?? 0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.textColor,
                    ),
                    onPressed: () => Get.back(),
                  ),
                  Text(
                    isSingleProduct ? 'Checkout' : 'Cart Checkout',
                    style: AppTypography.lora(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Summary Card
                    if (isSingleProduct)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                width: 80,
                                height: 80,
                                child: _product!.imageUrl != null
                                    ? CachedNetworkImage(
                                        imageUrl: _product!.imageUrl!,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(color: Colors.grey[200]),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _product!.title,
                                    style: AppTypography.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_product!.currency} ${_product!.effectivePrice}',
                                    style: AppTypography.inter(
                                      fontSize: 14,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      // Cart items summary
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE8E0D6)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order Summary (${_cartCtrl.itemCount} items)',
                              style: AppTypography.inter(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textColor,
                              ),
                            ),
                            Divider(color: Colors.grey.shade300),
                            ...(_cartCtrl.cart?.items.map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${item.product.title} x ${item.quantity}',
                                            style: TextStyle(
                                              color: AppColors.textColor
                                                  .withValues(alpha: 0.7),
                                              fontSize: 13,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          '${item.product.currency} ${item.lineTotal}',
                                          style: const TextStyle(
                                            color: AppColors.textColor,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ) ??
                                []),
                          ],
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Quantity Selector (only for single product)
                    if (isSingleProduct) ...[
                      Text(
                        'Quantity',
                        style: AppTypography.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _quantityBtn(Icons.remove, _decrement),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              '$_quantity',
                              style: AppTypography.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textColor,
                              ),
                            ),
                          ),
                          _quantityBtn(Icons.add, _increment),
                          const SizedBox(width: 16),
                          Text(
                            '(${_product!.stockQuantity} in stock)',
                            style: AppTypography.inter(
                              fontSize: 12,
                              color: AppColors.textColor.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Shipping Address
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Shipping Address',
                          style: AppTypography.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textColor,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _isLocating ? null : _fetchCurrentLocation,
                          icon: _isLocating
                              ? const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                )
                              : const Icon(
                                  Icons.my_location,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                          label: Text(
                            _isLocating
                                ? 'Locating...'
                                : 'Use Current Location',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _addressField('Full Name', _fullNameCtrl),
                    const SizedBox(height: 12),
                    _addressField(
                      'Phone Number',
                      _phoneCtrl,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    _addressField('Address Line 1', _addressLine1Ctrl),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _addressField('City', _cityCtrl)),
                        const SizedBox(width: 12),
                        Expanded(child: _addressField('State', _stateCtrl)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _addressField('Postal Code', _postalCodeCtrl),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: _addressField('Country', _countryCtrl)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Order Notes
                    Text(
                      'Order Notes (Optional)',
                      style: AppTypography.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesCtrl,
                      style: const TextStyle(color: AppColors.textColor),
                      decoration: InputDecoration(
                        hintText: 'Special instructions…',
                        hintStyle: TextStyle(
                          color: AppColors.textColor.withValues(alpha: 0.45),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE8E0D6),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Summary & Button
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Amount',
                          style: AppTypography.inter(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          '$currency $totalPrice',
                          style: AppTypography.lora(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Obx(() {
                      final loading = _checkoutCtrl.isInitiating;
                      return SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: loading ? null : _handleCheckout,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: loading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Proceed to Payment',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _addressField(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textColor.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: AppColors.textColor, fontSize: 14),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE8E0D6)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _quantityBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE0D6C2)),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: Icon(icon, color: AppColors.textColor, size: 20),
      ),
    );
  }
}

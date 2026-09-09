// lib/features/poojakit/presentation/pages/cart_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/core/utils/toast_util.dart';
import 'package:satya_devotte_app/features/poojakit/data/models/address_model.dart';
import 'package:satya_devotte_app/features/poojakit/data/models/cart_model.dart';
import 'package:satya_devotte_app/features/poojakit/data/models/shipping_quote_model.dart';
import 'package:satya_devotte_app/features/poojakit/state/cart_controller.dart';
import 'package:satya_devotte_app/features/poojakit/state/poojakit_checkout_controller.dart';
import 'package:satya_devotte_app/features/profile/presentation/controllers/profile_controller.dart';
import 'package:satya_devotte_app/shared/widgets/chakra_loading_indicator.dart';
import 'package:satya_devotte_app/features/poojakit/presentation/pages/poojakit_page.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _pickupNameCtrl = TextEditingController();
  final _pickupPhoneCtrl = TextEditingController();
  final _showLocationError = false.obs;

  @override
  void initState() {
    super.initState();
    final c = Get.find<CartController>();
    c.fetchCart();
    final checkout = Get.find<PoojaKitCheckoutController>();
    checkout.resetFulfillmentMethod();
    _initCollectorDetails(checkout);

    // Proactively prefetch pickup location so it is ready immediately with 0 buffering
    if (checkout.pickupLocation == null && !checkout.isLoadingPickup) {
      checkout.fetchPickupLocation();
    }
  }

  void _initCollectorDetails(PoojaKitCheckoutController checkout) {
    final addr = checkout.shippingAddress;
    if (addr != null) {
      if (addr.fullName.trim().isNotEmpty) {
        _pickupNameCtrl.text = addr.fullName.trim();
      }
      if (addr.phone.trim().isNotEmpty) {
        _pickupPhoneCtrl.text = addr.phone.trim();
      }
    }
    if (_pickupNameCtrl.text.isEmpty || _pickupPhoneCtrl.text.isEmpty) {
      if (Get.isRegistered<ProfileController>()) {
        final profile = Get.find<ProfileController>().resolvedUser;
        if (profile != null) {
          if (_pickupNameCtrl.text.isEmpty) {
            final name = (profile['fullName'] ??
                    profile['name'] ??
                    profile['displayName'] ??
                    '')
                .toString()
                .trim();
            if (name.isNotEmpty) _pickupNameCtrl.text = name;
          }
          if (_pickupPhoneCtrl.text.isEmpty) {
            final phone = (profile['phone'] ??
                    profile['mobile'] ??
                    profile['phoneNumber'] ??
                    '')
                .toString()
                .trim();
            if (phone.isNotEmpty) _pickupPhoneCtrl.text = phone;
          }
        }
      }
    }
  }

  void _syncPickupContactToCheckout() {
    final checkout = Get.find<PoojaKitCheckoutController>();
    final currentAddr = checkout.shippingAddress;
    final name = _pickupNameCtrl.text.trim();
    final phone = _pickupPhoneCtrl.text.trim();
    final updated = AddressModel(
      fullName: name,
      phone: phone,
      addressLine1: currentAddr?.addressLine1 ?? '',
      city: currentAddr?.city ?? '',
      state: currentAddr?.state ?? '',
      postalCode: currentAddr?.postalCode ?? '',
      country: currentAddr?.country ?? 'South Africa',
      lat: currentAddr?.lat,
      lng: currentAddr?.lng,
      localArea: currentAddr?.localArea,
      enteredAddress: currentAddr?.enteredAddress,
    );
    checkout.saveShippingAddress(updated);
  }

  @override
  void dispose() {
    _pickupNameCtrl.dispose();
    _pickupPhoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<CartController>();
    final checkoutCtrl = Get.find<PoojaKitCheckoutController>();

    return Scaffold(
      backgroundColor: AppColors.appBgColor,
      body: SafeArea(
        child: Column(
          children: [
            _ShopTopBar(title: 'Shopping Cart', onBack: () => Get.back()),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                child: Obx(() {
                  if (c.isLoading && c.cart == null) {
                    return const Center(
                      child: ChakraLoadingIndicator(size: 36),
                    );
                  }

                  final cart = c.cart;
                  if (cart == null || cart.isEmpty) {
                    return const _EmptyCart();
                  }

                  return SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                  child: Column(
                    children: [
                      ...cart.items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _CartItemTile(item: item, controller: c),
                        ),
                      ),
                      const Divider(
                        height: 26,
                        thickness: 0.7,
                        color: Color(0x1A6B4A2B),
                      ),
                      _DeliveryOptionsSection(
                        checkoutCtrl: checkoutCtrl,
                        nameController: _pickupNameCtrl,
                        phoneController: _pickupPhoneCtrl,
                        onMethodChanged: (method) {
                          _showLocationError.value = false;
                          final items = c.cart?.items
                                  .map(
                                    (i) => {
                                      'productId': i.product.id,
                                      'quantity': i.quantity,
                                    },
                                  )
                                  .toList() ??
                              [];
                          checkoutCtrl.setFulfillmentMethod(
                            method,
                            pickupItems:
                                items.isNotEmpty ? items : null,
                          );
                        },
                        onSyncPickupContact: _syncPickupContactToCheckout,
                        onRetryPickup: () {
                          final items = c.cart?.items
                                  .map(
                                    (i) => {
                                      'productId': i.product.id,
                                      'quantity': i.quantity,
                                    },
                                  )
                                  .toList() ??
                              [];
                          checkoutCtrl.fetchPickupLocation(
                            cartItems: items.isNotEmpty ? items : null,
                          );
                        },
                        onRetryQuote: () {
                          final addr = checkoutCtrl.shippingAddress;
                          if (addr != null) {
                            final items = c.cart?.items
                                    .map(
                                      (i) => {
                                        'productId': i.product.id,
                                        'quantity': i.quantity,
                                      },
                                    )
                                    .toList() ??
                                [];
                            checkoutCtrl.fetchShippingQuote(
                              addr,
                              items: items.isEmpty ? null : items,
                            );
                          }
                        },
                        onChangeAddressTap: () => Get.toNamed(
                          AppRoutes.poojaKitCheckout,
                          arguments: null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _BillSummarySection(
                        cart: cart,
                        deliveryCharge: checkoutCtrl.previewDeliveryCharge,
                        isPickup: checkoutCtrl.isPickup,
                      ),
                      const SizedBox(height: 86),
                    ],
                  ),
                );
              }),
            ),
          ),
            Obx(() {
              if (c.isLoading && c.cart == null) {
                return const SizedBox.shrink();
              }
              final cart = c.cart;
              if (cart == null || cart.isEmpty) {
                return _GradientCtaBar(
                  enabled: true,
                  label: 'Go to shopping',
                  onTap: () => Get.off(() => const PoojaKitPage()),
                );
              }

              final hasOption = checkoutCtrl.hasFulfillmentMethod;
              final isDeliveryWithoutAddress =
                  checkoutCtrl.isDelivery && checkoutCtrl.shippingAddress == null;
              final showError =
                  _showLocationError.value && isDeliveryWithoutAddress;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showError)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDE8E8),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFF05252),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Color(0xFFE02424),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Please set delivery location to proceed.',
                              style: AppTypography.inter(
                                color: const Color(0xFF9B1C1C),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  _GradientCtaBar(
                    enabled: hasOption,
                    label: 'Proceed to Payment',
                    onTap: hasOption
                        ? () => _handleProceedToPayment(c, checkoutCtrl)
                        : null,
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _handleProceedToPayment(
    CartController cartCtrl,
    PoojaKitCheckoutController checkoutCtrl,
  ) async {
    if (!checkoutCtrl.hasFulfillmentMethod) {
      ToastUtil.showInfo('Please select a delivery option (Pick from Warehouse or Door Delivery).');
      return;
    }
    if (checkoutCtrl.isPickup) {
      _showLocationError.value = false;
      if (checkoutCtrl.pickupLocation == null) {
        final items = cartCtrl.cart?.items
                .map(
                  (i) => {
                    'productId': i.product.id,
                    'quantity': i.quantity,
                  },
                )
                .toList() ??
            [];
        final ok = items.isNotEmpty
            ? await checkoutCtrl.fetchPickupLocation(cartItems: items)
            : await checkoutCtrl.fetchPickupLocation();
        if (!ok) {
          ToastUtil.showError(
            checkoutCtrl.lastError ?? 'Could not load pickup location',
          );
          return;
        }
      }
      final name = _pickupNameCtrl.text.trim();
      final phone = _pickupPhoneCtrl.text.trim();
      if (name.isEmpty || phone.isEmpty) {
        ToastUtil.showInfo('Please enter collector name and phone for pickup.');
        return;
      }
      _syncPickupContactToCheckout();
    } else {
      final address = checkoutCtrl.shippingAddress;
      if (address == null) {
        _showLocationError.value = true;
        return;
      }
      _showLocationError.value = false;
      if (checkoutCtrl.selectedRate == null) {
        if (checkoutCtrl.quoteRates.isEmpty && !checkoutCtrl.isQuoting) {
          final items = cartCtrl.cart?.items
                  .map(
                    (i) => {
                      'productId': i.product.id,
                      'quantity': i.quantity,
                    },
                  )
                  .toList() ??
              [];
          await checkoutCtrl.fetchShippingQuote(
            address,
            items: items.isEmpty ? null : items,
          );
        }
        if (checkoutCtrl.selectedRate == null) {
          ToastUtil.showInfo('Please select a Courier Guy service level.');
          return;
        }
      }
    }

    final init = await checkoutCtrl.initiateCartCheckout(
      contactFullName: checkoutCtrl.isPickup ? _pickupNameCtrl.text.trim() : null,
      contactPhone: checkoutCtrl.isPickup ? _pickupPhoneCtrl.text.trim() : null,
    );
    if (init != null) {
      Get.toNamed(AppRoutes.poojaKitPayment, arguments: init);
      return;
    }

    ToastUtil.showError(checkoutCtrl.lastError ?? 'Failed to initiate order');
  }
}

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({required this.item, required this.controller});
  final CartItemModel item;
  final CartController controller;

  @override
  Widget build(BuildContext context) {
    final product = item.product;
    final isBusy = controller.isBusy(product.id);

    final itemCount = product.items.length;
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProductThumb(imageUrl: product.imageUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: AppTypography.lora(
                      fontSize: 16,
                      height: 1.25,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1C1917),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  _CartBullet(
                    text: itemCount == 0
                        ? product.description
                        : '$itemCount items required for performing the puja.',
                  ),
                  _CartBullet(text: 'Sufficient for 2 members.'),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      if (product.salePrice != null &&
                          product.salePrice! < product.price) ...[
                        Text(
                          '${product.currency} ${_formatPrice(product.price)}',
                          style: AppTypography.inter(
                            fontSize: 10,
                            color: const Color(0x8A6C5B46),
                            decoration: TextDecoration.lineThrough,
                            decorationColor: const Color(0x8A6C5B46),
                          ),
                        ),
                        const SizedBox(width: 5),
                      ],
                      Text(
                        '${product.currency} ${_formatPrice(product.effectivePrice)}',
                        style: AppTypography.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFDC5B0A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _qtyBtn(
              Icons.remove,
              isBusy
                  ? null
                  : () => controller.updateQuantity(
                      product.id,
                      item.quantity - 1,
                    ),
            ),
            Container(
              width: 42,
              alignment: Alignment.center,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                child: isBusy
                    ? const SizedBox(
                        key: ValueKey('busy'),
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          color: Color(0xFFDC5B0A),
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        item.quantity.toString().padLeft(2, '0'),
                        key: ValueKey(item.quantity),
                        style: AppTypography.inter(
                          color: const Color(0xFFDC5B0A),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
              ),
            ),
            _qtyBtn(
              Icons.add,
              isBusy
                  ? null
                  : () => controller.updateQuantity(
                      product.id,
                      item.quantity + 1,
                    ),
            ),
          ],
        ),
      ],
    );
  }

  static String _formatPrice(num value) {
    if (value % 1 == 0) return value.toInt().toStringAsFixed(2);
    return value.toStringAsFixed(2);
  }

  Widget _qtyBtn(IconData icon, VoidCallback? onTap) {
    return Material(
      color: Color(0xFFFCF7EF),
      borderRadius: BorderRadius.circular(2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(2),
        child: SizedBox(
          width: 28,
          height: 28,
          child: Icon(
            icon,
            color: onTap == null
                ? AppColors.textColor.withValues(alpha: 0.35)
                : AppColors.textColor,
            size: 15,
          ),
        ),
      ),
    );
  }
}

class _CartBullet extends StatelessWidget {
  const _CartBullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final value = text.trim().isEmpty ? 'Complete puja essentials.' : text;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '. ',
            style: AppTypography.inter(
              fontSize: 12,
              height: 1.25,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF78716C),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.inter(
                fontSize: 12,
                height: 1.25,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF78716C),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductThumb extends StatelessWidget {
  const _ProductThumb({required this.imageUrl});
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 100,
        height: 100,
        child: imageUrl != null && imageUrl!.trim().isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, _) => const ColoredBox(
                  color: Color(0xFFFFF7E8),
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: ChakraLoadingIndicator(
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                errorWidget: (_, _, _) => ColoredBox(
                  color: Color(0xFFFFF7E8),
                  child: Image.asset(
                    'assets/images/default_img.png',
                    fit: BoxFit.cover,
                  ),
                ),
              )
            : ColoredBox(
                color: Color(0xFFFFF7E8),
                child: Image.asset(
                  'assets/images/default_img.png',
                  fit: BoxFit.cover,
                ),
              ),
      ),
    );
  }
}

class _ShopTopBar extends StatelessWidget {
  const _ShopTopBar({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: SizedBox(
        height: 46,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: _CircleIconButton(icon: Icons.arrow_back, onTap: onBack),
            ),
            Text(
              title,
              style: AppTypography.inter(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1D160E),
              ),
            ),
          ],
        ),
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
      color: Color(0xFFFCF7EF),
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

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 70,
            color: AppColors.textColor.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 14),
          Text(
            'Your cart is empty',
            style: AppTypography.lora(
              fontSize: 16,
              color: AppColors.textColor.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryOptionsSection extends StatelessWidget {
  const _DeliveryOptionsSection({
    required this.checkoutCtrl,
    required this.nameController,
    required this.phoneController,
    required this.onMethodChanged,
    required this.onSyncPickupContact,
    required this.onRetryPickup,
    required this.onRetryQuote,
    required this.onChangeAddressTap,
  });

  final PoojaKitCheckoutController checkoutCtrl;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final ValueChanged<FulfillmentMethod> onMethodChanged;
  final VoidCallback onSyncPickupContact;
  final VoidCallback onRetryPickup;
  final VoidCallback onRetryQuote;
  final VoidCallback onChangeAddressTap;

  @override
  Widget build(BuildContext context) {
    final isPickup = checkoutCtrl.isPickup;
    final isDelivery = checkoutCtrl.isDelivery;
    final savedAddress = checkoutCtrl.shippingAddress;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Delivery Options',
          style: AppTypography.lora(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1C1917),
          ),
        ),
        const SizedBox(height: 14),

        // 1. Pick from Warehouse Card
        Material(
          color: const Color(0xFFFCF7EF),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => onMethodChanged(FulfillmentMethod.pickup),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFCF7EF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isPickup
                      ? const Color(0xFFE95700)
                      : const Color(0xFFE8E0D6),
                  width: isPickup ? 1.4 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Pick from Warehouse',
                          style: AppTypography.inter(
                            fontSize: 14,
                            fontWeight:
                                isPickup ? FontWeight.w800 : FontWeight.w600,
                            color: const Color(0xFF1C1917),
                          ),
                        ),
                      ),
                      Icon(
                        isPickup
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        size: 22,
                        color: isPickup
                            ? const Color(0xFFE95700)
                            : const Color(0xFF78716C),
                      ),
                    ],
                  ),
                  if (isPickup) ...[
                    const SizedBox(height: 14),
                    if (checkoutCtrl.isLoadingPickup &&
                        checkoutCtrl.pickupLocation == null)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 18),
                        child: Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFDC5B0A),
                            ),
                          ),
                        ),
                      )
                    else if (checkoutCtrl.pickupLocation == null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Could not load pickup location.',
                            style: AppTypography.inter(
                              fontSize: 12,
                              color: const Color(0xFF6C5B46),
                            ),
                          ),
                          TextButton(
                            onPressed: onRetryPickup,
                            child: const Text('Retry'),
                          ),
                        ],
                      )
                    else ...[
                      if (checkoutCtrl.pickupLocation!.company.isNotEmpty) ...[
                        Text(
                          checkoutCtrl.pickupLocation!.company,
                          style: AppTypography.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF4A1C00),
                          ),
                        ),
                        const SizedBox(height: 3),
                      ],
                      Text(
                        checkoutCtrl.pickupLocation!.singleLine,
                        style: AppTypography.inter(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                          color: const Color(0xFF78716C),
                        ),
                      ),
                      if (checkoutCtrl
                          .pickupLocation!.hours.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Hours: ${checkoutCtrl.pickupLocation!.hours}',
                          style: AppTypography.inter(
                            fontSize: 10.5,
                            color: const Color(0xFF8B765D),
                          ),
                        ),
                      ],
                      if (checkoutCtrl.pickupLocation!.instructions
                          .trim()
                          .isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          checkoutCtrl.pickupLocation!.instructions,
                          style: AppTypography.inter(
                            fontSize: 10,
                            color: const Color(0xFF8B765D),
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Text(
                        'Collector details :',
                        style: AppTypography.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF4A1C00),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _CartInputField(
                        controller: nameController,
                        hint: 'Collector name',
                        icon: Icons.person_outline,
                        onChanged: (_) => onSyncPickupContact(),
                      ),
                      const SizedBox(height: 10),
                      _CartInputField(
                        controller: phoneController,
                        hint: 'Collector phone number',
                        keyboardType: TextInputType.phone,
                        icon: Icons.phone_outlined,
                        onChanged: (_) => onSyncPickupContact(),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // 2. Door Delivery Card
        Material(
          color: const Color(0xFFFCF7EF),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => onMethodChanged(FulfillmentMethod.delivery),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFCF7EF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDelivery
                      ? const Color(0xFFE95700)
                      : const Color(0xFFE8E0D6),
                  width: isDelivery ? 1.4 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Door Delivery',
                          style: AppTypography.inter(
                            fontSize: 14,
                            fontWeight:
                                isDelivery ? FontWeight.w800 : FontWeight.w600,
                            color: const Color(0xFF1C1917),
                          ),
                        ),
                      ),
                      Icon(
                        isDelivery
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        size: 22,
                        color: isDelivery
                            ? const Color(0xFFE95700)
                            : const Color(0xFF78716C),
                      ),
                    ],
                  ),
                  if (isDelivery) ...[
                    const SizedBox(height: 14),
                    Text(
                      'Address',
                      style: AppTypography.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1C1917),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (savedAddress != null) ...[
                      Builder(
                        builder: (_) {
                          final name = savedAddress.fullName.trim();
                          final phone = savedAddress.phone.trim();
                          final header = [
                            if (name.isNotEmpty) name,
                            if (phone.isNotEmpty) phone,
                          ].join(', ');
                          if (header.isEmpty) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              header,
                              style: AppTypography.inter(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF554D44),
                              ),
                            ),
                          );
                        },
                      ),
                      Text(
                        [
                          savedAddress.addressLine1,
                          savedAddress.city,
                          savedAddress.state,
                          savedAddress.postalCode,
                          savedAddress.country,
                        ].where((e) => e.trim().isNotEmpty).join(', '),
                        style: AppTypography.inter(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF78716C),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    ElevatedButton(
                      onPressed: onChangeAddressTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2255D4),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 8,
                        ),
                        elevation: 2,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        savedAddress == null
                            ? 'Set Delivery Location'
                            : 'Change Address',
                        style: AppTypography.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (savedAddress != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        'Based on your address, you are eligible for the below delivery options.',
                        style: AppTypography.inter(
                          fontSize: 11.5,
                          height: 1.3,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1C1917),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (checkoutCtrl.isQuoting)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 18),
                          child: Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFDC5B0A),
                              ),
                            ),
                          ),
                        )
                      else if (checkoutCtrl.quoteRates.isEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              checkoutCtrl.lastError ??
                                  'No rates available for this address.',
                              style: AppTypography.inter(
                                fontSize: 12,
                                color: const Color(0xFF6C5B46),
                              ),
                            ),
                            TextButton(
                              onPressed: onRetryQuote,
                              child: const Text('Retry'),
                            ),
                          ],
                        )
                      else
                        ...checkoutCtrl.quoteRates.map((rate) {
                          final isSelected =
                              checkoutCtrl.selectedRate?.serviceLevelCode ==
                                  rate.serviceLevelCode;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _CourierRateSubCard(
                              rate: rate,
                              isSelected: isSelected,
                              currency: checkoutCtrl.quoteCurrency,
                              onTap: () => checkoutCtrl.selectRate(rate),
                            ),
                          );
                        }),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CourierRateSubCard extends StatelessWidget {
  const _CourierRateSubCard({
    required this.rate,
    required this.isSelected,
    required this.currency,
    required this.onTap,
  });

  final ShippingRateModel rate;
  final bool isSelected;
  final String currency;
  final VoidCallback onTap;

  static String _formatPrice(num value) {
    if (value % 1 == 0) return value.toInt().toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? const Color(0xFFFFF0E4) : const Color(0xFFFFF7E8),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFE95700)
                  : const Color(0xFFE8E0D6),
              width: isSelected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rate.serviceLevelName.isEmpty
                          ? rate.serviceLevelCode
                          : rate.serviceLevelName,
                      style: AppTypography.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1C1917),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$currency ${_formatPrice(rate.rate)}',
                      style: AppTypography.inter(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? const Color(0xFFDC5B0A)
                            : const Color(0xFF78716C),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                size: 22,
                color: isSelected
                    ? const Color(0xFFE95700)
                    : const Color(0xFF78716C),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartInputField extends StatefulWidget {
  const _CartInputField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.icon,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final IconData? icon;
  final ValueChanged<String>? onChanged;

  @override
  State<_CartInputField> createState() => _CartInputFieldState();
}

class _CartInputFieldState extends State<_CartInputField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasFocus = _focusNode.hasFocus;

    return TextField(
      controller: widget.controller,
      focusNode: _focusNode,
      keyboardType: widget.keyboardType,
      textInputAction: TextInputAction.done,
      onEditingComplete: () => _focusNode.unfocus(),
      onSubmitted: (_) => _focusNode.unfocus(),
      onTapOutside: (_) => _focusNode.unfocus(),
      onChanged: widget.onChanged,
      style: AppTypography.inter(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF4A1C00),
      ),
      decoration: InputDecoration(
        isDense: true,
        hintText: widget.hint,
        hintStyle: AppTypography.inter(
          fontSize: 11,
          color: const Color(0xFFB7AAA0),
        ),
        prefixIcon: widget.icon == null
            ? null
            : Icon(widget.icon, size: 16, color: const Color(0xFF8B765D)),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 32,
          minHeight: 32,
        ),
        suffixIcon: hasFocus
            ? null
            : InkWell(
                onTap: () => _focusNode.requestFocus(),
                borderRadius: BorderRadius.circular(16),
                child: const SizedBox(
                  width: 32,
                  height: 32,
                  child: Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: Color(0xFF8B765D),
                  ),
                ),
              ),
        suffixIconConstraints: const BoxConstraints(
          minWidth: 32,
          minHeight: 32,
        ),
        filled: true,
        fillColor: const Color(0xFFFFF7E8),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 11,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE8E0D6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE95700), width: 1.4),
        ),
      ),
    );
  }
}

class _BillSummarySection extends StatelessWidget {
  const _BillSummarySection({
    required this.cart,
    required this.deliveryCharge,
    required this.isPickup,
  });
  final CartModel cart;
  final double deliveryCharge;
  final bool isPickup;

  static String _formatPrice(num value) {
    if (value % 1 == 0) return value.toInt().toStringAsFixed(2);
    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = (cart.subtotal ?? cart.totalAmount).toDouble();
    final tax = (cart.taxAmount ?? 0).toDouble();
    final vatPct = (cart.vatPercent ?? 0).toDouble();
    final delivery = isPickup ? 0.0 : deliveryCharge;
    // Server cart totalAmount is subtotal + VAT; add delivery at preview time.
    final productsWithVat = tax > 0
        ? subtotal + tax
        : cart.totalAmount.toDouble();
    final toPay = productsWithVat + delivery;

    Widget row(String left, String right, {bool bold = false}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              left,
              style: AppTypography.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF1D1B19),
              ),
            ),
            Text(
              right,
              style: AppTypography.inter(
                fontSize: 14,
                fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
                color: const Color(0xFF1D1B19),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Color(0xFFFCF7EF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8E0D6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bill Summary',
            style: AppTypography.lora(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1C1917),
            ),
          ),
          const SizedBox(height: 12),
          row('Subtotal', '${cart.currency} ${_formatPrice(subtotal)}'),
          if (tax > 0)
            row(
              vatPct > 0 ? 'VAT (${_formatPrice(vatPct)}%)' : 'VAT',
              '${cart.currency} ${_formatPrice(tax)}',
            ),
          row(
            isPickup ? 'Pickup (collect in store)' : 'Delivery charge',
            '${cart.currency} ${_formatPrice(delivery)}',
          ),
          const Divider(height: 16, color: Color(0x1A6B4A2B)),
          row('To pay', '${cart.currency} ${_formatPrice(toPay)}', bold: true),
          Text(
            'Inclusive of all taxes and charges',
            style: AppTypography.inter(
              fontSize: 8,
              fontWeight: FontWeight.w400,
              color: Color(0XFF1D1B19),
            ),
          ),
        ],
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
        child: GestureDetector(
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
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFFFCF7EF),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

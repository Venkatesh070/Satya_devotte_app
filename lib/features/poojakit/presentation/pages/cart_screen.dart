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
import 'package:satya_devotte_app/features/poojakit/data/models/pickup_location_model.dart';
import 'package:satya_devotte_app/features/poojakit/data/models/shipping_quote_model.dart';
import 'package:satya_devotte_app/features/poojakit/state/cart_controller.dart';
import 'package:satya_devotte_app/features/poojakit/state/poojakit_checkout_controller.dart';
import 'package:satya_devotte_app/shared/widgets/chakra_loading_indicator.dart';
import 'package:satya_devotte_app/features/poojakit/presentation/pages/poojakit_page.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    final c = Get.find<CartController>();
    c.fetchCart();
    final checkout = Get.find<PoojaKitCheckoutController>();
    if (checkout.isPickup && checkout.pickupLocation == null) {
      final cart = Get.find<CartController>();
      final items = cart.cart?.items
              .map(
                (i) => {
                  'productId': i.product.id,
                  'quantity': i.quantity,
                },
              )
              .toList() ??
          [];
      if (items.isNotEmpty) {
        checkout.fetchPickupLocation(cartItems: items);
      } else {
        checkout.fetchPickupLocation();
      }
    } else if (checkout.isDelivery &&
        checkout.shippingAddress != null &&
        checkout.quoteRates.isEmpty) {
      final items = c.cart?.items
              .map(
                (i) => {
                  'productId': i.product.id,
                  'quantity': i.quantity,
                },
              )
              .toList() ??
          [];
      checkout.fetchShippingQuote(
        checkout.shippingAddress!,
        items: items.isEmpty ? null : items,
      );
    }
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
              child: Obx(() {
                if (c.isLoading && c.cart == null) {
                  return const SizedBox.shrink();
                }

                final cart = c.cart;
                if (cart == null || cart.isEmpty) {
                  return const _EmptyCart();
                }

                return SingleChildScrollView(
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
                      Obx(
                        () => _FulfillmentMethodSection(
                          method: checkoutCtrl.fulfillmentMethod,
                          onChanged: (method) {
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
                        ),
                      ),
                      const SizedBox(height: 12),
                      Obx(() {
                        if (checkoutCtrl.isPickup) {
                          return _PickupLocationSection(
                            location: checkoutCtrl.pickupLocation,
                            isLoading: checkoutCtrl.isLoadingPickup,
                            onRetry: () {
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
                            onEditContact: () => Get.toNamed(
                              AppRoutes.poojaKitCheckout,
                              arguments: null,
                            ),
                            contactName:
                                checkoutCtrl.shippingAddress?.fullName,
                            contactPhone:
                                checkoutCtrl.shippingAddress?.phone,
                          );
                        }
                        return Column(
                          children: [
                            _DeliveryLocationSection(
                              address: checkoutCtrl.shippingAddress,
                              onChangeTap: () => Get.toNamed(
                                AppRoutes.poojaKitCheckout,
                                arguments: null,
                              ),
                            ),
                            if (checkoutCtrl.shippingAddress != null) ...[
                              const SizedBox(height: 12),
                              _CourierRatesSection(
                                rates: checkoutCtrl.quoteRates,
                                selected: checkoutCtrl.selectedRate,
                                currency: checkoutCtrl.quoteCurrency,
                                isLoading: checkoutCtrl.isQuoting,
                                error: checkoutCtrl.lastError,
                                onSelect: checkoutCtrl.selectRate,
                                onRetry: () {
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
                              ),
                            ],
                          ],
                        );
                      }),
                      const SizedBox(height: 12),
                      Obx(
                        () => _BillSummarySection(
                          cart: cart,
                          deliveryCharge: checkoutCtrl.previewDeliveryCharge,
                          isPickup: checkoutCtrl.isPickup,
                        ),
                      ),
                      const SizedBox(height: 86),
                    ],
                  ),
                );
              }),
            ),
            Obx(() {
              final cart = c.cart;
              if (cart == null || cart.isEmpty) {
                return _GradientCtaBar(
                  enabled: true,
                  label: 'Go to shopping',
                  onTap: () => Get.off(() => const PoojaKitPage()),
                );
              }
              return _GradientCtaBar(
                enabled: true,
                label: 'Proceed to Payment',
                onTap: () => _handleProceedToPayment(c, checkoutCtrl),
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
    if (checkoutCtrl.isPickup) {
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
      final contact = checkoutCtrl.shippingAddress;
      if (contact == null ||
          contact.fullName.trim().isEmpty ||
          contact.phone.trim().isEmpty) {
        Get.toNamed(AppRoutes.poojaKitCheckout, arguments: null);
        return;
      }
    } else {
      final address = checkoutCtrl.shippingAddress;
      if (address == null) {
        Get.toNamed(AppRoutes.poojaKitCheckout, arguments: null);
        return;
      }
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

    final init = await checkoutCtrl.initiateCartCheckout();
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

class _FulfillmentMethodSection extends StatelessWidget {
  const _FulfillmentMethodSection({
    required this.method,
    required this.onChanged,
  });

  final FulfillmentMethod method;
  final ValueChanged<FulfillmentMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFCF7EF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8E0D6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fulfilment method',
            style: AppTypography.lora(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1C1917),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MethodChip(
                  label: 'Pickup',
                  selected: method == FulfillmentMethod.pickup,
                  onTap: () => onChanged(FulfillmentMethod.pickup),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MethodChip(
                  label: 'Delivery',
                  selected: method == FulfillmentMethod.delivery,
                  onTap: () => onChanged(FulfillmentMethod.delivery),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MethodChip extends StatelessWidget {
  const _MethodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFFFF0E4) : const Color(0xFFFFF7E8),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? const Color(0xFFE95700)
                  : const Color(0xFFE8E0D6),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Text(
            label,
            style: AppTypography.inter(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: selected
                  ? const Color(0xFFE95700)
                  : const Color(0xFF6C5B46),
            ),
          ),
        ),
      ),
    );
  }
}

class _PickupLocationSection extends StatelessWidget {
  const _PickupLocationSection({
    required this.location,
    required this.isLoading,
    required this.onRetry,
    required this.onEditContact,
    this.contactName,
    this.contactPhone,
  });

  final PickupLocationModel? location;
  final bool isLoading;
  final VoidCallback onRetry;
  final VoidCallback onEditContact;
  final String? contactName;
  final String? contactPhone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFCF7EF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8E0D6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pickup location',
            style: AppTypography.lora(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1C1917),
            ),
          ),
          const SizedBox(height: 10),
          if (isLoading && location == null)
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
          else if (location == null)
            Column(
              children: [
                Text(
                  'Could not load pickup location.',
                  style: AppTypography.inter(
                    fontSize: 12,
                    color: const Color(0xFF6C5B46),
                  ),
                ),
                TextButton(onPressed: onRetry, child: const Text('Retry')),
              ],
            )
          else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7E8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE8E0D6)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location!.singleLine,
                    style: AppTypography.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF6C5B46),
                    ),
                  ),
                  if (location!.hours.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Hours: ${location!.hours}',
                      style: AppTypography.inter(
                        fontSize: 10,
                        color: const Color(0xFF8B765D),
                      ),
                    ),
                  ],
                  if (location!.instructions.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      location!.instructions,
                      style: AppTypography.inter(
                        fontSize: 10,
                        color: const Color(0xFF8B765D),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Collector: ${(contactName ?? '').trim().isEmpty ? 'Not set' : contactName}'
              '${(contactPhone ?? '').trim().isEmpty ? '' : ' · $contactPhone'}',
              style: AppTypography.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6C5B46),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.center,
              child: OutlinedButton(
                onPressed: onEditContact,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE95700),
                  side: const BorderSide(color: Color(0xFFE95700)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Set name & phone',
                  style: AppTypography.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFE95700),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CourierRatesSection extends StatelessWidget {
  const _CourierRatesSection({
    required this.rates,
    required this.selected,
    required this.currency,
    required this.isLoading,
    required this.onSelect,
    required this.onRetry,
    this.error,
  });

  final List<ShippingRateModel> rates;
  final ShippingRateModel? selected;
  final String currency;
  final bool isLoading;
  final String? error;
  final ValueChanged<ShippingRateModel> onSelect;
  final VoidCallback onRetry;

  static String _formatPrice(num value) {
    if (value % 1 == 0) return value.toInt().toStringAsFixed(2);
    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFCF7EF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8E0D6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'The Courier Guy',
            style: AppTypography.lora(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1C1917),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose a door-to-door service level',
            style: AppTypography.inter(
              fontSize: 10,
              color: const Color(0xFF6C5B46),
            ),
          ),
          const SizedBox(height: 12),
          if (isLoading)
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
          else if (rates.isEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  error ?? 'No rates available for this address.',
                  style: AppTypography.inter(
                    fontSize: 12,
                    color: const Color(0xFF6C5B46),
                  ),
                ),
                TextButton(onPressed: onRetry, child: const Text('Retry')),
              ],
            )
          else
            ...rates.map((rate) {
              final isSelected =
                  selected?.serviceLevelCode == rate.serviceLevelCode;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: isSelected
                      ? const Color(0xFFFFF0E4)
                      : const Color(0xFFFFF7E8),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => onSelect(rate),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFE95700)
                              : const Color(0xFFE8E0D6),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            size: 18,
                            color: isSelected
                                ? const Color(0xFFE95700)
                                : const Color(0xFF9B958E),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  rate.serviceLevelName.isEmpty
                                      ? rate.serviceLevelCode
                                      : rate.serviceLevelName,
                                  style: AppTypography.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1C1917),
                                  ),
                                ),
                                if (rate.description.trim().isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    rate.description,
                                    style: AppTypography.inter(
                                      fontSize: 10,
                                      color: const Color(0xFF6C5B46),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Text(
                            '$currency ${_formatPrice(rate.rate)}',
                            style: AppTypography.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFDC5B0A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _DeliveryLocationSection extends StatelessWidget {
  const _DeliveryLocationSection({
    required this.onChangeTap,
    required this.address,
  });

  final VoidCallback onChangeTap;
  final AddressModel? address;

  @override
  Widget build(BuildContext context) {
    final savedAddress = address;
    final addressText = savedAddress == null
        ? 'No location set'
        : [
            savedAddress.addressLine1,
            savedAddress.city,
            savedAddress.postalCode,
            savedAddress.country,
          ].where((e) => e.trim().isNotEmpty).join(', ');

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
            'Delivery Location',
            style: AppTypography.lora(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1C1917),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7E8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8E0D6)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF183EA4), Color(0xFFE35600)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ).createShader(bounds),
                  blendMode: BlendMode.srcIn,
                  child: Icon(
                    Icons.location_on_outlined,
                    size: 18,
                    color: Color(0xFF6C5B46),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    addressText,
                    style: AppTypography.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF6C5B46),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.center,
            child: OutlinedButton(
              onPressed: onChangeTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE95700),
                side: const BorderSide(color: Color(0xFFE95700)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF183EA4), Color(0xFFE35600)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ).createShader(bounds),
                blendMode: BlendMode.srcIn,
                child: Text(
                  address == null
                      ? 'Set Delivery Location'
                      : 'Change Delivery Location',
                  style: AppTypography.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
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

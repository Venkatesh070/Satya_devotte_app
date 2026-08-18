import 'package:flutter/material.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/cms/data/models/admin_order_models.dart';
import 'package:satya_devotte_app/features/cms/data/models/admin_order_request_models.dart';

/// User selection for return / replace: product id → quantity.
typedef OrderLineSelectionMap = Map<String, int>;

List<Map<String, dynamic>> orderLineSelectionToPayload(
  OrderLineSelectionMap selection,
) {
  return selection.entries
      .where((e) => e.value > 0)
      .map((e) => {'productId': e.key, 'quantity': e.value})
      .toList(growable: false);
}

OrderLineSelectionMap defaultOrderLineSelection(AdminOrder order) {
  if (order.items.length == 1) {
    final item = order.items.first;
    final id = item.productId.trim();
    if (id.isNotEmpty) {
      return {id: item.qty > 0 ? item.qty : 1};
    }
  }
  return {};
}

class OrderLineItemPicker extends StatefulWidget {
  const OrderLineItemPicker({
    super.key,
    required this.order,
    required this.selection,
    required this.onChanged,
    this.title = 'Select item(s)',
    this.subtitle,
    this.forDarkBackground = false,
  });

  final AdminOrder order;
  final OrderLineSelectionMap selection;
  final ValueChanged<OrderLineSelectionMap> onChanged;
  final String title;
  final String? subtitle;
  final bool forDarkBackground;

  @override
  State<OrderLineItemPicker> createState() => _OrderLineItemPickerState();
}

class _OrderLineItemPickerState extends State<OrderLineItemPicker> {
  late OrderLineSelectionMap _selection;

  @override
  void initState() {
    super.initState();
    _selection = Map<String, int>.from(widget.selection);
    if (_selection.isEmpty) {
      final defaults = defaultOrderLineSelection(widget.order);
      if (defaults.isNotEmpty) {
        _selection = defaults;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onChanged(Map<String, int>.from(_selection));
        });
      }
    }
  }

  void _toggle(OrderLineItem item, bool selected) {
    final id = item.productId.trim();
    if (id.isEmpty) return;
    setState(() {
      if (selected) {
        _selection[id] = item.qty > 0 ? item.qty : 1;
      } else {
        _selection.remove(id);
      }
    });
    widget.onChanged(Map<String, int>.from(_selection));
  }

  void _setQty(OrderLineItem item, int qty) {
    final id = item.productId.trim();
    if (id.isEmpty) return;
    final maxQty = item.qty > 0 ? item.qty : 1;
    final next = qty.clamp(1, maxQty);
    setState(() => _selection[id] = next);
    widget.onChanged(Map<String, int>.from(_selection));
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.order.items;
    if (items.isEmpty) {
      return Text(
        'No items found on this order.',
        style: AppTypography.inter(fontSize: 12, color: const Color(0xFF78716C)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: AppTypography.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: widget.forDarkBackground
                ? const Color(0xFFFCF7EF)
                : const Color(0xFF44403C),
          ),
        ),
        if (widget.subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.subtitle!,
            style: AppTypography.inter(
              fontSize: 12,
              height: 1.35,
              color: widget.forDarkBackground
                  ? Colors.white70
                  : const Color(0xFF78716C),
            ),
          ),
        ],
        const SizedBox(height: 10),
        ...items.map((item) {
          final id = item.productId.trim();
          final maxQty = item.qty > 0 ? item.qty : 1;
          final selected = _selection.containsKey(id);
          final qty = _selection[id] ?? maxQty;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: id.isEmpty ? null : () => _toggle(item, !selected),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFFE95700)
                          : const Color(0xFFE7D5BC),
                    ),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: selected,
                        onChanged: id.isEmpty
                            ? null
                            : (v) => _toggle(item, v == true),
                        activeColor: const Color(0xFFE95700),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      if (item.image.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            item.image,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox(
                              width: 44,
                              height: 44,
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5EFE6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.inventory_2_outlined,
                            size: 20,
                            color: Color(0xFF9E8E7E),
                          ),
                        ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title.isEmpty ? 'Item' : item.title,
                              style: AppTypography.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1C1917),
                              ),
                            ),
                            Text(
                              'Qty ordered: $maxQty',
                              style: AppTypography.inter(
                                fontSize: 11,
                                color: const Color(0xFF78716C),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (selected && maxQty > 1)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: qty > 1
                                  ? () => _setQty(item, qty - 1)
                                  : null,
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text(
                              '$qty',
                              style: AppTypography.inter(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: qty < maxQty
                                  ? () => _setQty(item, qty + 1)
                                  : null,
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

String formatAffectedItemsSummary(
  List<OrderAffectedItem> items, {
  String currency = 'ZAR',
}) {
  if (items.isEmpty) return '';
  final parts = items
      .map((item) {
        final title = item.title.isEmpty ? 'Item' : item.title;
        return item.quantity > 1 ? '$title ×${item.quantity}' : title;
      })
      .toList();
  final total = items.fold<double>(0, (sum, item) => sum + item.lineTotal);
  final amount = total > 0 ? ' (${currency.trim()} ${total.toStringAsFixed(2)})' : '';
  return '${parts.join(', ')}$amount';
}

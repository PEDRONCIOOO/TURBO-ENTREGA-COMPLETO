import 'package:flutter/material.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';

class DeliverItemCardWidget extends StatefulWidget {
  final String image;
  final String itemName;
  final String description;
  final bool isDeliverItem;
  const DeliverItemCardWidget({super.key, required this.image, required this.itemName, required this.description, this.isDeliverItem = false});

  @override
  State<DeliverItemCardWidget> createState() => _DeliverItemCardWidgetState();
}

class _DeliverItemCardWidgetState extends State<DeliverItemCardWidget> {
  bool _isHovered = false;

  static IconData _getFallbackIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('document') || lower.contains('doc')) return Icons.description_outlined;
    if (lower.contains('caixa') || lower.contains('box') || lower.contains('embalage')) return Icons.inventory_2_outlined;
    if (lower.contains('presente') || lower.contains('gift')) return Icons.card_giftcard_outlined;
    if (lower.contains('fragil') || lower.contains('fragei')) return Icons.warning_amber_rounded;
    if (lower.contains('equipamento') || lower.contains('eletron')) return Icons.devices_outlined;
    if (lower.contains('comida') || lower.contains('food') || lower.contains('marmita')) return Icons.restaurant_outlined;
    if (lower.contains('roupa') || lower.contains('cloth')) return Icons.checkroom_outlined;
    if (lower.contains('flor') || lower.contains('flower')) return Icons.local_florist_outlined;
    if (lower.contains('chave') || lower.contains('key')) return Icons.vpn_key_outlined;
    if (lower.contains('remedio') || lower.contains('farmacia') || lower.contains('medic')) return Icons.medical_services_outlined;
    return Icons.local_shipping_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        transform: Matrix4.translationValues(0, _isHovered ? -2 : 0, 0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _isHovered
                ? primaryColor.withValues(alpha: 0.2)
                : widget.isDeliverItem
                    ? primaryColor.withValues(alpha: 0.15)
                    : primaryColor.withValues(alpha: 0.06),
          ),
          boxShadow: Theme.of(context).brightness == Brightness.dark
              ? null
              : [
                  BoxShadow(
                    color: _isHovered
                        ? primaryColor.withValues(alpha: 0.12)
                        : Colors.black.withValues(alpha: 0.04),
                    blurRadius: _isHovered ? 20 : 12,
                    offset: Offset(0, _isHovered ? 6 : 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: Theme.of(context).brightness == Brightness.dark
                      ? [
                          primaryColor.withValues(alpha: 0.25),
                          primaryColor.withValues(alpha: 0.15),
                        ]
                      : [
                          primaryColor.withValues(alpha: 0.12),
                          primaryColor.withValues(alpha: 0.06),
                        ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: widget.image.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Theme.of(context).brightness == Brightness.dark
                          ? ColorFiltered(
                              colorFilter: ColorFilter.mode(primaryColor.withValues(alpha: 0.8), BlendMode.srcATop),
                              child: CustomImage(image: widget.image, height: 44, width: 44, fit: BoxFit.contain),
                            )
                          : CustomImage(image: widget.image, height: 44, width: 44, fit: BoxFit.contain),
                    )
                  : Icon(
                      _getFallbackIcon(widget.itemName),
                      size: 22,
                      color: primaryColor,
                    ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.itemName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: robotoMedium.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              widget.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: robotoRegular.copyWith(
                color: (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black).withValues(alpha: 0.45),
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

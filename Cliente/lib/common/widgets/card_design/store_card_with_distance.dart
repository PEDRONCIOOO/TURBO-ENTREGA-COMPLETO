import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/features/store/screens/store_screen.dart';

class StoreCardWithDistance extends StatelessWidget {
  final Store store;
  const StoreCardWithDistance({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Get.toNamed(
          RouteHelper.getStoreRoute(id: store.id, page: 'store'),
          arguments: StoreScreen(store: store, fromModule: false),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo da loja
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: CustomImage(
                  image: store.logoFullUrl ?? '',
                  height: 50, width: 50,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // InformaÃ§Ãµes da loja
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          store.name ?? '',
                          style: robotoMedium.copyWith(fontSize: 15),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.favorite_border,
                        color: Theme.of(context).disabledColor,
                        size: 22,
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  
                  Row(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.star, size: 14, color: Theme.of(context).primaryColor),
                          const SizedBox(width: 2),
                          Text(
                            store.avgRating?.toStringAsFixed(1) ?? '0.0',
                            style: robotoRegular.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                      Text(
                        ' â€¢ ${store.name ?? ''} â€¢ ${(store.distance! / 1000).toStringAsFixed(1)} km',
                        style: robotoRegular.copyWith(
                          fontSize: 12,
                          color: Theme.of(context).disabledColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),

                  Row(
                    children: [
                      Text(
                        '${store.deliveryTime} min',
                        style: robotoRegular.copyWith(
                          fontSize: 12,
                          color: Theme.of(context).disabledColor,
                        ),
                      ),
                      Text(
                        ' â€¢ R\$ ${store.minimumShippingCharge?.toStringAsFixed(2)}',
                        style: robotoRegular.copyWith(
                          fontSize: 12,
                          color: Theme.of(context).disabledColor,
                        ),
                      ),
                    ],
                  ),

                  if (store.discount != null && store.discount?.discount != null)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.local_offer,
                            color: Colors.green[700],
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Cupom de R\$ ${store.discount?.discount?.toStringAsFixed(2)} disponÃ­vel',
                            style: robotoMedium.copyWith(
                              fontSize: 12,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

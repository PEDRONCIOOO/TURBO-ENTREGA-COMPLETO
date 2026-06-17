import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/category/controllers/category_controller.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/favourite/controllers/favourite_controller.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/item_view.dart';
import 'package:sixam_mart/common/widgets/menu_drawer.dart';
import 'package:sixam_mart/common/widgets/web_menu_bar.dart';

import '../widgets/bottom_cart_widget.dart';

class StoreScreen extends StatefulWidget {
  final Store? store;
  final bool fromModule;
  final String slug;
  const StoreScreen({super.key, required this.store, required this.fromModule, this.slug = ''});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    initDataCall();
  }

  @override
  void dispose() {
    super.dispose();

    scrollController.dispose();
  }

  Future<void> initDataCall() async {
    if(Get.find<StoreController>().isSearching) {
      Get.find<StoreController>().changeSearchStatus(isUpdate: false);
    }
    Get.find<StoreController>().hideAnimation();
    await Get.find<StoreController>().getStoreDetails(Store(id: widget.store!.id), widget.fromModule, slug: widget.slug).then((value) {
      Get.find<StoreController>().showButtonAnimation();
    });
    if(Get.find<CategoryController>().categoryList == null) {
      Get.find<CategoryController>().getCategoryList(true);
    }
    Get.find<StoreController>().getStoreBannerList(widget.store!.id ?? Get.find<StoreController>().store!.id);
    Get.find<StoreController>().getRestaurantRecommendedItemList(widget.store!.id ?? Get.find<StoreController>().store!.id, false);
    Get.find<StoreController>().getStoreItemList(widget.store!.id ?? Get.find<StoreController>().store!.id, 1, 'all', true);

    scrollController.addListener(() {
      if(scrollController.position.userScrollDirection == ScrollDirection.reverse){
        if(Get.find<StoreController>().showFavButton){
          Get.find<StoreController>().changeFavVisibility();
          Get.find<StoreController>().hideAnimation();
        }
      }else{
        if(!Get.find<StoreController>().showFavButton){
          Get.find<StoreController>().changeFavVisibility();
          Get.find<StoreController>().showButtonAnimation();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ResponsiveHelper.isDesktop(context) ? const WebMenuBar() : null,
      endDrawer: const MenuDrawer(),endDrawerEnableOpenDragGesture: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: GetBuilder<StoreController>(builder: (storeController) {
        return GetBuilder<CategoryController>(builder: (categoryController) {
          Store? store;
          if(storeController.store != null && storeController.store!.name != null && categoryController.categoryList != null) {
            store = storeController.store;
            storeController.setCategoryList();
          }

          return (storeController.store != null && storeController.store!.name != null && categoryController.categoryList != null) ? CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            controller: scrollController,
            slivers: [
              // Banner e logo
              SliverToBoxAdapter(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Banner
                    Container(
                      height: 180,
                      width: double.infinity,
                      padding: EdgeInsets.zero,
                      margin: EdgeInsets.zero,
                      child: Image.network(
                        store!.coverPhotoFullUrl ?? '',
                        fit: BoxFit.cover,
                      ),
                    ),
                    
                    // BotÃµes de navegaÃ§Ã£o
                    Positioned(
                      top: 10,
                      left: 10,
                      child: InkWell(
                        onTap: () => Get.back(),
                        child: Container(
                          height: 40, width: 40,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withOpacity(0.6)),
                          alignment: Alignment.center,
                          child: Icon(Icons.arrow_back, color: Colors.white),
                        ),
                      ),
                    ),
                    
                    // BotÃ£o de favorito
                    Positioned(
                      top: 10,
                      right: 60,
                      child: GetBuilder<FavouriteController>(builder: (favouriteController) {
                        bool isWished = favouriteController.wishStoreIdList.contains(store!.id);
                        return InkWell(
                          onTap: () {
                            if(AuthHelper.isLoggedIn()) {
                              isWished ? favouriteController.removeFromFavouriteList(store!.id, true)
                                  : favouriteController.addToFavouriteList(null, store?.id, true);
                            } else {
                              showCustomSnackBar('you_are_not_logged_in'.tr);
                            }
                          },
                          child: Container(
                            height: 40, width: 40,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withOpacity(0.6)),
                            alignment: Alignment.center,
                            child: Icon(
                              isWished ? Icons.favorite : Icons.favorite_border,
                              color: isWished ? Theme.of(context).primaryColor : Colors.white,
                              size: 20,
                            ),
                          ),
                        );
                      }),
                    ),
                    
                    // BotÃ£o de pesquisa
                    Positioned(
                      top: 10,
                      right: 10,
                      child: InkWell(
                        onTap: () {
                          // Implementar pesquisa
                        },
                        child: Container(
                          height: 40, width: 40,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withOpacity(0.6)),
                          alignment: Alignment.center,
                          child: Icon(Icons.search, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                    
                    // Logo da loja (posicionada por cima do banner)
                    Positioned(
                      bottom: -30,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: PhysicalModel(
                          color: Colors.transparent,
                          elevation: 12,
                          shadowColor: Colors.black,
                          borderRadius: BorderRadius.circular(50),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              color: Colors.white,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(50),
                              child: Image.network(
                                store!.logoFullUrl ?? '',
                                height: 80,
                                width: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // CabeÃ§alho da loja (estilo iFood)
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  width: double.infinity,
                  child: Column(
                    children: [
                      // InformaÃ§Ãµes da loja
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 35, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Nome da loja
                            Text(
                              store!.name!,
                              style: robotoMedium.copyWith(fontSize: 24),
                              textAlign: TextAlign.center,
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Linha divisÃ³ria
                            Container(
                              height: 1,
                              color: Colors.grey.withOpacity(0.2),
                            ),
                            
                            // AvaliaÃ§Ã£o
                            InkWell(
                              onTap: () {
                                // AÃ§Ã£o ao clicar na avaliaÃ§Ã£o
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                child: Row(
                                  children: [
                                    Icon(Icons.star, color: Colors.black, size: 20),
                                    const SizedBox(width: 5),
                                    Text(
                                      '${store.avgRating != null ? store.avgRating!.toStringAsFixed(1) : '0.0'} (${store.ratingCount ?? '0'} ${'ratings'.tr})',
                                      style: robotoRegular.copyWith(fontSize: 16),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      'â€¢',
                                      style: robotoRegular.copyWith(fontSize: 16, color: Colors.grey),
                                    ),
                                    const SizedBox(width: 5),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.verified, color: Colors.red, size: 16),
                                          const SizedBox(width: 3),
                                          Text(
                                            'Super',
                                            style: robotoMedium.copyWith(
                                              fontSize: 14, 
                                              color: Colors.red
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Spacer(),
                                    Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                                  ],
                                ),
                              ),
                            ),
                            
                            // Linha divisÃ³ria
                            Container(
                              height: 1,
                              color: Colors.grey.withOpacity(0.2),
                            ),
                            
                            // InformaÃ§Ãµes de entrega
                            InkWell(
                              onTap: () {
                                // AÃ§Ã£o ao clicar nas informaÃ§Ãµes de entrega
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                child: Row(
                                  children: [
                                    Text(
                                      'entrega'.tr,
                                      style: robotoMedium.copyWith(fontSize: 16),
                                    ),
                                    const SizedBox(width: 10),
                                    Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
                                    const Spacer(),
                                    Text(
                                      'hoje'.tr + ', ' + (store.deliveryTime ?? '30-40 min') + ' â€¢ ' + PriceConverter.convertPrice(store.minimumOrder ?? 0),
                                      style: robotoRegular.copyWith(fontSize: 14),
                                    ),
                                    const SizedBox(width: 5),
                                    Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                                  ],
                                ),
                              ),
                            ),
                            
                            // Linha divisÃ³ria
                            Container(
                              height: 8,
                              color: Colors.grey.withOpacity(0.1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Barra de categorias horizontal
              SliverToBoxAdapter(
                child: Container(
                  height: 60,
                  margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                  child: storeController.categoryList != null ? ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: storeController.categoryList!.length,
                    padding: const EdgeInsets.only(left: Dimensions.paddingSizeSmall),
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      return InkWell(
                        onTap: () {
                          storeController.setCategoryIndex(index, itemSearching: storeController.isSearching);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
                          margin: const EdgeInsets.only(right: Dimensions.paddingSizeSmall, bottom: Dimensions.paddingSizeSmall, top: Dimensions.paddingSizeSmall),
                          decoration: BoxDecoration(
                            color: index == storeController.categoryIndex ? Theme.of(context).primaryColor : Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                            boxShadow: [BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1, blurRadius: 3,
                            )],
                          ),
                          child: Center(
                            child: Text(
                              storeController.categoryList![index].name!,
                              style: index == storeController.categoryIndex
                                  ? robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Colors.white)
                                  : robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      );
                    },
                  ) : const SizedBox(),
                ),
              ),
              
              // SeÃ§Ã£o de destaques
              if (storeController.recommendedItemModel != null && storeController.recommendedItemModel!.items!.isNotEmpty) 
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'destaques'.tr,
                          style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge),
                        ),
                        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                        
                        SizedBox(
                          height: 200,
                          child: ListView.builder(
                            shrinkWrap: true,
                            scrollDirection: Axis.horizontal,
                            itemCount: storeController.recommendedItemModel!.items!.length,
                            physics: const BouncingScrollPhysics(),
                            padding: EdgeInsets.zero,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(right: Dimensions.paddingSizeSmall, bottom: Dimensions.paddingSizeSmall),
                                child: Container(
                                  width: 150,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                    boxShadow: [BoxShadow(
                                      color: Colors.grey.withOpacity(0.2),
                                      spreadRadius: 1, blurRadius: 5,
                                    )],
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      Get.find<ItemController>().navigateToItemPage(
                                        storeController.recommendedItemModel!.items![index], context, inStore: true,
                                      );
                                    },
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius: const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusSmall)),
                                              child: CustomImage(
                                                image: '${storeController.recommendedItemModel!.items![index].imageFullUrl}',
                                                height: 100, width: 150, fit: BoxFit.cover,
                                              ),
                                            ),
                                            
                                            storeController.recommendedItemModel!.items![index].discount! > 0 ? Positioned(
                                              top: 10, right: 10,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context).primaryColor,
                                                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                                ),
                                                child: Text(
                                                  '${storeController.recommendedItemModel!.items![index].discount}%',
                                                  style: robotoMedium.copyWith(
                                                    color: Colors.white, fontSize: Dimensions.fontSizeExtraSmall,
                                                  ),
                                                ),
                                              ),
                                            ) : const SizedBox(),
                                          ],
                                        ),
                                        
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  storeController.recommendedItemModel!.items![index].name!,
                                                  style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
                                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 2),
                                                
                                                Text(
                                                  PriceConverter.convertPrice(
                                                    storeController.recommendedItemModel!.items![index].price,
                                                    discount: storeController.recommendedItemModel!.items![index].discount,
                                                    discountType: storeController.recommendedItemModel!.items![index].discountType,
                                                  ),
                                                  style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).primaryColor),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              // Lista de produtos
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                  child: storeController.isSearching
                  ? ItemsView(
                    isStore: false, 
                    items: storeController.storeSearchItemModel?.items,
                    stores: null,
                    noDataText: 'no_item_found'.tr,
                    padding: EdgeInsets.zero,
                  )
                  : (storeController.categoryList!.isNotEmpty && storeController.storeItemModel != null) ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                        child: Text(
                          storeController.categoryList![storeController.categoryIndex].name!,
                          style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge),
                        ),
                      ),
                      
                      ItemsView(
                        isStore: false, 
                        items: storeController.storeItemModel!.items,
                        stores: null,
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ) : const SizedBox(),
                ),
              ),
            ],
          ) : const Center(child: CircularProgressIndicator());
        });
      }),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/common/widgets/custom_ink_well.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/title_widget.dart';
import 'package:sixam_mart/features/banner/controllers/banner_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/home/widgets/banner_view.dart';
import 'package:sixam_mart/features/home/widgets/views/featured_stores_vertical_view.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class ModuleView extends StatelessWidget {
  final SplashController splashController;
  const ModuleView({super.key, required this.splashController});

  void _showAllCategories(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              height: 4,
              width: 40,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Todas as categorias',
                style: robotoMedium.copyWith(fontSize: 20),
              ),
            ),
            Expanded(
              child: GridView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: (2 / 1),
                  crossAxisSpacing: Dimensions.paddingSizeSmall,
                  mainAxisSpacing: Dimensions.paddingSizeSmall,
                ),
                itemCount: splashController.moduleList!.length,
                itemBuilder: (context, index) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(Dimensions.radiusDefault),
                      color: Theme.of(context).cardColor,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 3)
                      ],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(Dimensions.radiusDefault),
                        color: Colors.grey[100],
                      ),
                      child: CustomInkWell(
                        onTap: () {
                          splashController.switchModule(index, true);
                          Navigator.pop(context);
                        },
                        radius: Dimensions.radiusDefault,
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Padding(
                                padding: const EdgeInsets.all(
                                    Dimensions.paddingSizeSmall),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      splashController
                                          .moduleList![index].moduleName!,
                                      style:
                                          robotoMedium.copyWith(fontSize: 16),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topRight:
                                      Radius.circular(Dimensions.radiusDefault),
                                  bottomRight:
                                      Radius.circular(Dimensions.radiusDefault),
                                ),
                                child: CustomImage(
                                  image:
                                      '${splashController.moduleList![index].iconFullUrl}',
                                  height: 50,
                                  width: 50,
                                  fit: BoxFit.contain,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          splashController.moduleList != null
              ? splashController.moduleList!.isNotEmpty
                  ? Column(
                      children: [
                        // 2 cards grandes em cima
                        GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: (2 / 1),
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          padding:
                              const EdgeInsets.all(Dimensions.paddingSizeSmall),
                          itemCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Theme.of(context)
                                    .cardColor
                                    .withOpacity(0.05),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey[200],
                                ),
                                child: CustomInkWell(
                                  onTap: () => splashController.switchModule(
                                      index, true),
                                  radius: 8,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                              left: 12, top: 16, right: 8),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Text(
                                                splashController
                                                    .moduleList![index]
                                                    .moduleName!,
                                                style: robotoRegular.copyWith(
                                                  fontSize: 14,
                                                  color: Theme.of(context)
                                                      .textTheme
                                                      .bodyLarge
                                                      ?.color
                                                      ?.withOpacity(0.8),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: ClipRRect(
                                          borderRadius: const BorderRadius.only(
                                            topRight: Radius.circular(8),
                                            bottomRight: Radius.circular(8),
                                          ),
                                          child: CustomImage(
                                            image:
                                                '${splashController.moduleList![index].iconFullUrl}',
                                            height: 50,
                                            width: 50,
                                            fit: BoxFit.contain,
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

                        const SizedBox(height: 8),

                        // 3 cards menores embaixo
                        Container(
                          padding: const EdgeInsets.only(
                            left: Dimensions.paddingSizeSmall,
                            right: Dimensions.paddingSizeSmall,
                            bottom: Dimensions.paddingSizeSmall,
                          ),
                          child: Row(
                            children: [
                              for (int i = 2;
                                  i < 5 &&
                                      i < splashController.moduleList!.length;
                                  i++)
                                Expanded(
                                  child: Container(
                                    margin:
                                        EdgeInsets.only(right: i < 4 ? 8 : 0),
                                    height: 80,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: Theme.of(context)
                                          .cardColor
                                          .withOpacity(0.05),
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: Colors.grey[200],
                                      ),
                                      child: CustomInkWell(
                                        onTap: () => splashController
                                            .switchModule(i, true),
                                        radius: 8,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      Dimensions.radiusSmall),
                                              child: CustomImage(
                                                image:
                                                    '${splashController.moduleList![i].iconFullUrl}',
                                                height: 35,
                                                width: 35,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              splashController
                                                  .moduleList![i].moduleName!,
                                              style: robotoRegular.copyWith(
                                                fontSize: 11,
                                                color: Theme.of(context)
                                                    .textTheme
                                                    .bodyLarge
                                                    ?.color
                                                    ?.withOpacity(0.8),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                              // BotÃ£o Ver Mais
                              Expanded(
                                child: Container(
                                  height: 80,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: Theme.of(context)
                                        .cardColor
                                        .withOpacity(0.05),
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.transparent,
                                    ),
                                    child: CustomInkWell(
                                      onTap: () => _showAllCategories(context),
                                      radius: 8,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Theme.of(context)
                                                  .primaryColor
                                                  .withOpacity(0.1),
                                            ),
                                            child: Icon(
                                              Icons.add,
                                              color: Theme.of(context)
                                                  .primaryColor,
                                              size: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Ver mais',
                                            style: robotoRegular.copyWith(
                                              fontSize: 11,
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge
                                                  ?.color
                                                  ?.withOpacity(0.8),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: Padding(
                      padding: const EdgeInsets.only(
                          top: Dimensions.paddingSizeSmall),
                      child: Text('no_module_found'.tr),
                    ))
              : ModuleShimmer(isEnabled: splashController.moduleList == null),

          const SizedBox(height: Dimensions.paddingSizeSmall),

          // Slider de banners
          GetBuilder<BannerController>(builder: (bannerController) {
            return splashController.moduleList != null
                ? const BannerView(isFeatured: true)
                : const SizedBox();
          }),

          const SizedBox(height: Dimensions.paddingSizeSmall),
          const FeaturedStoresVerticalView(),
          const SizedBox(
              height: Dimensions.paddingSizeLarge *
                  8), // Aumentando o espaÃ§o no final para 8x
          Container(
              height: MediaQuery.of(context).size.height *
                  0.2), // Adicionando 20% da altura da tela como espaÃ§o extra
        ],
      ),
    );
  }
}

class ModuleShimmer extends StatelessWidget {
  final bool isEnabled;
  const ModuleShimmer({super.key, required this.isEnabled});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: (2 / 1),
        crossAxisSpacing: Dimensions.paddingSizeSmall,
        mainAxisSpacing: Dimensions.paddingSizeSmall,
      ),
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      itemCount: 6,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3)
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              color: Colors.grey[100],
            ),
            child: Shimmer(
              duration: const Duration(seconds: 2),
              enabled: isEnabled,
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding:
                          const EdgeInsets.all(Dimensions.paddingSizeSmall),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 20,
                            width: 100,
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(Dimensions.radiusSmall),
                              color: Colors.grey[300],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(Dimensions.radiusDefault),
                          bottomRight:
                              Radius.circular(Dimensions.radiusDefault),
                        ),
                        color: Colors.grey[300],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class AddressShimmer extends StatelessWidget {
  final bool isEnabled;
  const AddressShimmer({super.key, required this.isEnabled});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: Dimensions.paddingSizeLarge),
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeSmall),
          child: TitleWidget(title: 'deliver_to'.tr),
        ),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
        SizedBox(
          height: 70,
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: 5,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeSmall),
            itemBuilder: (context, index) {
              return Container(
                width: 300,
                padding:
                    const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
                child: Container(
                  padding: EdgeInsets.all(ResponsiveHelper.isDesktop(context)
                      ? Dimensions.paddingSizeDefault
                      : Dimensions.paddingSizeSmall),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black12, blurRadius: 5, spreadRadius: 1)
                    ],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(
                      Icons.location_on,
                      size: ResponsiveHelper.isDesktop(context) ? 50 : 40,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: Dimensions.paddingSizeSmall),
                    Expanded(
                      child: Shimmer(
                        duration: const Duration(seconds: 2),
                        enabled: isEnabled,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                  height: 15,
                                  width: 100,
                                  color: Colors.grey[300]),
                              const SizedBox(
                                  height: Dimensions.paddingSizeExtraSmall),
                              Container(
                                  height: 10,
                                  width: 150,
                                  color: Colors.grey[300]),
                            ]),
                      ),
                    ),
                  ]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

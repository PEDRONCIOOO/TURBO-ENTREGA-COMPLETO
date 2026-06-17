import 'package:sixam_mart/features/order/controllers/order_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/common/widgets/menu_drawer.dart';
import 'package:sixam_mart/features/order/widgets/guest_track_order_input_view_widget.dart';
import 'package:sixam_mart/features/order/widgets/order_view_widget.dart';
import 'package:sixam_mart/features/dashboard/widgets/bottom_nav_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  OrderScreenState createState() => OrderScreenState();
}

class OrderScreenState extends State<OrderScreen>
    with TickerProviderStateMixin {
  TabController? _tabController;
  bool _isLoggedIn = AuthHelper.isLoggedIn();

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, initialIndex: 0, vsync: this);

    initCall();
  }

  void initCall() {
    if (AuthHelper.isLoggedIn()) {
      Get.find<OrderController>().getRunningOrders(1);
      Get.find<OrderController>().getHistoryOrders(1);
    }
  }

  void _navigateToPage(int pageIndex) {
    if (pageIndex == 0) {
      Get.offAllNamed(RouteHelper.getInitialRoute());
    } else if (pageIndex == 1) {
      // Navegar para a tela do Clube
    } else if (pageIndex == 2) {
      // Ja esta na tela de pedidos
    } else if (pageIndex == 3) {
      Get.offAllNamed(RouteHelper.getInitialRoute(fromSplash: true),
          arguments: 3);
    }
  }

  @override
  Widget build(BuildContext context) {
    _isLoggedIn = AuthHelper.isLoggedIn();
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: CustomAppBar(
              title: 'my_orders'.tr,
              backButton: ResponsiveHelper.isDesktop(context)),
      endDrawer: const MenuDrawer(),
      endDrawerEnableOpenDragGesture: false,
      bottomNavigationBar: ResponsiveHelper.isDesktop(context) ? null : Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            BottomNavItemWidget(
              title: 'Entrega',
              selectedIcon: Images.entrega,
              unSelectedIcon: Images.entrega,
              isSelected: false,
              onTap: () => _navigateToPage(0),
            ),
            BottomNavItemWidget(
              title: 'Clube',
              selectedIcon: Images.clube,
              unSelectedIcon: Images.clube,
              isSelected: false,
              onTap: () => _navigateToPage(1),
            ),
            BottomNavItemWidget(
              title: 'Pedidos',
              selectedIcon: Images.pedidos,
              unSelectedIcon: Images.pedidos,
              isSelected: true,
              onTap: () {},
            ),
            BottomNavItemWidget(
              title: 'Perfil',
              selectedIcon: Images.perfil,
              unSelectedIcon: Images.perfil,
              isSelected: false,
              onTap: () => _navigateToPage(3),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: GetBuilder<OrderController>(
          builder: (orderController) {
            return Column(
              children: [
                _isLoggedIn
                    ? Expanded(
                        child: Column(children: [
                          ResponsiveHelper.isDesktop(context)
                              ? Container(
                                  color: ResponsiveHelper.isDesktop(context)
                                      ? Theme.of(context)
                                          .primaryColor
                                          .withValues(alpha: 0.1)
                                      : Colors.transparent,
                                  child: Column(children: [
                                    ResponsiveHelper.isDesktop(context)
                                        ? Center(
                                            child: Padding(
                                            padding: const EdgeInsets.only(
                                                top: Dimensions
                                                    .paddingSizeSmall),
                                            child: Text('my_orders'.tr,
                                                style: robotoMedium),
                                          ))
                                        : const SizedBox(),
                                    Center(
                                      child: SizedBox(
                                        width: Dimensions.webMaxWidth,
                                        child: Align(
                                          alignment: ResponsiveHelper.isDesktop(
                                                  context)
                                              ? Alignment.centerLeft
                                              : Alignment.center,
                                          child: Container(
                                            width: ResponsiveHelper.isDesktop(
                                                    context)
                                                ? 300
                                                : Dimensions.webMaxWidth,
                                            color: ResponsiveHelper.isDesktop(
                                                    context)
                                                ? Colors.transparent
                                                : Theme.of(context).cardColor,
                                            child: TabBar(
                                              controller: _tabController,
                                              indicatorColor: Theme.of(context)
                                                  .primaryColor,
                                              indicatorWeight: 3,
                                              labelColor: Theme.of(context)
                                                  .primaryColor,
                                              unselectedLabelColor:
                                                  Theme.of(context)
                                                      .disabledColor,
                                              unselectedLabelStyle:
                                                  robotoRegular.copyWith(
                                                      color: Theme.of(context)
                                                          .disabledColor,
                                                      fontSize: Dimensions
                                                          .fontSizeSmall),
                                              labelStyle: robotoBold.copyWith(
                                                  fontSize:
                                                      Dimensions.fontSizeSmall,
                                                  color: Theme.of(context)
                                                      .primaryColor),
                                              tabs: [
                                                Tab(text: 'running'.tr),
                                                Tab(text: 'history'.tr),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ]),
                                )
                              : Column(children: [
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: TabBar(
                                      controller: _tabController,
                                      isScrollable: false,
                                      padding: EdgeInsets.zero,
                                      indicatorColor:
                                          Theme.of(context).primaryColor,
                                      indicatorWeight: 3,
                                      labelColor:
                                          Theme.of(context).primaryColor,
                                      unselectedLabelColor:
                                          Theme.of(context).disabledColor,
                                      unselectedLabelStyle:
                                          robotoRegular.copyWith(
                                              color: Theme.of(context)
                                                  .disabledColor,
                                              fontSize:
                                                  Dimensions.fontSizeSmall),
                                      labelStyle: robotoBold.copyWith(
                                          fontSize: Dimensions.fontSizeSmall,
                                          color:
                                              Theme.of(context).primaryColor),
                                      tabs: [
                                        Tab(text: 'running'.tr),
                                        Tab(text: 'history'.tr),
                                      ],
                                    ),
                                  ),
                                ]),
                          Expanded(
                              child: TabBarView(
                              controller: _tabController,
                              children: const [
                                OrderViewWidget(isRunning: true),
                                OrderViewWidget(isRunning: false),
                              ],
                            )),
                        ]),
                      )
                    : const GuestTrackOrderInputViewWidget(),
              ],
            );
          },
        ),
      ),
    );
  }
}

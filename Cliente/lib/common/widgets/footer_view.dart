import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/common/models/config_model.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/hover/text_hover.dart';
import 'package:url_launcher/url_launcher_string.dart';

class FooterView extends StatefulWidget {
  final Widget child;
  final double minHeight;
  final bool visibility;
  const FooterView({super.key, required this.child, this.minHeight = 0.65, this.visibility = true});

  @override
  State<FooterView> createState() => _FooterViewState();
}

class _FooterViewState extends State<FooterView> {
  final TextEditingController _newsLetterController = TextEditingController();
  final ConfigModel? _config = Get.find<SplashController>().configModel;

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;

    return Column(mainAxisAlignment: MainAxisAlignment.start, children: [
      ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * widget.minHeight,
        ),
        child: widget.child,
      ),

      (widget.visibility && ResponsiveHelper.isDesktop(context)) ? Container(
        width: context.width,
        margin: const EdgeInsets.only(top: 40),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(top: BorderSide(color: primaryColor.withValues(alpha: 0.1), width: 1)),
        ),
        child: Center(child: Column(children: [

          // Main footer content
          Container(
            width: Dimensions.webMaxWidth,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // Column 1: Logo + Newsletter + Social
              Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Image.asset(Images.logo, width: 120, height: 40),
                const SizedBox(height: 16),

                Text(
                  'Inscreva-se em nossa carta de notícias para obter as últimas atualizações',
                  style: robotoRegular.copyWith(fontSize: 12, color: Theme.of(context).disabledColor, height: 1.4),
                ),
                const SizedBox(height: 12),

                // Newsletter input
                Container(
                  constraints: const BoxConstraints(maxWidth: 320),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primaryColor.withValues(alpha: 0.1)),
                  ),
                  child: Row(children: [
                    const SizedBox(width: 14),
                    Expanded(child: TextField(
                      controller: _newsLetterController,
                      expands: false,
                      style: robotoRegular.copyWith(fontSize: 12),
                      decoration: InputDecoration(
                        hintText: 'Seu endereço de email',
                        hintStyle: robotoRegular.copyWith(color: Theme.of(context).disabledColor, fontSize: 12),
                        border: InputBorder.none,
                        isCollapsed: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      maxLines: 1,
                    )),
                    GetBuilder<SplashController>(builder: (splashController) {
                      return InkWell(
                        onTap: () {
                          String email = _newsLetterController.text.trim();
                          if (email.isEmpty) {
                            showCustomSnackBar('enter_email_address'.tr);
                          } else if (!GetUtils.isEmail(email)) {
                            showCustomSnackBar('enter_a_valid_email_address'.tr);
                          } else {
                            Get.find<SplashController>().subscribeMail(email).then((value) {
                              if (value) _newsLetterController.clear();
                            });
                          }
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: !splashController.isLoading
                              ? Text('Inscreva-se', style: robotoMedium.copyWith(color: Colors.white, fontSize: 12))
                              : const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                        ),
                      );
                    }),
                  ]),
                ),
                const SizedBox(height: 20),

                // Social media icons
                GetBuilder<SplashController>(builder: (splashController) {
                  return Wrap(
                    spacing: 8,
                    children: List.generate(
                      splashController.configModel!.socialMedia!.length,
                      (index) {
                        String? name = splashController.configModel!.socialMedia![index].name;
                        late String icon;
                        if (name == 'facebook') icon = Images.facebook;
                        else if (name == 'linkedin') icon = Images.linkedin;
                        else if (name == 'youtube') icon = Images.youtube;
                        else if (name == 'twitter') icon = Images.twitter;
                        else if (name == 'instagram') icon = Images.instagram;
                        else if (name == 'pinterest') icon = Images.pinterest;
                        else return const SizedBox.shrink();

                        return InkWell(
                          onTap: () async {
                            String url = splashController.configModel!.socialMedia![index].link!;
                            if (!url.startsWith('https://')) url = 'https://$url';
                            url = url.replaceFirst('www.', '');
                            if (await canLaunchUrlString(url)) _launchURL(url);
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: Image.asset(icon, fit: BoxFit.contain, color: primaryColor),
                          ),
                        );
                      },
                    ),
                  );
                }),
                const SizedBox(height: 16),

                // App store buttons
                Row(children: [
                  if (_config!.landingPageLinks!.appUrlAndroidStatus == '1')
                    InkWell(
                      onTap: () => _launchURL(_config.landingPageLinks!.appUrlAndroid ?? ''),
                      child: Image.asset(Images.landingGooglePlay, height: 36, fit: BoxFit.contain),
                    ),
                  if (_config.landingPageLinks!.appUrlAndroidStatus == '1')
                    const SizedBox(width: 8),
                  if (_config.landingPageLinks!.appUrlIosStatus == '1')
                    InkWell(
                      onTap: () => _launchURL(_config.landingPageLinks!.appUrlIos ?? ''),
                      child: Image.asset(Images.landingAppStore, height: 36, fit: BoxFit.contain),
                    ),
                ]),
              ])),

              const SizedBox(width: 40),

              // Column 2: Links
              Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Links', style: robotoBold.copyWith(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                FooterButton(title: 'become_a_store_owner'.tr, route: RouteHelper.getRestaurantRegistrationRoute()),
                const SizedBox(height: 10),
                FooterButton(title: 'become_a_delivery_man'.tr, route: RouteHelper.getDeliverymanRegistrationRoute()),
                const SizedBox(height: 10),
                FooterButton(title: 'help_support'.tr, route: RouteHelper.getSupportRoute()),
                const SizedBox(height: 10),
                FooterButton(title: 'privacy_policy'.tr, route: RouteHelper.getHtmlRoute('privacy-policy')),
                const SizedBox(height: 10),
                FooterButton(title: 'terms_and_condition'.tr, route: RouteHelper.getHtmlRoute('terms-and-condition')),
              ])),

              const SizedBox(width: 24),

              // Column 3: Contact info
              Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Contato', style: robotoBold.copyWith(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),

                // Email
                _ContactItem(
                  icon: Icons.email_outlined,
                  title: 'Envie-nos e-mails',
                  value: _config.email ?? '',
                  onTap: () async {
                    String url = 'mailto:${_config.email ?? ''}';
                    if (await canLaunchUrlString(url)) _launchURL(url);
                  },
                ),
                const SizedBox(height: 14),

                // Phone
                _ContactItem(
                  icon: Icons.phone_outlined,
                  title: 'Contate-nos',
                  value: _config.phone ?? '',
                ),
                const SizedBox(height: 14),

                // Address
                _ContactItem(
                  icon: Icons.location_on_outlined,
                  title: 'Encontre-nos aqui',
                  value: _config.address ?? '',
                ),
              ])),
            ]),
          ),

          // Copyright bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.04),
              border: Border(top: BorderSide(color: primaryColor.withValues(alpha: 0.08))),
            ),
            child: Center(
              child: Text(
                '\u00A9 2026 Turbo Entregas \u2022 Todos os Direitos Reservados \u2022 CNPJ: 63.242.190/0001-73',
                style: robotoRegular.copyWith(fontSize: 12, color: Theme.of(context).disabledColor),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ])),
      ) : const SizedBox.shrink(),
    ]);
  }

  _launchURL(String url) async {
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url, mode: LaunchMode.externalApplication);
    }
  }
}

class _ContactItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;

  const _ContactItem({required this.icon, required this.title, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: Theme.of(context).primaryColor),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: robotoBold.copyWith(fontSize: 12)),
          const SizedBox(height: 2),
          Text(
            value,
            style: robotoRegular.copyWith(fontSize: 11, color: Theme.of(context).disabledColor),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ])),
      ]),
    );
  }
}

class FooterButton extends StatelessWidget {
  final String title;
  final String route;
  final bool url;
  const FooterButton({super.key, required this.title, required this.route, this.url = false});

  @override
  Widget build(BuildContext context) {
    return TextHover(builder: (hovered) {
      return InkWell(
        hoverColor: Colors.transparent,
        onTap: route.isNotEmpty ? () async {
          if (url) {
            if (await canLaunchUrlString(route)) {
              launchUrlString(route, mode: LaunchMode.externalApplication);
            }
          } else {
            Get.toNamed(route);
          }
        } : null,
        child: Text(
          title,
          style: hovered
              ? robotoMedium.copyWith(color: Theme.of(context).primaryColor, fontSize: 12)
              : robotoRegular.copyWith(fontSize: 12, color: Theme.of(context).disabledColor),
        ),
      );
    });
  }
}

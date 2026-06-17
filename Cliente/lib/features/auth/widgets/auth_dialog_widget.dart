import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/auth/widgets/sign_in/sign_in_view.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/centralize_login_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';

class AuthDialogWidget extends StatefulWidget {
  final bool exitFromApp;
  final bool backFromThis;
  const AuthDialogWidget({super.key, required this.exitFromApp, required this.backFromThis});

  @override
  AuthDialogWidgetState createState() => AuthDialogWidgetState();
}

class AuthDialogWidgetState extends State<AuthDialogWidget> {

  bool _isOtpViewEnable = false;

  @override
  Widget build(BuildContext context) {
    double width = _isOtpViewEnable ? 400 : CentralizeLoginHelper.getPreferredLoginMethod(Get.find<SplashController>().configModel!.centralizeLoginSetup!, false).size;
    return SizedBox(
      width: width,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Theme.of(context).cardColor,
        insetPadding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, right: 8),
                  child: InkWell(
                    onTap: () => Get.back(),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
                      ),
                      child: Icon(Icons.close_rounded, size: 18, color: Theme.of(context).disabledColor),
                    ),
                  ),
                ),
              ),

              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtremeLarge),
                  child: Column(children: [

                    Image.asset(Images.logo, width: 120),
                    const SizedBox(height: Dimensions.paddingSizeLarge),

                    SignInView(exitFromApp: widget.exitFromApp, backFromThis: widget.backFromThis,
                      isOtpViewEnable: (bool val) {
                      setState(() {
                        _isOtpViewEnable = true;
                      });
                      },
                    ),
                  ]),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_ink_well.dart';
import 'package:sixam_mart/common/widgets/custom_text_field.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/auth/widgets/condition_check_box_widget.dart';
import 'package:sixam_mart/features/auth/widgets/sign_up_widget.dart';
import 'package:sixam_mart/features/auth/widgets/social_login_widget.dart';
import 'package:sixam_mart/features/verification/screens/forget_pass_screen.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/helper/validate_check.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class ManualLoginWidget extends StatelessWidget {
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final FocusNode phoneFocus;
  final FocusNode passwordFocus;
  final Function() onClickLoginButton;
  final Function()? onWebSubmit;
  final bool socialEnable;
  final Function()? onOtpViewClick;
  const ManualLoginWidget({
    super.key, required this.phoneController, required this.phoneFocus, required this.onClickLoginButton, required this.passwordController,
    required this.passwordFocus, this.onWebSubmit, this.socialEnable = false, this.onOtpViewClick,
  });

  @override
  Widget build(BuildContext context) {
    bool isDesktop = ResponsiveHelper.isDesktop(context);
    return GetBuilder<AuthController>(builder: (authController) {
      
      if(isDesktop) {
        return webView(isDesktop, context, authController);
      }
      
      return Column(mainAxisSize: MainAxisSize.min, children: [
        Align(
          alignment: Alignment.topLeft,
          child: Text('login'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge)),
        ),
        const SizedBox(height: Dimensions.paddingSizeDefault),

        CustomTextField(
          onCountryChanged: (countryCode) => authController.countryDialCode = countryCode.dialCode!,
          countryDialCode: authController.isNumberLogin ? authController.countryDialCode : null,
          labelText: 'email_or_phone'.tr,
          titleText: 'enter_email_or_phone'.tr,
          controller: phoneController,
          focusNode: phoneFocus,
          nextFocus: passwordFocus,
          inputType: TextInputType.emailAddress,
          prefixImage: authController.isNumberLogin ? null : Images.emailWithPhoneIcon,
          onChanged: (String text){
            final numberRegExp = RegExp(r'^[+]?[0-9]+$');

            if(text.isEmpty && authController.isNumberLogin){
              authController.toggleIsNumberLogin();
            }
            if(text.startsWith(numberRegExp) && !authController.isNumberLogin ){
              authController.toggleIsNumberLogin();
              phoneController.text = text.replaceAll("+", "");
            }
            final emailRegExp = RegExp(r'@');
            if(text.contains(emailRegExp) && authController.isNumberLogin){
              authController.toggleIsNumberLogin();
            }

          },
          validator: (String? value){

            if(authController.isNumberLogin && ValidateCheck.getValidPhone(authController.countryDialCode+value!) == ""){
              return "enter_valid_phone_number".tr;
            }
            return (GetUtils.isPhoneNumber(authController.countryDialCode+value!.tr) || GetUtils.isEmail(value.tr)) ? null : 'enter_email_address_or_phone_number'.tr;
          },
        ),

        const SizedBox(height: Dimensions.paddingSizeExtraLarge),

        CustomTextField(
          titleText: '8_character'.tr,
          controller: passwordController,
          focusNode: passwordFocus,
          inputAction: TextInputAction.done,
          inputType: TextInputType.visiblePassword,
          prefixIcon: Icons.lock,
          isPassword: true,
          onSubmit: (text) => (GetPlatform.isWeb) ? onWebSubmit : null,
          labelText: 'password'.tr,
          required: true,
          validator: (value) => ValidateCheck.validateEmptyText(value, "please_enter_password".tr),
        ),
        SizedBox(height: ResponsiveHelper.isDesktop(context) ? Dimensions.paddingSizeDefault : Dimensions.paddingSizeExtraSmall),


        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          InkWell(
            onTap: () => authController.toggleRememberMe(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 24, width: 24,
                  child: Checkbox(
                    side: BorderSide(color: Theme.of(context).hintColor),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    activeColor: Theme.of(context).primaryColor,
                    value: authController.isActiveRememberMe,
                    onChanged: (bool? isChecked) => authController.toggleRememberMe(),
                  ),
                ),
                const SizedBox(width: Dimensions.paddingSizeSmall),

                Text('remember_me'.tr, style: robotoRegular),
              ],
            ),
          ),

          TextButton(
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            onPressed: () {
              Get.toNamed(RouteHelper.getForgotPassRoute());
            },
            child: Text('${'forgot_password'.tr}?', style: robotoRegular.copyWith(color: Theme.of(context).primaryColor)),
          ),
        ]),

        const SizedBox(height: Dimensions.paddingSizeLarge),

        const ConditionCheckBoxWidget(forSignUp: true),
        const SizedBox(height: Dimensions.paddingSizeExtraLarge),

        CustomButton(
          height: isDesktop ? 50 : null,
          width:  isDesktop ? 250 : null,
          buttonText: 'login'.tr,
          radius: isDesktop ? Dimensions.radiusSmall : Dimensions.radiusDefault,
          isBold: isDesktop ? false : true,
          isLoading: authController.isLoading,
          onPressed: onClickLoginButton,
        ),
        const SizedBox(height: Dimensions.paddingSizeLarge),

        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('do_not_have_account'.tr, style: robotoRegular.copyWith(color: Theme.of(context).hintColor)),

          InkWell(
            onTap: authController.isLoading ? null : () {
              Get.toNamed(RouteHelper.getSignUpRoute());
            },
            child: Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
              child: Text('sign_up'.tr, style: robotoMedium.copyWith(color: Theme.of(context).primaryColor)),
            ),
          ),
        ]),

        SizedBox(height: isDesktop ? Dimensions.paddingSizeLarge : 0),

        onOtpViewClick != null ? Column(children: [
          Text('or'.tr, style: robotoRegular.copyWith(color: Theme.of(context).disabledColor)),
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),

          Row(mainAxisSize: MainAxisSize.min, children: [
            Text('sign_in_with'.tr, style: robotoRegular.copyWith(color: Theme.of(context).disabledColor)),
            const SizedBox(width: Dimensions.paddingSizeExtraSmall),

            InkWell(
              onTap: onOtpViewClick,
              child: Text('otp'.tr, style: robotoRegular.copyWith(color: Theme.of(context).primaryColor, decoration: TextDecoration.underline)),
            ),
          ]),
        ]) : const SizedBox(),

        socialEnable ? const SocialLoginWidget(onlySocialLogin: false) : const SizedBox(),

      ]);
    });
  }

  Widget webView(bool isDesktop, BuildContext context, AuthController authController) {
    bool onlyManualLoginEnable = onOtpViewClick == null && !socialEnable;
    return Padding(
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      child: Column(mainAxisSize: MainAxisSize.min, children: [

        Align(
          alignment: Alignment.topLeft,
          child: Text('login'.tr, style: robotoBold.copyWith(fontSize: 20, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(height: Dimensions.paddingSizeDefault),

        CustomTextField(
          onCountryChanged: (countryCode) => authController.countryDialCode = countryCode.dialCode!,
          countryDialCode: authController.isNumberLogin ? authController.countryDialCode : null,
          labelText: 'email_or_phone'.tr,
          titleText: 'enter_email_or_phone'.tr,
          controller: phoneController,
          focusNode: phoneFocus,
          nextFocus: passwordFocus,
          prefixImage: authController.isNumberLogin ? null : Images.emailWithPhoneIcon,
          inputType: TextInputType.emailAddress,
          onChanged: (String text){
            final numberRegExp = RegExp(r'^[+]?[0-9]+$');
            if (text.isEmpty && authController.isNumberLogin) {
              authController.toggleIsNumberLogin();
            } else if (text.startsWith(numberRegExp) && !authController.isNumberLogin) {
              authController.toggleIsNumberLogin();
              final cleanedText = text.replaceAll("+", "");
              WidgetsBinding.instance.addPostFrameCallback((_) {
                phoneController.text = cleanedText;
                phoneController.selection = TextSelection.fromPosition(
                  TextPosition(offset: phoneController.text.length),
                );
              });
            } else if (text.contains('@') && authController.isNumberLogin) {
              authController.toggleIsNumberLogin();
            }
          },
          validator: (String? value){
            if(authController.isNumberLogin && ValidateCheck.getValidPhone(authController.countryDialCode+value!) == ""){
              return "enter_valid_phone_number".tr;
            }
            return (GetUtils.isPhoneNumber(value!.tr) || GetUtils.isEmail(value.tr)) ? null : 'enter_email_address_or_phone_number'.tr;
          },
        ),
        const SizedBox(height: Dimensions.paddingSizeExtraLarge),

        CustomTextField(
          titleText: '8_character'.tr,
          controller: passwordController,
          focusNode: passwordFocus,
          inputAction: TextInputAction.done,
          inputType: TextInputType.visiblePassword,
          prefixIcon: Icons.lock,
          isPassword: true,
          onSubmit: (text) => (GetPlatform.isWeb) ? onWebSubmit : null,
          labelText: 'password'.tr,
          required: true,
          validator: (value) => ValidateCheck.validateEmptyText(value, "please_enter_password".tr),
        ),
        const SizedBox(height: Dimensions.paddingSizeDefault),

        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          InkWell(
            onTap: () => authController.toggleRememberMe(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 24, width: 24,
                  child: Checkbox(
                    side: BorderSide(color: Theme.of(context).hintColor),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    activeColor: Theme.of(context).primaryColor,
                    value: authController.isActiveRememberMe,
                    onChanged: (bool? isChecked) => authController.toggleRememberMe(),
                  ),
                ),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                Text('remember_me'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall)),
              ],
            ),
          ),

          TextButton(
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            onPressed: () {
              Get.back();
              Get.dialog(const Center(child: ForgetPassScreen(fromDialog: true)));
            },
            child: Text('${'forgot_password'.tr}?', style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).primaryColor)),
          ),
        ]),

        const SizedBox(height: Dimensions.paddingSizeDefault),

        const ConditionCheckBoxWidget(forSignUp: true),
        const SizedBox(height: Dimensions.paddingSizeLarge),

        CustomButton(
          buttonText: 'login'.tr,
          radius: 12,
          isBold: true,
          isLoading: authController.isLoading,
          onPressed: onClickLoginButton,
        ),
        const SizedBox(height: Dimensions.paddingSizeDefault),

        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('do_not_have_account'.tr, style: robotoRegular.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeSmall)),
          InkWell(
            onTap: () {
              Get.back();
              Get.dialog(
                SizedBox(
                  width: 700,
                  child: Dialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    backgroundColor: Theme.of(context).cardColor,
                    insetPadding: EdgeInsets.zero,
                    child: const SignUpWidget(),
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
              child: Text('sign_up'.tr, style: robotoMedium.copyWith(color: Theme.of(context).primaryColor, fontSize: Dimensions.fontSizeSmall)),
            ),
          ),
        ]),

        // Social login + OTP section below form
        if (!onlyManualLoginEnable) ...[
          const SizedBox(height: Dimensions.paddingSizeSmall),

          Row(children: [
            Expanded(child: Divider(color: Theme.of(context).disabledColor.withValues(alpha: 0.3))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('or_login_with'.tr, style: robotoRegular.copyWith(color: Theme.of(context).disabledColor, fontSize: 12)),
            ),
            Expanded(child: Divider(color: Theme.of(context).disabledColor.withValues(alpha: 0.3))),
          ]),
          const SizedBox(height: Dimensions.paddingSizeDefault),

          if (socialEnable) const SocialLoginWidget(onlySocialLogin: true, showWelcomeText: false),

          if (onOtpViewClick != null) ...[
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.2)),
              ),
              child: CustomInkWell(
                onTap: onOtpViewClick!,
                radius: 12,
                child: Padding(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Image.asset(Images.otp, height: 20, width: 20),
                    const SizedBox(width: Dimensions.paddingSizeSmall),
                    Text('otp_sign_in'.tr, style: robotoMedium.copyWith(fontSize: 13)),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),
          ],
        ],

        const SizedBox(height: Dimensions.paddingSizeSmall),
      ]),
    );
  }
}

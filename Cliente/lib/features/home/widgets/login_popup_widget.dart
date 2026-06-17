import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/styles.dart';

class LoginPopupWidget extends StatelessWidget {
  const LoginPopupWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 20, // Alta elevaÃ§Ã£o para simular z-index alto
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Get.toNamed(RouteHelper.getLoginChoiceRoute()),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Explore mais com sua conta Turbo Entregas',
                style: robotoMedium.copyWith(
                  fontSize: 12,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Entrar ou cadastrar-se',
                style: robotoMedium.copyWith(
                  fontSize: 12,
                  color: Theme.of(context).primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

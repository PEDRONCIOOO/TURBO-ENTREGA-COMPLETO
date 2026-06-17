import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart_delivery/util/dimensions.dart';

// 👇 importa a key global
import 'package:sixam_mart_delivery/helper/global_keys.dart';

void showCustomSnackBar(String? message, {bool isError = true}) {
  if (message == null || message.isEmpty) return;

  // Usa SEMPRE a key global do ScaffoldMessenger
  rootScaffoldMessengerKey.currentState?.showSnackBar(
    SnackBar(
      content: Text(
        message,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
      backgroundColor:
          isError ? Colors.red.withOpacity(0.9) : Colors.green.withOpacity(0.9),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
  );
}

import 'package:sixam_mart/features/favourite/controllers/favourite_controller.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:get/get.dart';

class ApiChecker {
  static bool _isHandling401 = false;

  static void resetAuthFlag() {
    _isHandling401 = false;
  }

  static void checkApi(Response response, {bool getXSnackBar = false}) {
    if(response.statusCode == 401) {
      if(!_isHandling401) {
        _isHandling401 = true;
        Get.find<AuthController>().clearSharedData(removeToken: false).then((value) {
          Get.find<FavouriteController>().removeFavourite();
          Get.offAllNamed(RouteHelper.getInitialRoute());
        });
      }
    }else {
      if(response.statusText != 'The guest id field is required.') {
        showCustomSnackBar(response.statusText, getXSnackBar: getXSnackBar);
      }
    }
  }
}

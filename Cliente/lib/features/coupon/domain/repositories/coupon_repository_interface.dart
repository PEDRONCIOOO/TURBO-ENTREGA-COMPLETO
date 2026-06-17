import 'package:sixam_mart/interfaces/repository_interface.dart';

abstract class CouponRepositoryInterface extends RepositoryInterface{
  @override
  Future getList({int? offset, bool couponList = false});
  Future<dynamic> applyCoupon(String couponCode, int? storeID);
}
import 'package:sixam_mart/features/coupon/domain/models/coupon_model.dart';

abstract class CouponServiceInterface{
  Future<List<CouponModel>?> getCouponList();
  Future<CouponModel?> applyCoupon(String couponCode, int? storeID);
}
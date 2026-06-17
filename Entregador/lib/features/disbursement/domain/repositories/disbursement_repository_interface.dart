import 'package:sixam_mart_delivery/features/disbursement/domain/models/pix_account_model.dart';
import 'package:sixam_mart_delivery/interface/repository_interface.dart';

abstract class DisbursementRepositoryInterface implements RepositoryInterface {
  Future<dynamic> addWithdraw(Map<String?, String> data);
  Future<dynamic> makeDefaultMethod(Map<String?, String> data);
  Future<dynamic> getDisbursementReport(int offset);
  Future<dynamic> getWithdrawMethodList();
  Future<PixAccountModel?> getPixAccount();
  Future<dynamic> registerPixAccount(Map<String, String> data);
  Future<bool> requestDisbursement(Map<String, String> data);
  Future<bool> makeWalletAdjustment();
  Future<dynamic> requestPixReset();
}
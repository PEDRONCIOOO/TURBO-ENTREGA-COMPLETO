import 'package:sixam_mart_delivery/features/cash_in_hand/domain/models/withdraw_method_model.dart';
import 'package:sixam_mart_delivery/features/disbursement/domain/models/disbursement_method_model.dart' as disburse;
import 'package:sixam_mart_delivery/features/disbursement/domain/models/disbursement_report_model.dart' as report;
import 'package:sixam_mart_delivery/features/disbursement/domain/models/pix_account_model.dart';

abstract class DisbursementServiceInterface {
  Future<bool> addWithdraw(Map<String?, String> data);
  Future<disburse.DisbursementMethodBody?> getDisbursementMethodList();
  Future<bool> makeDefaultMethod(Map<String?, String> data);
  Future<bool> deleteMethod(int id);
  Future<report.DisbursementReportModel?> getDisbursementReport(int offset);
  Future<List<WidthDrawMethodModel>?> getWithdrawMethodList();
  Future<PixAccountModel?> getPixAccount();
  Future<dynamic> registerPixAccount(Map<String, String> data);
  Future<bool> requestDisbursement(Map<String, String> data);
  Future<bool> makeWalletAdjustment();
  Future<dynamic> requestPixReset();
}
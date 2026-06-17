import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart_delivery/features/cash_in_hand/domain/models/withdraw_method_model.dart';
import 'package:sixam_mart_delivery/features/disbursement/domain/models/disbursement_method_model.dart' as disburse;
import 'package:sixam_mart_delivery/features/disbursement/domain/models/disbursement_report_model.dart' as report;
import 'package:sixam_mart_delivery/features/disbursement/domain/models/pix_account_model.dart';
import 'package:sixam_mart_delivery/common/widgets/custom_dropdown_widget.dart';
import 'package:sixam_mart_delivery/common/widgets/custom_snackbar_widget.dart';
import 'package:sixam_mart_delivery/features/disbursement/domain/services/disbursement_service_interface.dart';

class DisbursementController extends GetxController implements GetxService {
  final DisbursementServiceInterface disbursementServiceInterface;
  DisbursementController({required this.disbursementServiceInterface});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isDeleteLoading = false;
  bool get isDeleteLoading => _isDeleteLoading;

  int? _selectedMethodIndex = 0;
  int? get selectedMethodIndex => _selectedMethodIndex;

  List<DropdownItem<int>> _methodList = [];
  List<DropdownItem<int>> get methodList => _methodList;

  List<TextEditingController> _textControllerList = [];
  List<TextEditingController> get textControllerList => _textControllerList;

  List<MethodFields> _methodFields = [];
  List<MethodFields> get methodFields => _methodFields;

  List<FocusNode> _focusList = [];
  List<FocusNode> get focusList => _focusList;

  List<WidthDrawMethodModel>? _widthDrawMethods;
  List<WidthDrawMethodModel>? get widthDrawMethods => _widthDrawMethods;

  disburse.DisbursementMethodBody? _disbursementMethodBody;
  disburse.DisbursementMethodBody? get disbursementMethodBody => _disbursementMethodBody;

  int? _index = -1;
  int? get index =>_index;

  report.DisbursementReportModel? _disbursementReportModel;
  report.DisbursementReportModel? get disbursementReportModel => _disbursementReportModel;

  // ── PIX / Saque ────────────────────────────────────────────────────────
  PixAccountModel? _pixAccount;
  PixAccountModel? get pixAccount => _pixAccount;

  bool _isPixLoading = false;
  bool get isPixLoading => _isPixLoading;

  /// true = API was called at least once and returned (success or failure)
  bool _pixLoaded = false;
  bool get pixLoaded => _pixLoaded;

  /// true = the last getPixAccount() call failed (network/server error)
  bool _pixLoadError = false;
  bool get pixLoadError => _pixLoadError;

  bool _isSaqueLoading = false;
  bool get isSaqueLoading => _isSaqueLoading;

  String _selectedPixKeyType = 'CPF';
  String get selectedPixKeyType => _selectedPixKeyType;

  List<String> get pixKeyTypes => const ['CPF', 'CNPJ', 'EMAIL', 'PHONE', 'EVP'];

  final TextEditingController pixKeyController = TextEditingController();
  final TextEditingController pixHolderNameController = TextEditingController();
  final TextEditingController pixHolderDocController = TextEditingController();
  final TextEditingController saqueAmountController = TextEditingController();

  // FocusNodes are persistent — they survive GetBuilder rebuilds so the keyboard
  // doesn't dismiss when the controller calls update() during profile/PIX loading.
  final FocusNode pixKeyFocusNode = FocusNode();
  final FocusNode pixHolderNameFocusNode = FocusNode();
  final FocusNode pixHolderDocFocusNode = FocusNode();
  final FocusNode saqueAmountFocusNode = FocusNode();

  void setMethodId(int? id, {bool canUpdate = true}) {
    _selectedMethodIndex = id;
    if(canUpdate){
      update();
    }
  }

  Future<void> setMethod({bool isUpdate = true}) async {
    _methodList = [];
    _textControllerList = [];
    _methodFields = [];
    _focusList = [];

    if(_widthDrawMethods == null) {
      _widthDrawMethods = await getWithdrawMethodList();
    } else {
      _widthDrawMethods = widthDrawMethods;
    }
    if(_widthDrawMethods != null && _widthDrawMethods!.isNotEmpty){
      for(int i=0; i < _widthDrawMethods!.length; i++){
        _methodList.add(DropdownItem<int>(value: i, child: SizedBox(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('${_widthDrawMethods![i].methodName}'),
          ),
        )));
      }
      _textControllerList = [];
      _methodFields = [];
      for (var field in _widthDrawMethods![_selectedMethodIndex!].methodFields!) {
        _methodFields.add(field);
        _textControllerList.add(TextEditingController());
        _focusList.add(FocusNode());
      }
    }
    if(isUpdate) {
      update();
    }
  }

  Future<void> addWithdrawMethod(Map<String?, String> data) async {
    _isLoading = true;
    update();
    bool isSuccess = await disbursementServiceInterface.addWithdraw(data);
    if(isSuccess) {
      Get.back();
      getDisbursementMethodList();
      showCustomSnackBar('add_successfully'.tr, isError: false);
    }
    _isLoading = false;
    update();
  }

  Future<bool> getDisbursementMethodList() async {
    bool success = false;
    disburse.DisbursementMethodBody? disbursementMethodBody = await disbursementServiceInterface.getDisbursementMethodList();
    if(disbursementMethodBody != null) {
      success = true;
      _disbursementMethodBody = disbursementMethodBody;
    }
    update();
    return success;
  }

  Future<void> makeDefaultMethod(Map<String, String> data, int index) async {
    _index = index;
    _isLoading = true;
    update();
    bool isSuccess = await disbursementServiceInterface.makeDefaultMethod(data);
    if(isSuccess) {
      _index = -1;
      getDisbursementMethodList();
      showCustomSnackBar('set_default_method_successful'.tr, isError: false);
    }
    _isLoading = false;
    update();
  }

  Future<void> deleteMethod(int id) async {
    _isDeleteLoading = true;
    update();
    bool isSuccess = await disbursementServiceInterface.deleteMethod(id);
    if(isSuccess) {
      getDisbursementMethodList();
      Get.back();
      showCustomSnackBar('method_delete_successfully'.tr, isError: false);
    }
    _isDeleteLoading = false;
    update();
  }

  Future<void> getDisbursementReport(int offset) async {
    report.DisbursementReportModel? disbursementReportModel = await disbursementServiceInterface.getDisbursementReport(offset);
    if(disbursementReportModel != null) {
      _disbursementReportModel = disbursementReportModel;
    }
    update();
  }

  Future<List<WidthDrawMethodModel>?> getWithdrawMethodList() async {
    List<WidthDrawMethodModel>? widthDrawMethods = await disbursementServiceInterface.getWithdrawMethodList();
    if(widthDrawMethods != null) {
      _widthDrawMethods = [];
      _widthDrawMethods!.addAll(widthDrawMethods);
    }
    update();
    return _widthDrawMethods;
  }

  void setPixKeyType(String type) {
    _selectedPixKeyType = type;
    update();
  }

  Future<void> getPixAccount() async {
    _isPixLoading = true;
    _pixLoadError = false;
    update();
    try {
      PixAccountModel? model = await disbursementServiceInterface.getPixAccount();
      if (model != null) {
        _pixAccount = model;
        _pixResetRequested = model.pixResetRequested ?? false;
        _pixLoaded = true;
      } else {
        _pixLoadError = true;
      }
    } catch (_) {
      _pixLoadError = true;
    } finally {
      _isPixLoading = false;
      update();
    }
  }

  Future<void> registerPixAccount() async {
    _isPixLoading = true;
    update();
    try {
      final data = {
        'pix_key': pixKeyController.text.trim(),
        'pix_key_type': _selectedPixKeyType,
        'holder_name': pixHolderNameController.text.trim(),
        'holder_document': pixHolderDocController.text.trim(),
      };
      final result = await disbursementServiceInterface.registerPixAccount(data);
      if (result == true) {
        showCustomSnackBar('Chave PIX cadastrada com sucesso!', isError: false);
        // Reload account without changing the loading flag (getPixAccount manages it)
        PixAccountModel? model = await disbursementServiceInterface.getPixAccount();
        if (model != null) {
          _pixAccount = model;
          _pixLoaded = true;
          _pixLoadError = false;
        }
      }
      // If result is an error String, show it
      if (result is String) {
        showCustomSnackBar(result);
      }
    } catch (e) {
      showCustomSnackBar('Erro ao cadastrar chave PIX. Tente novamente.');
    } finally {
      _isPixLoading = false;
      update();
    }
  }

  Future<void> requestSaque({required double availableBalance}) async {
    final text = saqueAmountController.text.trim().replaceAll(',', '.');
    final amount = double.tryParse(text);
    if (amount == null || amount <= 0) {
      showCustomSnackBar('Informe um valor válido');
      return;
    }
    if (amount > availableBalance) {
      showCustomSnackBar('Valor maior que o saldo disponível');
      return;
    }
    _isSaqueLoading = true;
    update();
    final data = {'amount': amount.toStringAsFixed(2)};
    bool success = await disbursementServiceInterface.requestDisbursement(data);
    if (success) {
      showCustomSnackBar('Saque solicitado com sucesso!', isError: false);
      saqueAmountController.clear();
      await getDisbursementReport(1);
    }
    _isSaqueLoading = false;
    update();
  }

  bool _isAdjustLoading = false;
  bool get isAdjustLoading => _isAdjustLoading;

  bool _isPixResetLoading = false;
  bool get isPixResetLoading => _isPixResetLoading;

  bool _pixResetRequested = false;
  bool get pixResetRequested => _pixResetRequested;

  Future<void> makeWalletAdjustment() async {
    _isAdjustLoading = true;
    update();
    bool success = await disbursementServiceInterface.makeWalletAdjustment();
    if (success) {
      showCustomSnackBar('Ajuste realizado com sucesso!', isError: false);
    }
    _isAdjustLoading = false;
    update();
  }

  Future<void> requestPixReset() async {
    _isPixResetLoading = true;
    update();
    final result = await disbursementServiceInterface.requestPixReset();
    _isPixResetLoading = false;
    if (result == true) {
      _pixResetRequested = true;
      showCustomSnackBar('Solicitação enviada! O administrador será notificado.', isError: false);
    } else {
      showCustomSnackBar(result?.toString() ?? 'Erro ao enviar solicitação.', isError: true);
    }
    update();
  }

  @override
  void onClose() {
    pixKeyController.dispose();
    pixHolderNameController.dispose();
    pixHolderDocController.dispose();
    saqueAmountController.dispose();
    pixKeyFocusNode.dispose();
    pixHolderNameFocusNode.dispose();
    pixHolderDocFocusNode.dispose();
    saqueAmountFocusNode.dispose();
    super.onClose();
  }
  
}
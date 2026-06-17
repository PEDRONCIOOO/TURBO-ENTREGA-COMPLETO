class PixAccountModel {
  bool? hasAccount;
  bool? pixResetRequested;
  PixAccountData? data;

  PixAccountModel({this.hasAccount, this.pixResetRequested, this.data});

  PixAccountModel.fromJson(Map<String, dynamic> json) {
    hasAccount = json['has_account'];
    pixResetRequested = json['pix_reset_requested'] == true;
    if (json['data'] != null && json['data'] is Map) {
      data = PixAccountData.fromJson(json['data']);
    }
  }
}

class PixAccountData {
  int? id;
  int? deliveryManId;
  String? pixKey;
  String? pixKeyType;
  String? holderName;
  String? holderDocument;
  bool? isVerified;
  bool? pixResetRequested;
  String? pixResetRequestedAt;
  String? createdAt;
  String? updatedAt;

  PixAccountData({
    this.id,
    this.deliveryManId,
    this.pixKey,
    this.pixKeyType,
    this.holderName,
    this.holderDocument,
    this.isVerified,
    this.pixResetRequested,
    this.pixResetRequestedAt,
    this.createdAt,
    this.updatedAt,
  });

  PixAccountData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    deliveryManId = json['delivery_man_id'];
    pixKey = json['pix_key'];
    pixKeyType = json['pix_key_type'];
    holderName = json['holder_name'];
    holderDocument = json['holder_document'];
    // is_verified pode vir como bool (cast PHP) ou int (legado) — aceita os dois
    final iv = json['is_verified'];
    isVerified = iv == true || iv == 1;
    // pix_reset_requested pode vir como bool ou int também
    final pr = json['pix_reset_requested'];
    pixResetRequested = pr == true || pr == 1;
    pixResetRequestedAt = json['pix_reset_requested_at']?.toString();
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }
}

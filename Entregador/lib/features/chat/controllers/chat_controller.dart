import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sixam_mart_delivery/api/api_client.dart';
import 'package:sixam_mart_delivery/features/notification/domain/models/notification_body_model.dart';
import 'package:sixam_mart_delivery/features/chat/domain/models/conversation_model.dart';
import 'package:sixam_mart_delivery/features/chat/domain/models/message_model.dart';
import 'package:sixam_mart_delivery/features/chat/domain/services/chat_service_interface.dart';
import 'package:sixam_mart_delivery/features/profile/controllers/profile_controller.dart';

class ChatController extends GetxController implements GetxService {
  final ChatServiceInterface chatServiceInterface;
  ChatController({required this.chatServiceInterface});

  List<bool>? _showDate;
  List<bool>? get showDate => _showDate;

  List<XFile>? _imageFiles;
  List<XFile>? get imageFiles => _imageFiles;

  bool _isSendButtonActive = false;
  bool get isSendButtonActive => _isSendButtonActive;

  final bool _isSeen = false;
  bool get isSeen => _isSeen;

  final bool _isSend = true;
  bool get isSend => _isSend;

  final bool _isMe = false;
  bool get isMe => _isMe;

  bool _isLoading= false;
  bool get isLoading => _isLoading;

  List <XFile>?_chatImage = [];
  List<XFile>? get chatImage => _chatImage;

  int? _pageSize;
  int? get pageSize => _pageSize;

  int? _offset;
  int? get offset => _offset;

  ConversationsModel? _conversationModel ;
  ConversationsModel? get conversationModel => _conversationModel;

  ConversationsModel? _searchConversationModel;
  ConversationsModel? get searchConversationModel => _searchConversationModel;

  MessageModel? _messageModel;
  MessageModel? get messageModel => _messageModel;

  Future<void> getConversationList(int offset) async{
    _searchConversationModel = null;
    _conversationModel = null;
    ConversationsModel? conversationModel = await chatServiceInterface.getConversationList(offset);
    if(conversationModel != null) {
      if(offset == 1) {
        _conversationModel = conversationModel;
      }else {
        _conversationModel!.totalSize = conversationModel.totalSize;
        _conversationModel!.offset = conversationModel.offset;
        _conversationModel!.conversations!.addAll(conversationModel.conversations!);
      }
    }
    update();
  }

  Future<void> searchConversation(String name) async {
    _searchConversationModel = ConversationsModel();
    update();
    ConversationsModel? searchConversationModel = await chatServiceInterface.searchConversationList(name);
    if(searchConversationModel != null) {
      _searchConversationModel = searchConversationModel;
    }
    update();
  }

  void removeSearchMode() {
    _searchConversationModel = null;
    update();
  }

  Future<void> getMessages(int offset, NotificationBodyModel notificationBody, User? user, int? conversationID, {bool firstLoad = false}) async {
    if(firstLoad) {
      _messageModel = null;
    }

    MessageModel? messageModel = await chatServiceInterface.processGetMessage(offset, notificationBody, conversationID);

    if (messageModel == null && offset == 1 && user != null) {
      // Only build empty model on FIRST LOAD (_messageModel is null).
      // Do NOT overwrite if _messageModel already has messages (e.g. right after sendMessage).
      if (_messageModel == null) {
        try {
          if (Get.find<ProfileController>().profileModel == null) {
            await Get.find<ProfileController>().getProfile();
          }
        } catch (_) {}
        final profile = Get.find<ProfileController>().profileModel;
        _messageModel = MessageModel(totalSize: 0, limit: 10, offset: 1, status: true, messages: []);
        _messageModel!.conversation = Conversation(
          sender: User(
            id: profile?.id, imageFullUrl: profile?.imageFullUrl,
            fName: profile?.fName, lName: profile?.lName,
          ),
          receiver: user,
        );
      }
    }

    if (messageModel != null) {
      if (offset == 1) {
        if(Get.find<ProfileController>().profileModel == null) {
          await Get.find<ProfileController>().getProfile();
        }
        _messageModel = messageModel;
        if(_messageModel!.conversation == null && user != null) {
          _messageModel!.conversation = Conversation(sender: User(
            id: Get.find<ProfileController>().profileModel!.id, imageFullUrl: Get.find<ProfileController>().profileModel!.imageFullUrl,
            fName: Get.find<ProfileController>().profileModel!.fName, lName: Get.find<ProfileController>().profileModel!.lName,
          ), receiver: user);
        }else if(_messageModel!.conversation != null && _messageModel!.conversation!.receiverType == 'delivery_man') {
          User? receiver = _messageModel!.conversation!.receiver;
          _messageModel!.conversation!.receiver = _messageModel!.conversation!.sender;
          _messageModel!.conversation!.sender = receiver;
        }
        // Fill missing name/photo from the user param when API returns incomplete data
        if(_messageModel!.conversation != null && user != null) {
          if((_messageModel!.conversation!.receiver?.fName == null || _messageModel!.conversation!.receiver!.fName!.isEmpty)
              && user.fName != null && user.fName!.isNotEmpty) {
            _messageModel!.conversation!.receiver?.fName = user.fName;
            _messageModel!.conversation!.receiver?.lName = user.lName;
          }
          if((_messageModel!.conversation!.receiver?.imageFullUrl == null || _messageModel!.conversation!.receiver!.imageFullUrl!.isEmpty)
              && user.imageFullUrl != null && user.imageFullUrl!.isNotEmpty) {
            _messageModel!.conversation!.receiver?.imageFullUrl = user.imageFullUrl;
          }
        }
      }else {
        _messageModel!.totalSize = messageModel.totalSize;
        _messageModel!.offset = messageModel.offset;
        _messageModel!.messages!.addAll(messageModel.messages!);
      }
    }
    _isLoading = false;
    update();

  }

  Future<bool> sendMessage({required String message, required NotificationBodyModel? notificationBody, required int? conversationId}) async {
    bool isSuccess = false;
    _isLoading = true;
    update();

    List<MultipartBody> chatImage = chatServiceInterface.processMultipartBody(_chatImage!);
    MessageModel? messageModel = await chatServiceInterface.processSendMessage(notificationBody, chatImage, message, conversationId);

    if (messageModel != null) {
      _imageFiles = [];
      _chatImage = [];
      _isSendButtonActive = false;
      _isLoading = false;
      _messageModel = messageModel;
      if(_messageModel!.conversation != null && _messageModel!.conversation!.receiverType == 'delivery_man') {
        User? receiver = _messageModel!.conversation!.receiver;
        _messageModel!.conversation!.receiver = _messageModel!.conversation!.sender;
        _messageModel!.conversation!.sender = receiver;
      }
      isSuccess = true;
    } else {
      _isLoading = false;
    }
    update();
    return isSuccess;
  }

  void pickImage(bool isRemove) async {
    final ImagePicker picker = ImagePicker();
    if(isRemove) {
      _imageFiles = [];
      _chatImage = [];
    }else {
      _imageFiles = await picker.pickMultiImage(imageQuality: 30);
      if (_imageFiles != null) {
        _chatImage = imageFiles;
        _isSendButtonActive = true;
      }
    }
    update();
  }
  void removeImage(int index){
    chatImage!.removeAt(index);
    update();
  }

  void toggleSendButtonActivity() {
    _isSendButtonActive = !_isSendButtonActive;
    update();
  }

}
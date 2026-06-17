import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'package:sixam_mart_delivery/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart_delivery/features/chat/controllers/chat_controller.dart';
import 'package:sixam_mart_delivery/features/dashboard/screens/dashboard_screen.dart';
import 'package:sixam_mart_delivery/features/notification/controllers/notification_controller.dart';
import 'package:sixam_mart_delivery/features/order/controllers/order_controller.dart';
import 'package:sixam_mart_delivery/features/notification/domain/models/notification_body_model.dart';
import 'package:sixam_mart_delivery/helper/route_helper.dart';
import 'package:sixam_mart_delivery/util/app_constants.dart';

class NotificationHelper {
  // ===========
  // CHANNELS
  // ===========
  static const String channelIdDefault = '6ammart';
  static const String channelNameDefault = 'Default';

  static const String channelIdRunning = 'running_order';
  static const String channelNameRunning = 'Em corrida';
  static const int notifIdRunning = 3003;

  // Canal “urgente” para corrida (tela cheia)
  static const String channelIdDispatch = 'dispatch_call';
  static const String channelNameDispatch = 'Corridas (Urgente)';

  // Canal “lembrete” para ativar 2º plano
  static const String channelIdReminder = 'enable_background';
  static const String channelNameReminder = 'Ativar 2º plano';

  // IDs fixos para evitar empilhar 30 notificações
  static const int notifIdDispatch = 1001;
  static const int notifIdReminder = 2002;



  // ===========
  // INIT (APP ISOLATE)
  // ===========
  static Future<void> initialize(FlutterLocalNotificationsPlugin fln) async {
    const androidInit = AndroidInitializationSettings('notification_icon');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);



    // Android 13+: pedir permissão de notificação
    await fln
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _createAndroidChannels(fln);


    await fln.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (resp) async {
        try {
          final payloadStr = resp.payload;
          final actionId = resp.actionId; // 'ACCEPT'/'DECLINE'/null
          if (payloadStr == null || payloadStr.isEmpty) return;

          final payload = NotificationBodyModel.fromJson(jsonDecode(payloadStr));

          // Botões Aceitar/Recusar
          if (actionId == 'ACCEPT' || actionId == 'DECLINE') {
            final int? orderId = payload.orderId;

            // Para o serviço/áudio
            await stopService();

            if (orderId == null) return;

            final orderController = Get.find<OrderController>();

            if (actionId == 'ACCEPT') {
              final ok = await orderController.acceptOrderById(orderId);

              if (ok) {
                // 1) cria notificação fixa "Em corrida"
                await NotificationHelper.showRunningOrderOngoing(
                  fln,
                  orderId: orderId,
                );

                // 2) abre a tela de detalhes
                Get.toNamed(
                  RouteHelper.getOrderDetailsRoute(orderId, fromNotification: true),
                );
              }
              return;
            }

            if (actionId == 'DECLINE') {
              // Ignore/recusa
              await orderController.ignoreOrderById(orderId);

              // opcional: limpar notificação fixa se existir
              await NotificationHelper.clearRunningOrderOngoing(fln);

              return;
            }
          }
          // Clique normal na notificação
          final Map<NotificationType, Function> notificationActions = {
            NotificationType.order: () => Get.toNamed(
                  RouteHelper.getOrderDetailsRoute(payload.orderId, fromNotification: true),
                ),
            NotificationType.order_request: () => Get.toNamed(
                  RouteHelper.getMainRoute('order-request'),
                ),
            NotificationType.block: () => Get.offAllNamed(RouteHelper.getSignInRoute()),
            NotificationType.unblock: () => Get.offAllNamed(RouteHelper.getSignInRoute()),
            NotificationType.otp: () => null,
            NotificationType.unassign: () => Get.to(const DashboardScreen(pageIndex: 1)),
            NotificationType.message: () => Get.toNamed(
                  RouteHelper.getChatRoute(
                    notificationBody: payload,
                    conversationId: payload.conversationId,
                    fromNotification: true,
                  ),
                ),
            NotificationType.general: () => Get.toNamed(
                  RouteHelper.getNotificationRoute(fromNotification: true),
                ),
          };

          notificationActions[payload.notificationType]?.call();
        } catch (_) {}
      },
    );

    // =========== FOREGROUND (APP ABERTO) ===========
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      if (kDebugMode) {
        debugPrint("onMessage type:${message.data['type']}");
        debugPrint("onMessage data:${message.data}");
      }

      final type = (message.data['type'] ?? '').toString();

      // Corrida urgente em foreground
      if (_isDispatchType(type)) {
        await _handleDispatchMessage(message, fln);
        return;
      }

      // Resto (mantive sua lógica)
      if (type == 'message' && Get.currentRoute.startsWith(RouteHelper.chatScreen)) {
        if (Get.find<AuthController>().isLoggedIn()) {
          Get.find<ChatController>().getConversationList(1);
          if (Get.find<ChatController>().messageModel!.conversation!.id.toString() ==
              message.data['conversation_id'].toString()) {
            Get.find<ChatController>().getMessages(
              1,
              NotificationBodyModel(
                notificationType: NotificationType.message,
                customerId: message.data['sender_type'] == AppConstants.user ? 0 : null,
                vendorId: message.data['sender_type'] == AppConstants.vendor ? 0 : null,
              ),
              null,
              int.parse(message.data['conversation_id'].toString()),
            );
          } else {
            await showNotification(message, fln);
          }
        }
      } else if (type == 'message' &&
          Get.currentRoute.startsWith(RouteHelper.conversationListScreen)) {
        if (Get.find<AuthController>().isLoggedIn()) {
          Get.find<ChatController>().getConversationList(1);
        }
        await showNotification(message, fln);
      } else if (type == 'otp') {
        await showNotification(message, fln);
      } else {
        if (type != 'assign' && type != 'new_order' && type != 'order_request') {
          await showNotification(message, fln);
          Get.find<OrderController>().getCurrentOrders();
          Get.find<OrderController>().getLatestOrders();
          Get.find<NotificationController>().getNotificationList();
        }
      }
    });

    // ========= OPENED APP (clicou na notif do sistema) =========
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) debugPrint("onOpenApp type:${message.data['type']}");
      try {
        if (message.data.isNotEmpty) {
          final notificationBody = convertNotification(message.data);
          if (notificationBody == null) return;

          if (notificationBody.notificationType == NotificationType.order_request) {
            Get.toNamed(RouteHelper.getMainRoute('order-request'));
            return;
          }

          final Map<NotificationType, Function> notificationActions = {
            NotificationType.order: () => Get.toNamed(
                  RouteHelper.getOrderDetailsRoute(
                    int.parse(message.data['order_id']),
                    fromNotification: true,
                  ),
                ),
            NotificationType.order_request: () => Get.toNamed(
                  RouteHelper.getMainRoute('order-request'),
                ),
            NotificationType.block: () => Get.offAllNamed(RouteHelper.getSignInRoute()),
            NotificationType.unblock: () => Get.offAllNamed(RouteHelper.getSignInRoute()),
            NotificationType.otp: () => null,
            NotificationType.unassign: () => Get.to(const DashboardScreen(pageIndex: 1)),
            NotificationType.message: () => Get.toNamed(
                  RouteHelper.getChatRoute(
                    notificationBody: notificationBody,
                    conversationId: notificationBody.conversationId,
                    fromNotification: true,
                  ),
                ),
            NotificationType.general: () => Get.toNamed(
                  RouteHelper.getNotificationRoute(fromNotification: true),
                ),
          };

          notificationActions[notificationBody.notificationType]?.call();
        }
      } catch (_) {}
    });
  }

  // ===========
  // BACKGROUND: canais “only” (para isolate)
  // ===========
  static Future<void> ensureChannelsOnly(FlutterLocalNotificationsPlugin fln) async {
    final android = fln.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    await android.createNotificationChannel(const AndroidNotificationChannel(
      channelIdRunning,
      channelNameRunning,
      description: 'Notificação fixa para corrida em andamento',
      importance: Importance.low,
    ));

    await android.createNotificationChannel(const AndroidNotificationChannel(
      channelIdDispatch,
      channelNameDispatch,
      description: 'Notificações urgentes para aceitar/recusar corrida',
      importance: Importance.max,
    ));

    await android.createNotificationChannel(const AndroidNotificationChannel(
      channelIdDefault,
      channelNameDefault,
      description: 'Notificações padrão',
      importance: Importance.high,
    ));

    await android.createNotificationChannel(const AndroidNotificationChannel(
      channelIdReminder,
      channelNameReminder,
      description: 'Lembrete para ativar 2º plano',
      importance: Importance.high,
    ));
  }

  static Future<void> showRunningOrderOngoing(
    FlutterLocalNotificationsPlugin fln, {
    required int orderId,
  }) async {
    final nb = NotificationBodyModel(
      orderId: orderId,
      notificationType: NotificationType.order,
    );

    final androidDetails = AndroidNotificationDetails(
      channelIdRunning,
      channelNameRunning,
      channelDescription: 'Corrida em andamento',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
    );

    final details = NotificationDetails(android: androidDetails);

    await fln.show(
      notifIdRunning,
      'Em corrida',
      'Toque para abrir os detalhes (#$orderId)',
      details,
      payload: jsonEncode(nb.toJson()),
    );
  }

  static Future<void> clearRunningOrderOngoing(FlutterLocalNotificationsPlugin fln) async {
    await fln.cancel(notifIdRunning);
  }


  static bool _isDispatchType(String type) {
    return type == 'order_request' || type == 'new_order';
  }

  static Future<void> _handleDispatchMessage(
    RemoteMessage message,
    FlutterLocalNotificationsPlugin fln,
  ) async {
    final nb = convertNotification(message.data);
    if (nb == null) return;

    final title = (message.data['title'] ?? 'Nova corrida').toString();
    final body = (message.data['body'] ?? 'Toque para aceitar ou recusar').toString();

    try {
      await NotificationHelper.showIncomingOrderFullScreen(
        fln: fln,
        title: title,
        body: body,
        notificationBody: nb,
        data: message.data,
      );
      FlutterForegroundTask.initCommunicationPort();
      _initService(repeatMillis: 5000);
      await _startService(nb.orderId?.toString(), nb.notificationType!);
    } catch (_) {
      await showBigTextNotification(title, body, nb, fln);
      await showEnableBackgroundReminder(fln);
    }
  }

  // ===========
  // SHOW NOTIF (GENERIC)
  // ===========
  static Future<void> showNotification(
    RemoteMessage message,
    FlutterLocalNotificationsPlugin fln,
  ) async {
    if (GetPlatform.isIOS) return;

    final title = message.data['title'];
    final body = message.data['body'];
    final image = (message.data['image'] != null && message.data['image'].isNotEmpty)
        ? message.data['image'].startsWith('http')
            ? message.data['image']
            : '${AppConstants.baseUrl}/storage/app/public/notification/${message.data['image']}'
        : null;

    final nb = convertNotification(message.data);

    if (image != null && image.isNotEmpty) {
      try {
        await showBigPictureNotificationHiddenLargeIcon(title, body, nb, image, fln);
      } catch (_) {
        await showBigTextNotification(title, body ?? '', nb, fln);
      }
    } else {
      await showBigTextNotification(title, body ?? '', nb, fln);
    }
  }

static Map<String, String> _formatDispatchPT(Map<String, dynamic> data) {
  final pickup   = _safe(data, 'pickup', fallback: 'Não informado');
  final dropoff  = _safe(data, 'dropoff', fallback: 'Não informado');
  final distance = _safe(data, 'distance_text', fallback: '—');
  final payment  = _ptPaymentLabel(_safe(data, 'payment_method', fallback: '—'));
  final amount   = _safe(data, 'order_amount', fallback: '—');

  return {
    'pickup': pickup,
    'dropoff': dropoff,
    'distance': distance,
    'payment': payment,
    'amount': amount,
  };
}

static String _ptPaymentLabel(String pm) {
  final v = pm.toLowerCase().trim();
  if (v.contains('cash') || v.contains('dinheiro')) return 'Dinheiro';
  if (v.contains('card') || v.contains('cart')) return 'Cartão';
  if (v.contains('pix')) return 'Pix';
  return pm.isEmpty ? 'Não informado' : pm;
}

static String _safe(Map<String, dynamic> data, String key, {String fallback = ''}) {
  final v = (data[key] ?? '').toString().trim();
  return v.isEmpty ? fallback : v;
}

  // ===========
  // FULL SCREEN (DISPATCH)
  // ===========
  static Future<void> showIncomingOrderFullScreen({
    required FlutterLocalNotificationsPlugin fln,
    required String title,
    required String body,
    required NotificationBodyModel notificationBody,
    required Map<String, dynamic> data, // <- adicione isso
  }) async {
    final f = _formatDispatchPT(data);

    final inbox = InboxStyleInformation(
      <String>[
        'Retirada: ${f['pickup']}',
        'Entrega: ${f['dropoff']}',
        'Distância: ${f['distance']}',
        'Pagamento: ${f['payment']}',
        'Valor: ${f['amount']}',
      ],
      contentTitle: 'Nova corrida',
      summaryText: 'Toque para aceitar ou recusar',
    );

    final androidDetails = AndroidNotificationDetails(
      channelIdDispatch,
      channelNameDispatch,
      channelDescription: 'Notificação urgente de corrida',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.call,
      ongoing: true,
      autoCancel: false,
      styleInformation: inbox,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'ACCEPT',
          'Aceitar',
          showsUserInterface: true,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          'DECLINE',
          'Recusar',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
      sound: const RawResourceAndroidNotificationSound('notification'),
    );

    final details = NotificationDetails(android: androidDetails);

    // payload normal (mantém seu roteamento/aceite)
    await fln.show(
      notifIdDispatch,
      'Nova corrida • ${f['distance']} • ${f['amount']}',
      'Retirada: ${f['pickup']}',
      details,
      payload: jsonEncode(notificationBody.toJson()),
    );
  }


  static Future<void> showEnableBackgroundReminder(FlutterLocalNotificationsPlugin fln) async {
    const androidDetails = AndroidNotificationDetails(
      channelIdReminder,
      channelNameReminder,
      channelDescription: 'Lembrete para ativar 2º plano',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );
    const details = NotificationDetails(android: androidDetails);

    await fln.show(
      notifIdReminder,
      'Ative o modo 2º plano',
      'Para receber corridas em tela cheia e com toque contínuo, ative nas permissões do app.',
      details,
      payload: jsonEncode({'type': 'open_settings'}),
    );
  }

  static Future<void> showBigTextNotification(
    String? title,
    String body,
    NotificationBodyModel? notificationBody,
    FlutterLocalNotificationsPlugin fln,
  ) async {
    final bigTextStyle = BigTextStyleInformation(
      body,
      htmlFormatBigText: true,
      contentTitle: title,
      htmlFormatContentTitle: true,
    );

    final androidDetails = AndroidNotificationDetails(
      channelIdDefault,
      AppConstants.appName,
      importance: Importance.max,
      priority: Priority.max,
      styleInformation: bigTextStyle,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('notification'),
    );

    final details = NotificationDetails(android: androidDetails);

    await fln.show(
      0,
      title,
      body,
      details,
      payload: notificationBody != null ? jsonEncode(notificationBody.toJson()) : null,
    );
  }

  static Future<void> showBigPictureNotificationHiddenLargeIcon(
    String? title,
    String? body,
    NotificationBodyModel? notificationBody,
    String image,
    FlutterLocalNotificationsPlugin fln,
  ) async {
    final largeIconPath = await _downloadAndSaveFile(image, 'largeIcon');
    final bigPicturePath = await _downloadAndSaveFile(image, 'bigPicture');

    final bigPictureStyle = BigPictureStyleInformation(
      FilePathAndroidBitmap(bigPicturePath),
      hideExpandedLargeIcon: true,
      contentTitle: title,
      htmlFormatContentTitle: true,
      summaryText: body,
      htmlFormatSummaryText: true,
    );

    final androidDetails = AndroidNotificationDetails(
      channelIdDefault,
      AppConstants.appName,
      largeIcon: FilePathAndroidBitmap(largeIconPath),
      importance: Importance.max,
      priority: Priority.max,
      styleInformation: bigPictureStyle,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('notification'),
    );

    final details = NotificationDetails(android: androidDetails);

    await fln.show(
      0,
      title,
      body,
      details,
      payload: notificationBody != null ? jsonEncode(notificationBody.toJson()) : null,
    );
  }

  static Future<String> _downloadAndSaveFile(String url, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$fileName';
    final response = await http.get(Uri.parse(url));
    final file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return filePath;
  }

  // ===========
  // CHANNELS (app isolate)
  // ===========
  static Future<void> _createAndroidChannels(FlutterLocalNotificationsPlugin fln) async {
    await ensureChannelsOnly(fln);
  }

  // ===========
  // CONVERT
  // ===========
  static NotificationBodyModel? convertNotification(Map<String, dynamic> data) {
    final type = (data['type'] ?? '').toString();
    final orderId = (data['order_id'] ?? '').toString();

    switch (type) {
      case 'new_order':
      case 'order_request':
        return NotificationBodyModel(
          orderId: int.tryParse(orderId),
          notificationType: NotificationType.order_request,
        );

      case 'order_status':
        return NotificationBodyModel(
          orderId: int.tryParse(orderId) ?? 0,
          notificationType: NotificationType.order,
        );

      case 'cash_collect':
        return NotificationBodyModel(notificationType: NotificationType.general);

      case 'unassign':
        return NotificationBodyModel(notificationType: NotificationType.unassign);

      case 'block':
        return NotificationBodyModel(notificationType: NotificationType.block);

      case 'unblock':
        return NotificationBodyModel(notificationType: NotificationType.unblock);

      case 'otp':
        return NotificationBodyModel(notificationType: NotificationType.otp);

      case 'message':
        return _handleMessageNotification(data);

      default:
        return NotificationBodyModel(notificationType: NotificationType.general);
    }
  }

  static NotificationBodyModel _handleMessageNotification(Map<String, dynamic> data) {
    final conversationId = data['conversation_id'];
    final senderType = data['sender_type'];

    return NotificationBodyModel(
      conversationId: (conversationId != null && conversationId.toString().isNotEmpty)
          ? int.tryParse(conversationId.toString())
          : null,
      notificationType: NotificationType.message,
      type: senderType == AppConstants.user ? AppConstants.user : AppConstants.vendor,
    );
  }
}




// ============================================================
// BACKGROUND HANDLER (ISOLATE)
// ============================================================
@pragma('vm:entry-point')
Future<void> myBackgroundMessageHandler(RemoteMessage message) async {
  debugPrint("BG_HANDLER_FIRED data: ${message.data}");

  final type = (message.data['type'] ?? '').toString();
  if (type != 'order_request' && type != 'new_order') return;

  // recomendado para o isolate
  try {
    await Firebase.initializeApp();
  } catch (_) {}

  final nb = NotificationHelper.convertNotification(message.data);
  if (nb == null) return;

  final fln = FlutterLocalNotificationsPlugin();
  const androidInit = AndroidInitializationSettings('notification_icon');
  const iosInit = DarwinInitializationSettings();
  await fln.initialize(const InitializationSettings(android: androidInit, iOS: iosInit));

  // ✅ só canais (sem registrar listeners)
  await NotificationHelper.ensureChannelsOnly(fln);

  // ✅ mostra tela cheia + botões
  await NotificationHelper.showIncomingOrderFullScreen(
    fln: fln,
    title: (message.data['title'] ?? 'Nova corrida').toString(),
    body: (message.data['body'] ?? 'Aceite ou recuse').toString(),
    notificationBody: nb,
    data: message.data, // ✅ ESSENCIAL para Retirada/Entrega/etc
  );

  // ✅ serviço (som repetido)
  FlutterForegroundTask.initCommunicationPort();
  _initService(repeatMillis: 5000);
  await _startService(nb.orderId?.toString(), nb.notificationType!);
}

// ============================================================
// FOREGROUND SERVICE (som repetido)
// ============================================================
final AudioPlayer _audioPlayer = AudioPlayer();

@pragma('vm:entry-point')
Future<ServiceRequestResult> _startService(String? orderId, NotificationType notificationType) async {
  if (await FlutterForegroundTask.isRunningService) {
    return FlutterForegroundTask.restartService();
  }
  return FlutterForegroundTask.startService(
    serviceId: 256,
    notificationTitle: 'Corrida pendente',
    notificationText: 'Aceite ou recuse a corrida.',
    callback: startCallback,
  );
}

@pragma('vm:entry-point')
void _initService({required int repeatMillis}) {
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: NotificationHelper.channelIdDispatch,
      channelName: NotificationHelper.channelNameDispatch,
      channelDescription: 'Serviço em primeiro plano (corridas urgentes)',
      onlyAlertOnce: false,
    ),
    iosNotificationOptions: const IOSNotificationOptions(
      showNotification: false,
      playSound: false,
    ),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.repeat(repeatMillis),
      autoRunOnBoot: false,
      autoRunOnMyPackageReplaced: false,
      allowWakeLock: true,
      allowWifiLock: true,
    ),
  );
}

@pragma('vm:entry-point')
Future<ServiceRequestResult> stopService() async {
  try {
    await _audioPlayer.stop();
    await _audioPlayer.dispose();
  } catch (_) {}
  return FlutterForegroundTask.stopService();
}

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(MyTaskHandler());
}

class MyTaskHandler extends TaskHandler {
  Future<void> _beep() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('notification.mp3'));
    } catch (_) {}
  }

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    await _beep();
  }

  @override
  void onRepeatEvent(DateTime timestamp) async {
    await _beep();
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    await stopService();
  }

  @override
  void onReceiveData(Object data) {}

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp('/');
    stopService();
  }

  @override
  void onNotificationButtonPressed(String id) {
    FlutterForegroundTask.launchApp('/');
    stopService();
  }

  @override
  void onNotificationDismissed() {}
}

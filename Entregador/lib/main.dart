import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:sixam_mart_delivery/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart_delivery/features/language/controllers/language_controller.dart';
import 'package:sixam_mart_delivery/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart_delivery/common/controllers/theme_controller.dart';
import 'package:sixam_mart_delivery/features/notification/domain/models/notification_body_model.dart';
import 'package:sixam_mart_delivery/helper/notification_helper.dart';
import 'package:sixam_mart_delivery/helper/route_helper.dart';
import 'package:sixam_mart_delivery/theme/dark_theme.dart';
import 'package:sixam_mart_delivery/theme/light_theme.dart';
import 'package:sixam_mart_delivery/util/app_constants.dart';
import 'package:sixam_mart_delivery/util/messages.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:url_strategy/url_strategy.dart';

// foreground service
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

// 👇 importa a key global
import 'helper/global_keys.dart';

import 'helper/get_di.dart' as di;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  // Porta de comunicação do flutter_foreground_task (recomendado pela doc)
  FlutterForegroundTask.initCommunicationPort();

  WidgetsFlutterBinding.ensureInitialized();

  // if (!GetPlatform.isWeb) {
  //   HttpOverrides.global = MyHttpOverrides();
  // }

  setPathUrlStrategy();

  // Inicialização do foreground_task (apenas Android)
  if (GetPlatform.isAndroid) {
      FlutterForegroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
          channelId: NotificationHelper.channelIdDispatch,
          channelName: NotificationHelper.channelNameDispatch,
          channelDescription: 'Corridas urgentes',
          onlyAlertOnce: false,
        ),
        iosNotificationOptions: const IOSNotificationOptions(
          showNotification: false,
          playSound: false,
        ),
        foregroundTaskOptions: ForegroundTaskOptions(
          eventAction: ForegroundTaskEventAction.repeat(5000),
          autoRunOnBoot: false,
          autoRunOnMyPackageReplaced: false,
          allowWakeLock: true,
          allowWifiLock: true,
        ),
      );
}

  try {
    // Verificar se o Firebase já está inicializado
    if (Firebase.apps.isEmpty) {
      if (GetPlatform.isAndroid) {
        final firebaseOptions = FirebaseOptions(
          apiKey: 'YOUR_FIREBASE_API_KEY',
          appId: 'YOUR_FIREBASE_APP_ID',
          messagingSenderId: 'YOUR_FIREBASE_MESSAGING_SENDER_ID',
          projectId: 'YOUR_FIREBASE_PROJECT_ID',
        );

        await Firebase.initializeApp(options: firebaseOptions);
        debugPrint('Firebase inicializado com sucesso usando opções explícitas');
      } else {
        await Firebase.initializeApp();
        debugPrint('Firebase inicializado para plataforma não-Android');
      }
    } else {
      debugPrint('Firebase já estava inicializado');
    }
  } catch (e) {
    debugPrint('Erro ao inicializar Firebase: ${e.toString()}');
    // Continue mesmo se o Firebase falhar
  }
  // ✅ COLOQUE AQUI (logo após o Firebase init)
  if (GetPlatform.isMobile) {
    FirebaseMessaging.onBackgroundMessage(myBackgroundMessageHandler);
  }
  Map<String, Map<String, String>> languages = await di.init();

  NotificationBodyModel? body;
  try {
    if (GetPlatform.isMobile) {
      final RemoteMessage? remoteMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (remoteMessage != null) {
        body = NotificationHelper.convertNotification(remoteMessage.data);
      }
      await NotificationHelper.initialize(flutterLocalNotificationsPlugin);
      //FirebaseMessaging.onBackgroundMessage(myBackgroundMessageHandler);
    }
  } catch (_) {}

  runApp(
    // wrapper do foreground_task (para rodar em 2° plano)
    WithForegroundTask(
      child: MyApp(languages: languages, body: body),
    ),
  );
}

class MyApp extends StatelessWidget {
  final Map<String, Map<String, String>>? languages;
  final NotificationBodyModel? body;
  const MyApp({super.key, required this.languages, this.body});

  void _route() {
    Get.find<SplashController>().getConfigData().then((bool isSuccess) async {
      if (isSuccess) {
        if (Get.find<AuthController>().isLoggedIn()) {
          Get.find<AuthController>().updateToken();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (GetPlatform.isWeb) {
      Get.find<SplashController>().initSharedData();
      _route();
    }

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));

    return GetBuilder<ThemeController>(builder: (themeController) {
      return GetBuilder<LocalizationController>(builder: (localizeController) {
        return GetBuilder<SplashController>(builder: (splashController) {
          return (GetPlatform.isWeb && splashController.configModel == null)
              ? const SizedBox()
              : GetMaterialApp(
                  title: AppConstants.appName,
                  debugShowCheckedModeBanner: false,
                  navigatorKey: Get.key,
                  theme: themeController.darkTheme ? dark : light,
                  locale: localizeController.locale,
                  translations: Messages(languages: languages),
                  fallbackLocale: Locale(
                    AppConstants.languages[0].languageCode!,
                    AppConstants.languages[0].countryCode,
                  ),
                  initialRoute: RouteHelper.getSplashRoute(body),
                  getPages: RouteHelper.routes,
                  defaultTransition: Transition.topLevel,
                  transitionDuration: const Duration(milliseconds: 500),

                  // 👇 AQUI ligamos todos os SnackBars na key global
                  scaffoldMessengerKey: rootScaffoldMessengerKey,

                  builder: (BuildContext context, widget) {
                    return MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        textScaler: const TextScaler.linear(1.0),
                      ),
                      child: Material(
                        child: SafeArea(
                          top: false,
                          bottom: GetPlatform.isAndroid,
                          child: Stack(
                            children: [
                              widget!,
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
        });
      });
    });
  }
}

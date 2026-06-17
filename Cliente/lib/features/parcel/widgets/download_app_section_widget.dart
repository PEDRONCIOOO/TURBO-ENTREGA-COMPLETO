import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:url_launcher/url_launcher.dart';

class DownloadAppSectionWidget extends StatelessWidget {
  const DownloadAppSectionWidget({super.key});

  static const String _clientePlayStoreUrl =
      'https://play.google.com/store/apps/details?id=com.turboentregas.cliente';
  static const String _entregadorPlayStoreUrl =
      'https://play.google.com/store/apps/details?id=com.turboentregasv3.motoboy';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF4870C), Color(0xFFFF6B35)],
          ),
          boxShadow: Theme.of(context).brightness == Brightness.dark
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFFF4870C).withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Text + CTAs
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Baixe o App Turbo Entregas',
                    style: robotoBold.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Peça entregas, acompanhe em tempo real e ganhe descontos exclusivos.',
                    style: robotoRegular.copyWith(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.85),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Google Play button
                      InkWell(
                        onTap: () => launchUrl(
                          Uri.parse(_clientePlayStoreUrl),
                          mode: LaunchMode.externalApplication,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                'assets/image/landing_google_play.png',
                                height: 18,
                                width: 18,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.play_arrow_rounded,
                                  size: 18,
                                  color: Color(0xFF111111),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Google Play',
                                style: robotoBold.copyWith(
                                  fontSize: 13,
                                  color: const Color(0xFF111111),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '|',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Secondary link - Entregador
                      InkWell(
                        onTap: () => launchUrl(
                          Uri.parse(_entregadorPlayStoreUrl),
                          mode: LaunchMode.externalApplication,
                        ),
                        child: Text(
                          'Quer ser entregador?',
                          style: robotoRegular.copyWith(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.9),
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 32),
            // QR Code
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: _clientePlayStoreUrl,
                    version: QrVersions.auto,
                    size: 100,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Color(0xFF111111),
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Color(0xFF111111),
                    ),
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'ESCANEIE',
                  style: robotoBold.copyWith(
                    fontSize: 9,
                    color: Colors.white.withValues(alpha: 0.7),
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/util/styles.dart';

class PromoBannerWidget extends StatefulWidget {
  const PromoBannerWidget({super.key});

  @override
  State<PromoBannerWidget> createState() => _PromoBannerWidgetState();
}

class _PromoBannerWidgetState extends State<PromoBannerWidget> {
  late Timer _timer;
  Duration _remaining = const Duration(hours: 47, minutes: 59, seconds: 59);

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining.inSeconds > 0 && mounted) {
        setState(() => _remaining -= const Duration(seconds: 1));
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hours = _remaining.inHours;
    final minutes = _remaining.inMinutes.remainder(60);
    final seconds = _remaining.inSeconds.remainder(60);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF4870C), Color(0xFFFF6B35)],
          ),
        ),
        child: Stack(children: [
          Positioned(right: -20, top: -20, child: Container(
            width: 100, height: 100,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.06)),
          )),
          Row(children: [
            // Left: Promo text
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'PRIMEIRA ENTREGA',
                  style: robotoRegular.copyWith(
                    fontSize: 11, color: Colors.white.withValues(alpha: 0.7),
                    letterSpacing: 2, fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '20% OFF',
                  style: robotoBold.copyWith(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(const ClipboardData(text: 'TURBO20'));
                    showCustomSnackBar('Cupom copiado!', isError: false);
                  },
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(
                      'Use o cupom ',
                      style: robotoRegular.copyWith(fontSize: 13, color: Colors.white.withValues(alpha: 0.85)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(
                          'TURBO20',
                          style: robotoBold.copyWith(fontSize: 13, color: Colors.white, letterSpacing: 1),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.copy_rounded, size: 14, color: Colors.white.withValues(alpha: 0.8)),
                      ]),
                    ),
                  ]),
                ),
              ],
            )),
            // Right: Countdown
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Válido por',
                  style: robotoRegular.copyWith(fontSize: 12, color: Colors.white.withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  _CountdownUnit(value: hours.toString().padLeft(2, '0'), label: 'HRS'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(':', style: robotoBold.copyWith(fontSize: 18, color: Colors.white.withValues(alpha: 0.5))),
                  ),
                  _CountdownUnit(value: minutes.toString().padLeft(2, '0'), label: 'MIN'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(':', style: robotoBold.copyWith(fontSize: 18, color: Colors.white.withValues(alpha: 0.5))),
                  ),
                  _CountdownUnit(value: seconds.toString().padLeft(2, '0'), label: 'SEG'),
                ]),
              ],
            ),
          ]),
        ]),
      ),
    );
  }
}

class _CountdownUnit extends StatelessWidget {
  final String value;
  final String label;

  const _CountdownUnit({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(value, style: robotoBold.copyWith(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
        Text(label, style: robotoRegular.copyWith(fontSize: 9, color: Colors.white.withValues(alpha: 0.6))),
      ]),
    );
  }
}

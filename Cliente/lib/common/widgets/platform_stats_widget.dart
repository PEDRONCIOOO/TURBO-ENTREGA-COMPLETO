import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/styles.dart';

class PlatformStatsWidget extends StatefulWidget {
  const PlatformStatsWidget({super.key});

  @override
  State<PlatformStatsWidget> createState() => _PlatformStatsWidgetState();
}

class _PlatformStatsWidgetState extends State<PlatformStatsWidget> {
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final response = await Get.find<ApiClient>().getData(AppConstants.platformStatsUri);
      if (response.statusCode == 200 && mounted) {
        setState(() => _stats = response.body);
      }
    } catch (_) {
      // Silently fail - widget just won't show
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_stats == null) return const SizedBox();

    final int deliverymen = _stats!['active_deliverymen'] ?? 0;
    final int deliveries = _stats!['total_deliveries'] ?? 0;
    final double rating = (_stats!['avg_rating'] ?? 0).toDouble();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        _StatItem(
          value: _formatNumber(deliveries),
          suffix: '+',
          label: 'Entregas realizadas',
          gradientColors: const [Color(0xFFF4870C), Color(0xFFFF6B35)],
          showBorder: true,
        ),
        _StatItem(
          value: deliverymen.toString(),
          label: 'Entregadores online',
          gradientColors: const [Color(0xFF22C55E), Color(0xFF16A34A)],
          showDot: true,
          showBorder: true,
        ),
        _StatItem(
          value: rating.toStringAsFixed(1),
          suffix: '★',
          label: 'Avaliação média',
          gradientColors: const [Color(0xFFFBBF24), Color(0xFFF59E0B)],
          showBorder: true,
        ),
        _StatItem(
          value: '~25',
          suffix: 'min',
          label: 'Tempo médio',
          gradientColors: const [Color(0xFF6366F1), Color(0xFF4F46E5)],
          showBorder: false,
        ),
      ]),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k';
    return n.toString();
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String? suffix;
  final String label;
  final List<Color> gradientColors;
  final bool showDot;
  final bool showBorder;

  const _StatItem({
    required this.value,
    this.suffix,
    required this.label,
    required this.gradientColors,
    this.showDot = false,
    required this.showBorder,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          border: showBorder
              ? Border(right: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)))
              : null,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              if (showDot) ...[
                Container(
                  width: 8, height: 8,
                  margin: const EdgeInsets.only(right: 6, bottom: 4),
                  decoration: BoxDecoration(
                    color: gradientColors[0],
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: gradientColors[0].withValues(alpha: 0.6), blurRadius: 6)],
                  ),
                ),
              ],
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(colors: gradientColors).createShader(bounds),
                child: Text(
                  value,
                  style: robotoBold.copyWith(fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white, height: 1),
                ),
              ),
              if (suffix != null)
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(colors: gradientColors).createShader(bounds),
                  child: Text(
                    suffix!,
                    style: robotoBold.copyWith(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: robotoRegular.copyWith(fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 10),
          Container(
            width: 24, height: 3,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: LinearGradient(colors: gradientColors),
            ),
          ),
        ]),
      ),
    );
  }
}

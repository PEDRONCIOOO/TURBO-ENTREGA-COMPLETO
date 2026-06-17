import 'package:app_motoboy_turboentregas/util/color_compat.dart';
import 'package:flutter/material.dart';

extension ColorWithValuesCompat on Color {
  Color withValues({double? alpha}) => withOpacity(alpha ?? 1.0);
}

extension MaterialColorWithValuesCompat on MaterialColor {
  Color withValues({double? alpha}) => (this.shade500).withOpacity(alpha ?? 1.0);
}

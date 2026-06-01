import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ColorBlindMode { off, protanopia, deuteranopia, tritanopia }

class AccessibilityService extends ChangeNotifier {
  AccessibilityService._();
  static final AccessibilityService instance = AccessibilityService._();

  static const _keyTextScale = 'titanfit_a11y_text_scale';
  static const _keyBoldText = 'titanfit_a11y_bold_text';
  static const _keyReduceMotion = 'titanfit_a11y_reduce_motion';
  static const _keyColorBlind = 'titanfit_a11y_colorblind';

  double _textScale = 1.0;
  bool _boldText = false;
  bool _reduceMotion = false;
  ColorBlindMode _colorBlind = ColorBlindMode.off;

  double get textScale => _textScale;
  bool get boldText => _boldText;
  bool get reduceMotion => _reduceMotion;
  ColorBlindMode get colorBlindMode => _colorBlind;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _textScale = prefs.getDouble(_keyTextScale) ?? 1.0;
    _boldText = prefs.getBool(_keyBoldText) ?? false;
    _reduceMotion = prefs.getBool(_keyReduceMotion) ?? false;
    _colorBlind = ColorBlindMode.values.byName(
      prefs.getString(_keyColorBlind) ?? 'off',
      orElse: () => ColorBlindMode.off,
    );
    notifyListeners();
  }

  Future<void> setTextScale(double value) async {
    _textScale = value.clamp(0.9, 1.4);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyTextScale, _textScale);
    notifyListeners();
  }

  Future<void> setBoldText(bool value) async {
    _boldText = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBoldText, value);
    notifyListeners();
  }

  Future<void> setReduceMotion(bool value) async {
    _reduceMotion = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyReduceMotion, value);
    notifyListeners();
  }

  Future<void> setColorBlindMode(ColorBlindMode mode) async {
    _colorBlind = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyColorBlind, mode.name);
    notifyListeners();
  }

  List<double> get textScaleOptions => const [1.0, 1.12, 1.24];

  ColorFilter? get colorFilter {
    return switch (_colorBlind) {
      ColorBlindMode.protanopia => const ColorFilter.matrix([
        0.567, 0.433, 0, 0, 0,
        0.558, 0.442, 0, 0, 0,
        0, 0.242, 0.758, 0, 0,
        0, 0, 0, 1, 0,
      ]),
      ColorBlindMode.deuteranopia => const ColorFilter.matrix([
        0.625, 0.375, 0, 0, 0,
        0.7, 0.3, 0, 0, 0,
        0, 0.3, 0.7, 0, 0,
        0, 0, 0, 1, 0,
      ]),
      ColorBlindMode.tritanopia => const ColorFilter.matrix([
        0.95, 0.05, 0, 0, 0,
        0, 0.433, 0.567, 0, 0,
        0, 0.475, 0.525, 0, 0,
        0, 0, 0, 1, 0,
      ]),
      ColorBlindMode.off => null,
    };
  }
}

extension _ByName<T extends Enum> on List<T> {
  T byName(String name, {required T Function() orElse}) {
    for (final v in this) {
      if (v.name == name) return v;
    }
    return orElse();
  }
}

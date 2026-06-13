import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

enum FontSizeOption { small, medium, large, extraLarge }

extension FontSizeExt on FontSizeOption {
  double get scale => switch (this) {
        FontSizeOption.small => 0.85,
        FontSizeOption.medium => 1.0,
        FontSizeOption.large => 1.15,
        FontSizeOption.extraLarge => 1.3,
      };

  String get label => switch (this) {
        FontSizeOption.small => 'Small',
        FontSizeOption.medium => 'Medium',
        FontSizeOption.large => 'Large',
        FontSizeOption.extraLarge => 'X-Large',
      };
}

class AppSettings {
  final ThemeMode themeMode;
  final FontSizeOption fontSize;
  final bool highContrast;
  final bool reducedMotion;
  final bool pushNotifications;
  final bool emailNotifications;
  final bool smsNotifications;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.fontSize = FontSizeOption.medium,
    this.highContrast = false,
    this.reducedMotion = false,
    this.pushNotifications = true,
    this.emailNotifications = true,
    this.smsNotifications = false,
  });

  double get fontSizeScale => fontSize.scale;

  AppSettings copyWith({
    ThemeMode? themeMode,
    FontSizeOption? fontSize,
    bool? highContrast,
    bool? reducedMotion,
    bool? pushNotifications,
    bool? emailNotifications,
    bool? smsNotifications,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        fontSize: fontSize ?? this.fontSize,
        highContrast: highContrast ?? this.highContrast,
        reducedMotion: reducedMotion ?? this.reducedMotion,
        pushNotifications: pushNotifications ?? this.pushNotifications,
        emailNotifications: emailNotifications ?? this.emailNotifications,
        smsNotifications: smsNotifications ?? this.smsNotifications,
      );
}

class SettingsNotifier extends Notifier<AppSettings> {
  late Box _box;

  @override
  AppSettings build() {
    _box = Hive.box('app_settings');
    final modeIndex = (_box.get('themeMode', defaultValue: ThemeMode.system.index) as num).toInt();
    final fontIndex = (_box.get('fontSize', defaultValue: FontSizeOption.medium.index) as num).toInt();
    return AppSettings(
      themeMode: ThemeMode.values[modeIndex.clamp(0, ThemeMode.values.length - 1)],
      fontSize: FontSizeOption.values[fontIndex.clamp(0, FontSizeOption.values.length - 1)],
      highContrast: _box.get('highContrast', defaultValue: false) as bool,
      reducedMotion: _box.get('reducedMotion', defaultValue: false) as bool,
      pushNotifications: _box.get('pushNotifications', defaultValue: true) as bool,
      emailNotifications: _box.get('emailNotifications', defaultValue: true) as bool,
      smsNotifications: _box.get('smsNotifications', defaultValue: false) as bool,
    );
  }

  void setThemeMode(ThemeMode mode) {
    _box.put('themeMode', mode.index);
    state = state.copyWith(themeMode: mode);
  }

  void setFontSize(FontSizeOption option) {
    _box.put('fontSize', option.index);
    state = state.copyWith(fontSize: option);
  }

  void setHighContrast(bool value) {
    _box.put('highContrast', value);
    state = state.copyWith(highContrast: value);
  }

  void setReducedMotion(bool value) {
    _box.put('reducedMotion', value);
    state = state.copyWith(reducedMotion: value);
  }

  void setPushNotifications(bool value) {
    _box.put('pushNotifications', value);
    state = state.copyWith(pushNotifications: value);
  }

  void setEmailNotifications(bool value) {
    _box.put('emailNotifications', value);
    state = state.copyWith(emailNotifications: value);
  }

  void setSmsNotifications(bool value) {
    _box.put('smsNotifications', value);
    state = state.copyWith(smsNotifications: value);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

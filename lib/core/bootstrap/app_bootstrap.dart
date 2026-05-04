import 'package:hive_ce_flutter/hive_flutter.dart';

class AppBootstrap {
  static bool _hiveReady = false;

  static Future<void> init() async {
    if (_hiveReady) return;
    await Hive.initFlutter();
    await Hive.openBox<dynamic>('allinonepdf_box');
    _hiveReady = true;
  }

  static Box<dynamic> get prefsBox => Hive.box<dynamic>('allinonepdf_box');
}

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models.dart';

class LocalStore {
  LocalStore({SharedPreferences? preferences}) : _preferences = preferences;

  static const String storageKey = 'yaseer.app_data.v1';

  final SharedPreferences? _preferences;

  Future<SharedPreferences> _prefs() async =>
      _preferences ?? SharedPreferences.getInstance();

  Future<AppData?> load() async {
    final encoded = (await _prefs()).getString(storageKey);
    if (encoded == null || encoded.trim().isEmpty) return null;

    final decoded = jsonDecode(encoded);
    if (decoded is! Map) {
      throw const FormatException('Saved app data is not a JSON object.');
    }
    return AppData.fromJson(Map<String, dynamic>.from(decoded));
  }

  Future<void> save(AppData data) async {
    final didSave =
        await (await _prefs()).setString(storageKey, jsonEncode(data.toJson()));
    if (!didSave) {
      throw StateError('تعذر حفظ البيانات على هذا الجهاز.');
    }
  }

  Future<void> clear() async {
    final didRemove = await (await _prefs()).remove(storageKey);
    if (!didRemove && (await _prefs()).containsKey(storageKey)) {
      throw StateError('تعذر حذف البيانات المحفوظة على هذا الجهاز.');
    }
  }

  Future<AppData?> loadAppData() => load();

  Future<void> saveAppData(AppData data) => save(data);
}

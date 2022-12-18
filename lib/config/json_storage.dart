import 'dart:convert';
import 'dart:io';

import 'package:rpmlauncher/util/data.dart';
import 'package:rpmlauncher/util/logger.dart';
import 'package:synchronized/synchronized.dart';

class JsonStorage {
  /// Local copy of data.
  Map<String, dynamic>? _cachedData;

  // Use this lock to prevent concurrent access to data
  final _lock = Lock();

  /// The data file.
  final File file;

  JsonStorage(this.file);

  Future<void> init() async {
    await readData();
  }

  /// Gets the data from the stored file. Once read, the data are
  /// maintained in memory.
  Future<Map<String, dynamic>> readData() async {
    Map<String, dynamic> data = {};

    await _lock.synchronized(() async {
      if (_cachedData != null) {
        return _cachedData!;
      }

      if (await file.exists()) {
        final String stringMap = await file.readAsString();
        if (stringMap.isNotEmpty) {
          final Object? data0 = json.decode(stringMap);
          if (data0 is Map) {
            data = data0.cast<String, dynamic>();
          }
        }
      }
      _cachedData = data;
    });

    return data;
  }

  /// Writes the cached data to disk. Returns [true] if the operation
  /// succeeded.
  Future<bool> writeData(Map<String, dynamic> data) async {
    try {
      await _lock.synchronized(() async {
        if (!await file.exists()) {
          await file.create(recursive: true);
        }
        final String stringMap = json.encode(data);
        await file.writeAsString(stringMap);
      });
    } catch (e, s) {
      logger.error(ErrorType.data, 'Error saving the data to disk: $e ($file)',
          stackTrace: s);
      return false;
    }
    return true;
  }

  /// Get the value of the key by the data file.
  T? getItem<T>(String key) {
    Object? value = _cachedData?[key];
    if (value is T) {
      return value;
    } else {
      return null;
    }
  }

  /// Set the value of the key to the data file.
  /// If the value is null, the key will be removed.
  Future<void> setItem<T>(String key, T? value) async {
    final data = await readData();

    if (value == null) {
      data.remove(key);
    } else {
      data[key] = value;
    }

    _cachedData = data;

    await writeData(data);
  }

  operator []=(String key, dynamic value) => setItem(key, value);
  operator [](String key) => getItem(key);

  /// Get all keys and values in the data file.
  Future<Map<String, Object?>> getAll() async {
    final data = await readData();
    _cachedData = data;

    return data;
  }
}

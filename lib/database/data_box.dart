import 'dart:async';
import 'dart:io';

import 'package:hive/hive.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/util/data.dart';
import 'package:uuid/uuid.dart';

class DataBox<K, V> {
  static final List<DataBox> _boxes = [];

  final String uuid;
  final String name;
  final Map<K, V> _mainData;
  final Box<V> _subBox;

  Iterable<K> get keys => _mainData.keys;

  const DataBox._(this.uuid, this.name, this._mainData, this._subBox);

  bool containsKey(K key) {
    return _subBox.containsKey(key) || _mainData.containsKey(key);
  }

  V? get(K key) {
    return _subBox.get(key) ?? _mainData[key];
  }

  Future<void> put(K key, V value) {
    return _subBox.put(key, value);
  }

  Future<void> save() async {
    logger.info('Saving $name');
    final Map map = _subBox.toMap();
    await _subBox.clear();

    final LazyBox mainBox = await Hive.openLazyBox(name);
    await mainBox.putAll(map);
    await mainBox.close();
  }

  Future<void> _close() async {
    logger.info('Closing $name');
    await save();
    await _subBox.deleteFromDisk();
  }

  void _init() {
    _boxes.add(this);
    if (!Platform.isWindows) {
      ProcessSignal.sigterm.watch().forEach((event) async {
        await _close();
      });
    }

    ProcessSignal.sigint.watch().forEach((event) async {
      await _close();
      exit(0);
    });

    /// Auto save data to disk.
    Timer.periodic(const Duration(minutes: 1), (timer) async {
      if (_subBox.toMap().isNotEmpty) {
        await save();
      }
    });
  }

  static Future<DataBox<K, V>> open<K, V>(String name) async {
    final String uuid = const Uuid().v4();
    final Box mainBox = await Hive.openBox(name);
    final Map<K, V> mainData = Map<K, V>.fromIterables(
        mainBox.keys.cast<K>(), mainBox.values.cast<V>());
    try {
      await mainBox.close();
    } on FileSystemException {
      // ignore
    }

    final Box<V> subBox = await Hive.openBox<V>('${name}_$uuid',
        path: join(Directory.systemTemp.path, 'dart_data_box_temp'));

    return DataBox<K, V>._(uuid, name, mainData, subBox).._init();
  }

  static Future<void> close() async {
    for (final DataBox box in _boxes) {
      await box._close();
    }
    _boxes.clear();
  }
}

import 'dart:convert';
import 'dart:io';

class JsonStorage {
  final File _file;
  late Map _data;

  JsonStorage(this._file) {
    try {
      _data = json.decode(_file.readAsStringSync());
    } catch (e) {
      _data = {};
    }
  }

  operator []=(String key, dynamic value) => setItem(key, value);
  operator [](String key) => getItem(key);

  Future<void> removeItem(String key) async {
    _data.remove(key);
    await save();
  }

  /// 儲存變更並且更新資料檔案
  Future<void> setItem(String key, dynamic value) async {
    _data[key] = value;
    await save();
  }

  /// 儲存資料檔案
  Future<void> save() async {
    if (!await _file.exists()) {
      await _file.create(recursive: true);
    }
    await _file.writeAsString(encode);
  }

  // /// 重新從檔案中載入資料
  // void updateData() {
  //   _data = json.decode(_file.readAsStringSync());
  // }

  // 從 key 取得資料
  dynamic getItem(String key) {
    // updateData();
    return _data[key];
  }

  /// 取得資料的 Map
  Map toMap() => _data;

  /// 取得資料的字串，為 json 格式
  String get encode => json.encode(_data);
}

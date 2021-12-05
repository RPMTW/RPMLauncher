import 'dart:convert';
import 'dart:io';

abstract class JsonDataMap {
  final File dataFile;
  late Map rawData;

  JsonDataMap(this.dataFile) {
    try {
      rawData = json.decode(dataFile.readAsStringSync());
    } catch (e) {
      rawData = {};
    }
  }

  void createFile() {
    dataFile.createSync(recursive: true);
  }

  operator []=(String key, dynamic value) => changeValue(key, value);
  operator [](String key) => get(key);

  void remove(String key) {
    rawData.remove(key);
    saveData();
  }

  /// 儲存變更並且更新資料檔案
  void changeValue(String key, dynamic value) {
    rawData[key] = value;
    saveData();
  }

  /// 儲存資料檔案
  void saveData() {
    if (!dataFile.existsSync()) {
      createFile();
    }
    dataFile.writeAsStringSync(json.encode(rawData));
  }

  /// 重新從檔案中載入資料
  void updateData() {
    rawData = json.decode(dataFile.readAsStringSync());
  }

  // 從 key 取得資料
  dynamic get(String key) {
    updateData();
    return rawData[key];
  }

  /// 取得資料的 Map
  Map toMap() => rawData;

  static Map toStaticMap(File file) {
    try {
      return json.decode(file.readAsStringSync());
    } catch (e) {
      file.writeAsStringSync(json.encode({}));
      return {};
    }
  }

  /// 取得資料的字串，為 json 格式
  String get rawDataString => json.encode(rawData);
}

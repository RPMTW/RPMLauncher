import 'dart:collection';

import 'dart:convert';

class Properties with MapMixin<String, String> {
  final Map<String, String> _map = {};
  final comments = <String>[];

  Properties();

  static Properties decode(String text, {String splitChar = "="}) {
    final Properties properties = Properties();
    final List<String> lines = LineSplitter().convert(text);
    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];

      /// 註解處理
      if (line.startsWith('#')) {
        properties.comments.add(line.replaceFirst("#", ""));
        continue;
      } else if (line.isEmpty) {
        continue;
      } else {
        try {
          final kv = line.split(splitChar);
          final k = kv[0];
          final v = kv.getRange(1, (kv.length)).join("");
          properties[k] = v;
        } catch (e) {
          throw DecodePropertiesError('$i 解析失敗，該字串為: $line');
        }
      }
    }

    return properties;
  }

  static encode(Properties properties, {String splitChar = "="}) {
    final lines = <String>[];
    properties.forEach((k, v) {
      lines.add('$k$splitChar$v');
    });
    return lines.join('\n');
  }

  @override
  String? operator [](Object? key) {
    return _map[key];
  }

  @override
  void operator []=(String key, String value) {
    _map[key] = value;
  }

  @override
  void clear() {
    _map.clear();
  }

  @override
  Iterable<String> get keys => _map.keys;

  @override
  String? remove(Object? key) {
    return _map.remove(key);
  }
}

class DecodePropertiesError extends Error {
  final String msg;

  DecodePropertiesError(this.msg);
}

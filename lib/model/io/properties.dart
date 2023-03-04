import 'dart:collection';

import 'dart:convert';

class Properties with MapMixin<String, String> {
  final Map<String, String> _map;
  final List<String> comments;

  const Properties(this._map, {this.comments = const []});

  static Properties decode(String text, {String splitChar = "="}) {
    final Map<String, String> map = {};
    final List<String> comments = [];

    final List<String> lines = const LineSplitter().convert(text);
    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];
      line = line.trim();

      /// 註解處理
      if (line.startsWith('#')) {
        comments.add(line.replaceFirst("#", ""));
        continue;
      } else if (line.isEmpty) {
        continue;
      } else {
        try {
          final kv = line.split(splitChar);
          final k = kv[0];
          final v = kv.getRange(1, (kv.length)).join("");
          map[k] = v;
        } catch (e) {
          throw DecodePropertiesError('$i 解析失敗，該字串為: $line');
        }
      }
    }

    return Properties(map, comments: comments);
  }

  static String encode(Properties properties, {String splitChar = "="}) {
    final List<String> lines = [];
    properties.forEach((k, v) {
      lines.add('$k$splitChar$v');
    });

    for (final comment in properties.comments) {
      lines.insert(0, '#$comment');
    }

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

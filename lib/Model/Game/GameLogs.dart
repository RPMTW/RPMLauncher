import 'dart:collection';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/Utility/I18n.dart';

enum GameLogType { info, warn, error, debug, fatal, unknown }

extension GameLogTypeExtra on GameLogType {
  Widget getText() {
    late Widget text;

    switch (this) {
      case GameLogType.info:
        text = AutoSizeText(
          I18n.format('log.type.info'),
          style: TextStyle(
            color: Colors.lightGreen,
          ),
          textAlign: TextAlign.center,
        );
        break;
      case GameLogType.warn:
        text = AutoSizeText(
          I18n.format('log.type.warn'),
          style: TextStyle(color: Colors.orange.shade500),
          textAlign: TextAlign.center,
        );
        break;
      case GameLogType.error:
        text = AutoSizeText(
          I18n.format('log.type.error'),
          style: TextStyle(
            color: Colors.red,
          ),
          textAlign: TextAlign.center,
        );
        break;
      case GameLogType.debug:
        text = AutoSizeText(I18n.format('log.type.debug'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.deepPurple,
            ));
        break;
      case GameLogType.fatal:
        text = AutoSizeText(
          I18n.format('log.type.fatal'),
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.red.shade800),
        );
        break;
      case GameLogType.unknown:
        text = AutoSizeText(
          I18n.format('log.type.unknown'),
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        );
        break;
    }

    return text;
  }
}

class GameLogs extends ListBase<GameLog> {
  List<GameLog> _list;

  GameLogs(this._list);

  @override
  GameLog operator [](int index) => _list[index];

  @override
  void operator []=(int index, GameLog value) {
    _list[index] = value;
  }

  @override
  int get length => _list.length;

  @override
  set length(int newLength) {
    _list.length = newLength;
  }

  @override
  GameLogs toList({bool growable = true}) =>
      GameLogs(_list.toList(growable: growable));

  @override
  GameLogs getRange(int start, int end, {bool growable = true}) =>
      GameLogs(_list.getRange(start, end).toList());

  GameLogs whereLog(bool Function(GameLog element) test) {
    return GameLogs(super.where(test).toList());
  }

  void addLog(String source) {
    _list.add(GameLog.format(source));
  }

  void addLogs(List<String> sources) {
    sources.forEach((source) => _list.add(GameLog.format(source)));
  }

  String toLogString() {
    return _list.map((e) => e.formattedString).join();
  }

  factory GameLogs.empty() => GameLogs([]);
}

class GameLog {
  final String source;
  final GameLogType type;
  final DateTime time;
  final String formattedString;
  final String thread;

  GameLog(this.source, this.type, this.time, this.formattedString, this.thread);

  static GameLogType parseType(String source) {
    source = getInfoString(source).split('/')[1];
    switch (source) {
      case 'INFO':
        return GameLogType.info;
      case 'WARN':
        return GameLogType.warn;
      case 'ERROR':
        return GameLogType.error;
      case 'DEBUG':
        return GameLogType.debug;
      case 'FATAL':
        return GameLogType.fatal;
      default:
        return GameLogType.unknown;
    }
  }

  static String getTimeString(String source) {
    return source.split('[')[1].split(']')[0];
  }

  static String getInfoString(String source) {
    return source.split('[')[2].split(']')[0];
  }

  static DateTime parseTime(String source) {
    String timeString = getTimeString(source);
    int hour = int.parse(timeString.split(':')[0]);
    int minute = int.parse(timeString.split(':')[1]);
    int second = int.parse(timeString.split(':')[2]);
    DateTime now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute, second);
  }

  static String parseSource(String source) {
    return source
        .split('[${getTimeString(source)}]')[1]
        .split('[${getInfoString(source)}]: ')[1]
        .replaceAll('\n', '');
  }

  static String parseThread(String source) {
    return getInfoString(source).split('/')[0];
  }

  factory GameLog.format(String source) {
    try {
      return GameLog(source, parseType(source), parseTime(source),
          parseSource(source), parseThread(source));
    } catch (e) {
      return GameLog(
          source, GameLogType.unknown, DateTime.now(), source, 'unknown');
    }
  }
}

// ignore_for_file: non_constant_identifier_names, camel_case_types

import 'dart:collection';
import 'dart:convert';
import 'dart:core';
import 'dart:io';

import 'package:path/path.dart';
import 'package:rpmlauncher/Launcher/GameRepository.dart';
import 'package:rpmlauncher/Utility/utility.dart';

class Libraries extends ListBase<Library> {
  List<Library> libraries = [];

  Libraries(List<Library> lib) : libraries = lib;

  factory Libraries.fromList(List libraries) {
    List<Library> libraries_ = [];
    libraries.forEach((library) => libraries_.add(Library.fromJson(library)));
    return Libraries(libraries_);
  }

  String toString() => json.encode(toList());

  List toJson() => libraries.map((library) => library.toJson()).toList();

  @override
  get length => libraries.length;

  @override
  Library operator [](int index) {
    return libraries[index];
  }

  @override
  void operator []=(int index, Library value) {
    libraries[index] = value;
  }

  @override
  void add(Library value) {
    libraries.add(value);
  }

  @override
  set length(int length) => libraries.length = length;
}

class Library {
  final String name;
  final LibraryDownloads downloads;
  List<_rule> rules;
  final _natives? natives;
  bool get isnatives {
    if (natives != null) {
      return parseLibRule();
    } else {
      return natives!.toMap().keys.contains(utility.getOS());
    }
  }

  final String? localPath;

  File? get file => localPath == null ? null : File(localPath!);

  Library(
      {required this.name,
      required this.downloads,
      List<_rule>? rules,
      this.natives,
      this.localPath})
      : rules = rules ?? [];

  factory Library.fromJson(Map json) {
    List<_rule>? rules_ = _rules.fromJson(json['rules'] ?? []).rules;

    return Library(
      name: json['name'],
      downloads: LibraryDownloads.fromJson(json['downloads']),
      rules: rules_,
      natives: _natives?.fromJson(json['natives'] ?? {}),
    );
  }

  bool parseLibRule() {
    if (rules.length > 1) {
      if (rules[0].action == 'allow' &&
          rules[1].action == 'disallow' &&
          rules[1].os!["name"] == 'osx') {
        return utility.getOS() != 'osx';
      } else {
        return false;
      }
    } else if (rules.length == 1) {
      if (rules[0].action == 'allow' && rules[0].os != null)
        return utility.getOS() == 'osx';
    }
    return true;
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> _map = {
      'name': name,
      'downloads': downloads.toJson(),
      'rules': rules
    };
    if (localPath != null) _map['localPath'] = localPath;
    if (natives != null) _map['natives'] = natives!.toMap();
    return _map;
  }

  String toString() => json.encode(toJson());
}

class LibraryDownloads {
  final Artifact artifact;
  final Classifiers? classifiers;

  const LibraryDownloads({required this.artifact, this.classifiers});

  factory LibraryDownloads.fromJson(Map json) {
    Classifiers? classifiers_;

    if (json['classifiers'] != null) {
      json['classifiers']?.containsKey("natives-${Platform.operatingSystem}") ??
              false
          ? Classifiers.fromJson(json['classifiers'])
          : null;
    }

    return LibraryDownloads(
        artifact: Artifact.fromJson(json['artifact']),
        classifiers: classifiers_);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> _map = {
      'artifact': artifact.toMap(),
    };

    if (classifiers != null) _map['classifiers'] = classifiers!.toJson();

    return _map;
  }
}

class _rules {
  final List<_rule> rules;

  const _rules({
    required this.rules,
  });

  factory _rules.fromJson(List? list) {
    if (list != null && list.length > 0) {
      List<_rule> rules_ = [];
      list.forEach((rule) => rules_.add(_rule.fromJson(rule)));
      return _rules(rules: rules_);
    } else {
      return _rules(rules: []);
    }
  }

  Map<String, dynamic> toJson() => {'rules': rules.map((e) => e.toJson()).toList()};
}

class _rule {
  final String action;
  final Map? os;

  const _rule({
    required this.action,
    this.os,
  });

  factory _rule.fromJson(Map json) =>
      _rule(action: json['action'], os: json['os'] ?? {});

  Map<String, dynamic> toJson() =>
      {'action': action, 'os': os == {} ? null : os};
}

class _natives {
  final bool isWindows;
  final bool islinux;
  final bool isosx; //osx -> macos

  const _natives({
    this.isWindows = false,
    this.islinux = false,
    this.isosx = false,
  });

  factory _natives.fromJson(Map json) => _natives(
      isWindows: json.containsKey('windows'),
      islinux: json.containsKey('linux'),
      isosx: json.containsKey('osx'));

  Map<String, String> toMap() {
    Map<String, String> json = {};
    if (isWindows) {
      json['windows'] = 'natives-windows';
    }
    if (islinux) {
      json['linux'] = 'natives-linux';
    }
    if (isosx) {
      json['osx'] = 'natives-macos';
    }
    return json;
  }

  String toJson() => json.encode(toMap());
}

class Artifact {
  final String path; //file save path
  final String url; // file download url
  final String sha1; //file sha1 hash
  final int? size; //File size in bytes

  File get localFile {
    List split_ = path.split("/");
    File _file = File(join(
        GameRepository.getLibraryGlobalDir().path,
        split_.sublist(0, split_.length - 2).join("/"),
        split_[split_.length - 1]));
    return _file;
  }

  const Artifact({
    required this.path,
    required this.url,
    required this.sha1,
    this.size,
  });

  factory Artifact.fromJson(Map json) => Artifact(
      path: json['path'],
      url: json['url'],
      sha1: json['sha1'],
      size: json['size']);

  Map<String, dynamic> toMap() =>
      {'path': path, 'url': url, 'sha1': sha1, 'size': size};

  String toJson() => json.encode(toMap());
}

class Classifiers {
  final String path; //file save path
  final String url; // file download url
  final String sha1; //file sha1 hash
  final int size; //File size in bytes

  const Classifiers(
      {required this.path,
      required this.url,
      required this.sha1,
      required this.size});

  factory Classifiers.fromJson(Map json) {
    var SystemNatives = json["natives-${Platform.operatingSystem}"];

    return Classifiers(
        path: SystemNatives['path'],
        url: SystemNatives['url'],
        sha1: SystemNatives['sha1'],
        size: SystemNatives['size']);
  }

  Map<String, dynamic> toMap() =>
      {'path': path, 'url': url, 'sha1': sha1, 'size': size};

  String toJson() => json.encode(toMap());
}

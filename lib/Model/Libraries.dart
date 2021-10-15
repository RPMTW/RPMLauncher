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
    libraries.forEach((library) {
      libraries_.add(Library.fromJson(library));
    });
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

  List<File> getLibrariesFiles() {
    List<File> files = [];
    libraries.forEach((Library library) {
      Artifact _artifact = library.downloads.artifact;
      if (_artifact.localFile.existsSync()) {
        files.add(_artifact.localFile);
      }
    });
    return files;
  }

  String getLibrariesLauncherArgs(File ClientJar) {
    List<File> _files = [ClientJar];
    _files.addAll(getLibrariesFiles());
    return _files.map((File file) => file.path).join(utility.getSeparator());
  }
}

class Library {
  final String name;
  final LibraryDownloads downloads;
  LibraryRules? rules;
  final LibraryNatives? natives;
  bool get isnatives =>
      natives != null && (natives!.isnatives || parseLibRule());

  Library(
      {required this.name, required this.downloads, this.rules, this.natives});

  factory Library.fromJson(Map _json) {
    if (_json['rules'] is LibraryRules) {
      _json['rules'] = (_json['rules'] as LibraryRules).toJson();
    }

    LibraryRules? rules_ =
        _json['rules'] != null ? LibraryRules.fromJson(_json['rules']) : null;
    return Library(
      name: _json['name'],
      rules: rules_,
      downloads: LibraryDownloads.fromJson(_json['downloads']),
      natives: _json['natives'] != null
          ? LibraryNatives.fromJson(_json['natives'])
          : null,
    );
  }

  bool parseLibRule() {
    if (rules != null) {
      if (rules!.length > 1) {
        if (rules![0].action == 'allow' &&
            rules![1].os == 'disallow' &&
            rules![1].os!["name"] == 'osx') {
          return utility.getOS() != 'osx';
        } else {
          return false;
        }
      } else {
        if (rules![0].action == 'allow' && rules![0].os != null)
          return utility.getOS() == 'osx';
      }
    }
    return true;
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> _map = {
      'name': name,
      'downloads': downloads.toJson(),
    };
    if (natives != null) _map['natives'] = natives!.toMap();
    if (rules != null) _map['rules'] = rules;
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

    if (json['classifiers'] != null && json['classifiers'] is Map) {
      if (json['classifiers']
          .containsKey("natives-${Platform.operatingSystem}")) {
        classifiers_ = Classifiers.fromJson(json['classifiers']);
      }
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

class LibraryRules extends ListBase<LibraryRule> {
  final List<LibraryRule> rules;

  LibraryRules({
    required this.rules,
  });

  factory LibraryRules.fromJson(List list) {
    List<LibraryRule> rules_ = [];
    list.forEach((rule) {
      if (rule is LibraryRule) {
        rules_.add(rule);
      } else {
        rules_.add(LibraryRule.fromJson(rule as Map));
      }
    });
    return LibraryRules(rules: rules_);
  }

  List<LibraryRule> toJson() => rules.toList();

  @override
  int get length => rules.length;

  @override
  set length(int length) => rules.length = length;

  @override
  LibraryRule operator [](int index) {
    return rules[index];
  }

  @override
  void operator []=(int index, LibraryRule value) {
    rules[index] = value;
  }
}

class LibraryRule {
  final String action;
  final Map? os;

  const LibraryRule({
    required this.action,
    this.os,
  });

  factory LibraryRule.fromJson(Map json) =>
      LibraryRule(action: json['action'], os: json['os'] ?? {});

  Map<String, dynamic> toJson() =>
      {'action': action, 'os': os == {} ? null : os};
}

class LibraryNatives {
  final bool isWindows;
  final bool islinux;
  final bool isosx; //osx -> macos
  bool get isnatives {
    if (Platform.isLinux) {
      return islinux;
    } else if (Platform.isWindows) {
      return isWindows;
    } else if (Platform.isMacOS) {
      return isosx;
    } else {
      return false;
    }
  }

  const LibraryNatives({
    this.isWindows = false,
    this.islinux = false,
    this.isosx = false,
  });

  factory LibraryNatives.fromJson(Map json) => LibraryNatives(
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

  File get localFile =>
      File(join(GameRepository.getLibraryGlobalDir().path, path));

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

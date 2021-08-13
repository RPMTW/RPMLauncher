import 'dart:io';

import 'package:RPMLauncher/Utility/utility.dart';

class Libraries {
  final List<Library> libraries;

  const Libraries({
    required this.libraries,
  });

  factory Libraries.fromList(List libraries) {
    List<Library> libraries_ = [];
    libraries.forEach((library) => libraries_.add(Library.fromJson(library)));
    return Libraries(libraries: libraries_);
  }
  List<Library> toList() => libraries;
}

class Library {
  final String name;
  final _downloads downloads;
  final List<_rule>? rules;
  final _natives? natives;
  final bool isnatives;

  const Library(
      {required this.name,
      required this.downloads,
      this.rules = null,
      this.natives = null,
      this.isnatives = false});

  factory Library.fromJson(Map json) {
    List<_rule>? rules_ = _rules.fromJson(json['rules'] ?? []).rules;
    bool ParseLibRule() {
      if (rules_ != null) {
        if (rules_.length > 1) {
          if (rules_[0].action == 'allow' &&
              rules_[1].os == 'disallow' &&
              rules_[1].os!["name"] == 'osx') {
            return utility.getOS() != 'osx';
          } else {
            return false;
          }
        } else {
          if (rules_[0].action == 'allow' && rules_[0].os != null)
            return utility.getOS() == 'osx';
        }
      }
      return true;
    }

    return Library(
        name: json['name'],
        downloads: _downloads.fromJson(json['downloads']),
        rules: rules_,
        natives: _natives?.fromJson(json['natives'] ?? {}),
        isnatives: json['natives'] != null &&
                json["natives"].keys.contains(utility.getOS()) ||
            ParseLibRule());
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'downloads': downloads.toJson(),
        'rules': rules ?? [],
        'natives': natives?.toJson(),
        'isnatives': isnatives
      };
}

class _downloads {
  final Artifact artifact;
  final Classifiers? classifiers;

  const _downloads({required this.artifact, this.classifiers = null});

  factory _downloads.fromJson(Map json) => _downloads(
      artifact: Artifact.fromJson(json['artifact']),
      classifiers: json['classifiers']
                  ?.containsKey("natives-${Platform.operatingSystem}") ??
              false
          ? Classifiers.fromJson(json['classifiers'])
          : null);

  Map<String, dynamic> toJson() =>
      {'artifact': artifact.toJson(), 'classifiers': classifiers?.toJson()};
}

class _rules {
  final List<_rule>? rules;

  const _rules({
    required this.rules,
  });

  factory _rules.fromJson(List? list) {
    if (list != null && list.length > 0) {
      List<_rule> rules_ = [];
      list.forEach((rule) => rules_.add(_rule.fromJson(rule)));
      return _rules(rules: rules_);
    } else {
      return _rules(rules: null);
    }
  }

  Map<String, dynamic> toJson() => {'rules': rules};
}

class _rule {
  final String action;
  final Map? os;

  const _rule({
    required this.action,
    this.os = null,
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

  Map<String, String> toJson() {
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
}

class Artifact {
  final String path; //file save path
  final String url; // file download url
  final String sha1; //file sha1 hash
  final int size; //File size in bytes

  const Artifact({
    required this.path,
    required this.url,
    required this.sha1,
    required this.size,
  });

  factory Artifact.fromJson(Map json) => Artifact(
      path: json['path'],
      url: json['url'],
      sha1: json['sha1'],
      size: json['size']);

  Map<String, dynamic> toJson() =>
      {'path': path, 'url': url, 'sha1': sha1, 'size': size};
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

  Map<String, dynamic> toJson() =>
      {'path': path, 'url': url, 'sha1': sha1, 'size': size};
}

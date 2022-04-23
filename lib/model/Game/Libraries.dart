import 'dart:collection';
import 'dart:convert';
import 'dart:core';
import 'dart:io';

import 'package:path/path.dart';
import 'package:pub_semver/pub_semver.dart';

import 'package:rpmlauncher/launcher/GameRepository.dart';
import 'package:rpmlauncher/util/util.dart';

class Libraries extends ListBase<Library> {
  List<Library> _libraries = [];

  Libraries(List<Library> lib) : _libraries = lib;

  factory Libraries.fromList(List libraries) {
    List<Library> libraries_ = [];
    libraries.forEach((library) {
      libraries_.add(Library.fromMap(library));
    });
    return Libraries(libraries_);
  }

  @override
  String toString() => json.encode(toList());

  List<Map<String, dynamic>> toJson() =>
      _libraries.map((library) => library.toJson()).toList();

  @override
  get length => _libraries.length;

  @override
  Library operator [](int index) {
    return _libraries[index];
  }

  @override
  void operator []=(int index, Library value) {
    _libraries[index] = value;
  }

  @override
  void add(Library element) {
    _libraries.add(element);
  }

  @override
  set length(int length) => _libraries.length = length;

  List<File> getLibrariesFiles() {
    final List<File> files = [];
    final List<Library> needLibraries =
        _libraries.where((library) => library.need).toList();

    /// 處理重複的函式庫並保留最新版本
    final List<String> librariesName =
        needLibraries.map((e) => e.packageName).toList();
    final Set<String> librariesNameSet = librariesName.toSet();

    if (librariesName.length > librariesNameSet.length) {
      librariesNameSet.forEach((name) {
        List<Library> duplicateLibraries =
            needLibraries.where((lib) => lib.packageName == name).toList();

        /// Detected duplicate libraries
        if (duplicateLibraries.length > 1) {
          Library keepLibrary = (duplicateLibraries
                ..sort((a, b) =>
                    a.comparableVersion.compareTo(b.comparableVersion)))
              .last;

          List<Library> needDeleteLibraries =
              duplicateLibraries.where((lib) => lib != keepLibrary).toList();
          needDeleteLibraries.forEach(needLibraries.remove);
        }
      });
    }

    needLibraries.forEach((Library library) {
      Artifact? artifact = library.downloads.artifact;
      if (artifact != null) {
        if (artifact.localFile.existsSync()) {
          files.add(artifact.localFile);
        }
      }
    });

    files.toSet().toList();

    return files;
  }

  String getLibrariesLauncherArgs(File? clientJar) {
    List<File> files = [
      ...(clientJar != null ? [clientJar] : [])
    ];
    files.addAll(getLibrariesFiles());
    return files.map((File file) => file.path).join(Util.getLibrarySeparator());
  }
}

class Library {
  final String name;
  final LibraryDownloads downloads;
  final LibraryRules? rules;
  final LibraryNatives? natives;
  bool get need => parseLibRule() || (natives != null && (natives!.isNatives));

  String get packageName {
    return name.replaceAll(":$version", '');
  }

  String get version => name.split(':').last;

  Version get comparableVersion {
    try {
      return Version.parse(version);
    } catch (e) {
      try {
        return Version.parse("$version.0");
      } catch (e) {
        return Version.none;
      }
    }
  }

  const Library(
      {required this.name, required this.downloads, this.rules, this.natives});

  factory Library.fromMap(Map map) {
    if (map['rules'] is LibraryRules) {
      map['rules'] = (map['rules'] as LibraryRules).toMap();
    }

    return Library(
      name: map['name'],
      rules: map['rules'] != null ? LibraryRules.fromJson(map['rules']) : null,
      downloads: LibraryDownloads.fromJson(map['downloads']),
      natives: map['natives'] != null
          ? LibraryNatives.fromJson(map['natives'])
          : null,
    );
  }

  bool parseLibRule() {
    bool need = true;
    if (rules != null) {
      if (rules!.isNotEmpty) {
        rules!.forEach((rule) {
          if (rule.features != null) {
            need = false;
            return;
          }
          if (rule.os == null ||
              (rule.os != null &&
                  rule.os!['name'] == Util.getMinecraftFormatOS())) {
            if (rule.action == 'allow') {
              need = true;
            } else if (rule.action == 'disallow') {
              need = false;
            }
          }
        });
      }
    }
    return need;
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {
      'name': name,
      'downloads': downloads.toJson(),
    };
    if (natives != null) map['natives'] = natives!.toMap();
    if (rules != null) map['rules'] = rules?.map((e) => e.toMap()).toList();
    return map;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Library &&
        other.name == name &&
        other.downloads == downloads &&
        other.natives == natives;
  }

  @override
  int get hashCode => name.hashCode ^ downloads.hashCode ^ natives.hashCode;
}

class LibraryDownloads {
  final Artifact? artifact;
  final Classifiers? classifiers;

  const LibraryDownloads({required this.artifact, this.classifiers});

  factory LibraryDownloads.fromJson(Map json) {
    Classifiers? classifiers;
    Artifact? artifact;

    dynamic classifiersMap = json['classifiers'];

    if (classifiersMap is Map &&
        (classifiersMap.containsKey("natives-${Platform.operatingSystem}") ||
            classifiersMap
                .containsKey("natives-${Util.getMinecraftFormatOS()}"))) {
      classifiers = Classifiers.fromJson(json['classifiers']);
    }

    if (json['artifact'] != null && json['artifact'] is Map) {
      artifact = Artifact.fromJson(json['artifact']);
    }

    return LibraryDownloads(artifact: artifact, classifiers: classifiers);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {};

    if (artifact != null) map['artifact'] = artifact!.toJson();
    if (classifiers != null) map['classifiers'] = classifiers!.toJson();

    return map;
  }
}

class LibraryRules extends ListBase<LibraryRule> {
  final List<LibraryRule> rules;

  LibraryRules({
    required this.rules,
  });

  factory LibraryRules.fromJson(List list) {
    List<LibraryRule> rules = [];
    list.forEach((rule) {
      rules.add(LibraryRule.fromMap(rule));
    });
    return LibraryRules(rules: rules);
  }

  List<Map> toMap() => rules.map((e) => e.toMap()).toList();

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
  final Map? features;

  const LibraryRule({required this.action, this.os, this.features});

  factory LibraryRule.fromMap(Map json) => LibraryRule(
      action: json['action'], os: json['os'], features: json['features']);

  Map<String, dynamic> toMap() {
    return {
      'action': action,
      if (os != null) 'os': os,
      if (features != null) 'features': features,
    };
  }
}

class LibraryNatives {
  final bool isWindows;
  final bool isLinux;
  final bool isOSX; //osx -> macos
  bool get isNatives {
    if (Platform.isLinux) {
      return isLinux;
    } else if (Platform.isWindows) {
      return isWindows;
    } else if (Platform.isMacOS) {
      return isOSX;
    } else {
      return false;
    }
  }

  const LibraryNatives({
    this.isWindows = false,
    this.isLinux = false,
    this.isOSX = false,
  });

  factory LibraryNatives.fromJson(Map json) => LibraryNatives(
      isWindows: json.containsKey('windows'),
      isLinux: json.containsKey('linux'),
      isOSX: json.containsKey('osx'));

  Map<String, String> toMap() {
    Map<String, String> json = {};
    if (isWindows) {
      json['windows'] = 'natives-windows';
    }
    if (isLinux) {
      json['linux'] = 'natives-linux';
    }
    if (isOSX) {
      json['osx'] = 'natives-macos';
    }
    return json;
  }

  String toJson() => json.encode(toMap());
}

class Artifact {
  final String path; //file save path
  final String url; // file download url
  final String? sha1; //file sha1 hash
  final int? size; //File size in bytes

  File get localFile =>
      File(join(GameRepository.getLibraryGlobalDir().path, path));

  const Artifact({
    required this.path,
    required this.url,
    this.sha1,
    this.size,
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
    Map systemNatives = json["natives-${Platform.operatingSystem}"] ??
        json["natives-${Util.getMinecraftFormatOS()}"];

    return Classifiers(
        path: systemNatives['path'],
        url: systemNatives['url'],
        sha1: systemNatives['sha1'],
        size: systemNatives['size']);
  }

  Map<String, dynamic> toJson() => {
        'natives-${Platform.operatingSystem}': {
          'path': path,
          'url': url,
          'sha1': sha1,
          'size': size
        }
      };
}

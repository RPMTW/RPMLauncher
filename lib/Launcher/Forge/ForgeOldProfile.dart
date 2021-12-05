import 'dart:convert';

import 'package:flutter/foundation.dart';

class ForgeOldProfile {
  final Install install;
  final VersionInfo versionInfo;
  ForgeOldProfile({
    required this.install,
    required this.versionInfo,
  });

  ForgeOldProfile copyWith({
    Install? install,
    VersionInfo? versionInfo,
    List<dynamic>? optionals,
  }) {
    return ForgeOldProfile(
        install: install ?? this.install,
        versionInfo: versionInfo ?? this.versionInfo);
  }

  Map<String, dynamic> toMap() {
    return {'install': install.toMap(), 'versionInfo': versionInfo.toMap()};
  }

  factory ForgeOldProfile.fromMap(Map<String, dynamic> map) {
    return ForgeOldProfile(
      install: Install.fromMap(map['install']),
      versionInfo: VersionInfo.fromMap(map['versionInfo']),
    );
  }

  String toJson() => json.encode(toMap());

  factory ForgeOldProfile.fromJson(String source) =>
      ForgeOldProfile.fromMap(json.decode(source));

  @override
  String toString() =>
      'ForgeOldProfile(install: $install, versionInfo: $versionInfo)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ForgeOldProfile &&
        other.install == install &&
        other.versionInfo == versionInfo;
  }

  @override
  int get hashCode => install.hashCode ^ versionInfo.hashCode;
}

class Install {
  final String profileName;
  final String target;
  final String path;
  final String version;
  final String filePath;
  final String welcome;
  final String minecraft;
  final String mirrorList;
  final String logo;
  final String? modList;
  Install({
    required this.profileName,
    required this.target,
    required this.path,
    required this.version,
    required this.filePath,
    required this.welcome,
    required this.minecraft,
    required this.mirrorList,
    required this.logo,
    required this.modList,
  });

  Install copyWith({
    String? profileName,
    String? target,
    String? path,
    String? version,
    String? filePath,
    String? welcome,
    String? minecraft,
    String? mirrorList,
    String? logo,
    String? modList,
  }) {
    return Install(
      profileName: profileName ?? this.profileName,
      target: target ?? this.target,
      path: path ?? this.path,
      version: version ?? this.version,
      filePath: filePath ?? this.filePath,
      welcome: welcome ?? this.welcome,
      minecraft: minecraft ?? this.minecraft,
      mirrorList: mirrorList ?? this.mirrorList,
      logo: logo ?? this.logo,
      modList: modList ?? this.modList,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'profileName': profileName,
      'target': target,
      'path': path,
      'version': version,
      'filePath': filePath,
      'welcome': welcome,
      'minecraft': minecraft,
      'mirrorList': mirrorList,
      'logo': logo,
      'modList': modList,
    };
  }

  factory Install.fromMap(Map<String, dynamic> map) {
    return Install(
      profileName: map['profileName'],
      target: map['target'],
      path: map['path'],
      version: map['version'],
      filePath: map['filePath'],
      welcome: map['welcome'],
      minecraft: map['minecraft'],
      mirrorList: map['mirrorList'],
      logo: map['logo'],
      modList: map['modList'],
    );
  }

  String toJson() => json.encode(toMap());

  factory Install.fromJson(String source) =>
      Install.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Install(profileName: $profileName, target: $target, path: $path, version: $version, filePath: $filePath, welcome: $welcome, minecraft: $minecraft, mirrorList: $mirrorList, logo: $logo, modList: $modList)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Install &&
        other.profileName == profileName &&
        other.target == target &&
        other.path == path &&
        other.version == version &&
        other.filePath == filePath &&
        other.welcome == welcome &&
        other.minecraft == minecraft &&
        other.mirrorList == mirrorList &&
        other.logo == logo &&
        other.modList == modList;
  }

  @override
  int get hashCode {
    return profileName.hashCode ^
        target.hashCode ^
        path.hashCode ^
        version.hashCode ^
        filePath.hashCode ^
        welcome.hashCode ^
        minecraft.hashCode ^
        mirrorList.hashCode ^
        logo.hashCode ^
        modList.hashCode;
  }
}

class VersionInfo {
  final String id;
  final String time;
  final String releaseTime;
  final String type;
  final String minecraftArguments;
  final String mainClass;
  final String inheritsFrom;
  final String jar;
  final List<Librarie> libraries;
  VersionInfo({
    required this.id,
    required this.time,
    required this.releaseTime,
    required this.type,
    required this.minecraftArguments,
    required this.mainClass,
    required this.inheritsFrom,
    required this.jar,
    required this.libraries,
  });

  VersionInfo copyWith({
    String? id,
    String? time,
    String? releaseTime,
    String? type,
    String? minecraftArguments,
    String? mainClass,
    String? inheritsFrom,
    String? jar,
    List<Librarie>? libraries,
  }) {
    return VersionInfo(
      id: id ?? this.id,
      time: time ?? this.time,
      releaseTime: releaseTime ?? this.releaseTime,
      type: type ?? this.type,
      minecraftArguments: minecraftArguments ?? this.minecraftArguments,
      mainClass: mainClass ?? this.mainClass,
      inheritsFrom: inheritsFrom ?? this.inheritsFrom,
      jar: jar ?? this.jar,
      libraries: libraries ?? this.libraries,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'time': time,
      'releaseTime': releaseTime,
      'type': type,
      'minecraftArguments': minecraftArguments,
      'mainClass': mainClass,
      'inheritsFrom': inheritsFrom,
      'jar': jar,
      'libraries': libraries.map((x) => x.toMap()).toList(),
    };
  }

  factory VersionInfo.fromMap(Map<String, dynamic> map) {
    return VersionInfo(
      id: map['id'],
      time: map['time'],
      releaseTime: map['releaseTime'],
      type: map['type'],
      minecraftArguments: map['minecraftArguments'],
      mainClass: map['mainClass'],
      inheritsFrom: map['inheritsFrom'],
      jar: map['jar'],
      libraries: List<Librarie>.from(
          map['libraries']?.map((x) => Librarie.fromMap(x))),
    );
  }

  String toJson() => json.encode(toMap());

  factory VersionInfo.fromJson(String source) =>
      VersionInfo.fromMap(json.decode(source));

  @override
  String toString() {
    return 'VersionInfo(id: $id, time: $time, releaseTime: $releaseTime, type: $type, minecraftArguments: $minecraftArguments, mainClass: $mainClass, inheritsFrom: $inheritsFrom, jar: $jar, libraries: $libraries)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is VersionInfo &&
        other.id == id &&
        other.time == time &&
        other.releaseTime == releaseTime &&
        other.type == type &&
        other.minecraftArguments == minecraftArguments &&
        other.mainClass == mainClass &&
        other.inheritsFrom == inheritsFrom &&
        other.jar == jar &&
        listEquals(other.libraries, libraries);
  }

  @override
  int get hashCode {
    return id.hashCode ^
        time.hashCode ^
        releaseTime.hashCode ^
        type.hashCode ^
        minecraftArguments.hashCode ^
        mainClass.hashCode ^
        inheritsFrom.hashCode ^
        jar.hashCode ^
        libraries.hashCode;
  }
}

class Librarie {
  final String name;
  final String? url;
  Librarie({
    required this.name,
    required this.url,
  });

  Librarie copyWith({
    String? name,
    String? url,
  }) {
    return Librarie(
      name: name ?? this.name,
      url: url ?? this.url,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'url': url,
    };
  }

  factory Librarie.fromMap(Map<String, dynamic> map) {
    return Librarie(
      name: map['name'],
      url: map['url'],
    );
  }

  String toJson() => json.encode(toMap());

  factory Librarie.fromJson(String source) =>
      Librarie.fromMap(json.decode(source));

  @override
  String toString() => 'Librarie(name: $name, url: $url)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Librarie && other.name == name && other.url == url;
  }

  @override
  int get hashCode => name.hashCode ^ url.hashCode;
}

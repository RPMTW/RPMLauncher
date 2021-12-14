import 'dart:collection';
import 'dart:convert';

class FabricInstallerVersions extends ListMixin<FabricInstallerVersion> {
  List<FabricInstallerVersion> _versions;

  FabricInstallerVersions(
    this._versions,
  );

  factory FabricInstallerVersions.fromJson(String str) =>
      FabricInstallerVersions.fromList(
          json.decode(str).cast<Map<String, dynamic>>());

  String toJson() => json.encode(toList());

  static FabricInstallerVersions fromList(List<Map<String, dynamic>> list) =>
      FabricInstallerVersions(
        list.map((e) => FabricInstallerVersion.fromMap(e)).toList(),
      );

  @override
  int get length => _versions.length;

  @override
  set length(int newLength) {
    _versions.length = newLength;
  }

  @override
  FabricInstallerVersion operator [](int index) {
    return _versions[index];
  }

  @override
  void operator []=(int index, FabricInstallerVersion value) {
    _versions[index] = value;
  }
}

class FabricInstallerVersion {
  final String url;
  final String maven;
  final String version;
  final bool stable;
  FabricInstallerVersion({
    required this.url,
    required this.maven,
    required this.version,
    required this.stable,
  });

  FabricInstallerVersion copyWith({
    String? url,
    String? maven,
    String? version,
    bool? stable,
  }) {
    return FabricInstallerVersion(
      url: url ?? this.url,
      maven: maven ?? this.maven,
      version: version ?? this.version,
      stable: stable ?? this.stable,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'maven': maven,
      'version': version,
      'stable': stable,
    };
  }

  factory FabricInstallerVersion.fromMap(Map<String, dynamic> map) {
    return FabricInstallerVersion(
      url: map['url'] ?? '',
      maven: map['maven'] ?? '',
      version: map['version'] ?? '',
      stable: map['stable'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory FabricInstallerVersion.fromJson(String source) =>
      FabricInstallerVersion.fromMap(json.decode(source));

  @override
  String toString() {
    return 'FabricInstallerVersion(url: $url, maven: $maven, version: $version, stable: $stable)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FabricInstallerVersion &&
        other.url == url &&
        other.maven == maven &&
        other.version == version &&
        other.stable == stable;
  }

  @override
  int get hashCode {
    return url.hashCode ^ maven.hashCode ^ version.hashCode ^ stable.hashCode;
  }
}

import 'package:dio_http/dio_http.dart';

class MCVersionManifest {
  String latestRelease;

  String latestSnapshot;

  List<MCVersion> versions;

  MCVersionManifest(this.latestRelease, this.latestSnapshot, this.versions);

  factory MCVersionManifest.fromJson(Map data) {
    return MCVersionManifest(
        data['latest']['release'],
        data['latest']['snapshot'],
        (data['versions'] as List<dynamic>)
            .map((d) => MCVersion.fromJson(d))
            .toList());
  }
}

class MCVersion {
  String id;

  MCVersionType type;

  String url;

  String time;

  String releaseTime;

  String sha1;

  int complianceLevel;

  DateTime get timeDateTime => DateTime.parse(time);

  DateTime get releaseDateTime => DateTime.parse(releaseTime);

  Future<Map<String, dynamic>> get meta async => (await Dio().get(url)).data;

  MCVersion(this.id, this.type, this.url, this.time, this.releaseTime,
      this.sha1, this.complianceLevel);

  factory MCVersion.fromJson(Map json) {
    return MCVersion(
        json['id'],
        MCVersionType.values.firstWhere((_) => _.name == json['type']),
        json['url'],
        json['time'],
        json['releaseTime'],
        json['sha1'],
        json['complianceLevel']);
  }
}

enum MCVersionType {
  release,
  snapshot,
  beta,
  alpha,
}

extension MCVersionTypeExtension on MCVersionType {
  String get name {
    switch (this) {
      case MCVersionType.release:
        return 'release';
      case MCVersionType.snapshot:
        return 'snapshot';
      case MCVersionType.beta:
        return 'old_beta';
      case MCVersionType.alpha:
        return 'old_alpha';
    }
  }
}

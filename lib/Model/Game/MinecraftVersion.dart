class MCVersionManifest {
  String latestRelease;

  String latestSnapshot;

  List<MCVersion> versions;

  MCVersionManifest(this.latestRelease, this.latestSnapshot, this.versions);

  factory MCVersionManifest.fromJson(Map<String, dynamic> data) {
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

  String type;

  String url;

  String time;

  String releaseTime;

  String sha1;

  int complianceLevel;

  DateTime get timeDateTime => DateTime.parse(time);

  DateTime get releaseDateTime => DateTime.parse(releaseTime);

  MCVersion(this.id, this.type, this.url, this.time, this.releaseTime,
      this.sha1, this.complianceLevel);

  factory MCVersion.fromJson(Map<String, dynamic> json) {
    return MCVersion(json['id'], json['type'], json['url'], json['time'],
        json['releaseTime'], json['sha1'], json['complianceLevel']);
  }
}

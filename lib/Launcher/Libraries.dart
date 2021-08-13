class Libraries {
  final List<_Library> libraries;

  const Libraries({
    required this.libraries,
  });

  factory Libraries.fromJson(Map json) =>
      Libraries(libraries: json['libraries']);
  Map<String, dynamic> toJson() => {
        'libraries': libraries,
      };
}

class _Library {
  final String name;
  final _downloads downloads;

  const _Library({
    required this.name,
    required this.downloads,
  });

  factory _Library.fromJson(Map json) => _Library(
      name: json['name'], downloads: _downloads.fromJson(json['downloads']));
  Map<String, dynamic> toJson() => {
        'name': name,
        'downloads': downloads.toJson(),
      };
}

class _downloads {
  final _artifact? artifact;
  final _classifiers? classifiers;
  const _downloads({
    required this.artifact,
    this.classifiers = null,
  });

  factory _downloads.fromJson(Map json) => _downloads(
      artifact: _artifact.fromJson(json['artifact']),
      classifiers: _classifiers.fromJson(json['classifiers']));

  Map<String, dynamic> toJson() => {
        'artifact': artifact?.toJson() ?? {},
        'classifiers': classifiers?.toJson() ?? {},
      };
}

class _artifact {
  final String path;
  final String url;
  final String sha1;
  final int size;

  const _artifact({
    required this.path,
    required this.url,
    required this.sha1,
    required this.size,
  });

  factory _artifact.fromJson(Map json) => _artifact(
      path: json['path'],
      url: json['url'],
      sha1: json['sha1'],
      size: json['size']);

  Map<String, dynamic> toJson() =>
      {'path': path, 'url': url, 'sha1': sha1, 'size': size};
}

class _classifiers {
  final String path;
  final String url;
  final String sha1;
  final int size;

  const _classifiers({
    required this.path,
    required this.url,
    required this.sha1,
    required this.size,
  });

  factory _classifiers.fromJson(Map json) => _classifiers(
      path: json['path'],
      url: json['url'],
      sha1: json['sha1'],
      size: json['size']);

  Map<String, dynamic> toJson() =>
      {'path': path, 'url': url, 'sha1': sha1, 'size': size};
}

import 'dart:io';

import 'package:path/path.dart';

enum TestData {
  versionManifestV2,
  version1193Meta,
  versionRd132211Meta;

  String getFileName() {
    switch (this) {
      case TestData.versionManifestV2:
        return 'version_manifest_v2.json';
      case TestData.version1193Meta:
        return '1.19.3_version_meta.json';
      case TestData.versionRd132211Meta:
        return 'rd-132211_version_meta.json';
    }
  }

  File getFile() =>
      File(join(Directory.current.path, 'test', 'data', getFileName()));
}

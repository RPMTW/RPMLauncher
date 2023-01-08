import 'dart:io';

import 'package:path/path.dart';

enum TestData {
  versionManifestV2;

  String getFileName() {
    switch (this) {
      case TestData.versionManifestV2:
        return 'version_manifest_v2.json';
    }
  }

  File getFile() =>
      File(join(Directory.current.path, 'test', 'data', getFileName()));
}

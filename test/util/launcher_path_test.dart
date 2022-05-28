// ignore_for_file: depend_on_referenced_packages

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rpmlauncher/util/launcher_path.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../script/test_helper.dart';

void main() {
  setUpAll(() => TestHelper.init());
  test('old data home (for windows and macOS)', () async {
    final Directory oldHome = Directory(join(
        (await getApplicationDocumentsDirectory()).path,
        'RPMLauncher',
        'test'));
    oldHome.createSync(recursive: true);

    await LauncherPath.init();
    final Directory path = LauncherPath.currentDataHome;
    expect(path.path, oldHome.path);

    oldHome.deleteSync(recursive: true);
  }, skip: Platform.isLinux);

  test('old data home (for linux)', () async {
    final Directory oldHome = Directory(
        join(absolute(Platform.environment['HOME']!), 'RPMLauncher', 'test'));
    oldHome.createSync(recursive: true);

    await LauncherPath.init();
    final Directory path = LauncherPath.currentDataHome;
    expect(path.path, oldHome.path);
  }, skip: !Platform.isLinux);
}

class FakePathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationSupportPath() async {
    return '${Directory.current.path}/Support';
  }

  @override
  Future<String?> getApplicationDocumentsPath() async {
    return '${Directory.current.path}/Documents';
  }
}

class AllNullFakePathProviderPlatform extends Fake
    implements PathProviderPlatform {
  @override
  Future<String?> getTemporaryPath() async {
    return null;
  }

  @override
  Future<String?> getApplicationSupportPath() async {
    return null;
  }

  @override
  Future<String?> getLibraryPath() async {
    return null;
  }

  @override
  Future<String?> getApplicationDocumentsPath() async {
    return null;
  }

  @override
  Future<String?> getExternalStoragePath() async {
    return null;
  }

  @override
  Future<List<String>?> getExternalCachePaths() async {
    return null;
  }

  @override
  Future<List<String>?> getExternalStoragePaths({
    StorageDirectory? type,
  }) async {
    return null;
  }

  @override
  Future<String?> getDownloadsPath() async {
    return null;
  }
}

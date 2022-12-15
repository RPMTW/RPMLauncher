import 'dart:io';
import 'package:http/http.dart';
import 'dart:convert';
import 'dart:core';
import 'package:args/args.dart';

void main(List<String> args) async {
  File updateJsonFile = File('update.json');
  updateJsonFile.createSync(recursive: true);

  Response response = await get(Uri.parse(
      'https://raw.githubusercontent.com/RPMTW/RPMTW-website-data/main/data/RPMLauncher/update.json'));

  Map updateJson = json.decode(response.body);

  var parser = ArgParser();

  parser.addFlag('version');
  parser.addFlag('build_id');
  parser.addFlag('type');
  parser.addFlag('changelog');

  var results = parser.parse(args);

  String version = results.rest[0];
  String buildID = results.rest[1];
  String type = results.rest[2];
  String changelog = results.rest[3];

  String baseUrl =
      'https://github.com/RPMTW/RPMLauncher/releases/download/$version+$buildID';

  updateJson['version_list']['$version+$buildID'] = {
    'download_url': {
      'windows': '$baseUrl/RPMLauncher-Windows-Installer.exe',
      'windows-zip': '$baseUrl/RPMLauncher-Windows.zip',
      'linux': '$baseUrl/RPMLauncher-Linux.zip',
      'linux-appimage': '$baseUrl/RPMLauncher-Linux.AppImage',
      'linux-deb': '$baseUrl/RPMLauncher-Linux.deb',
      'macos': '$baseUrl/RPMLauncher-macOS-Installer.dmg'
    },
    'changelog': changelog,
    'type': type
  };

  void updateStable() {
    updateJson['stable']['latest_version'] = version;
    updateJson['stable']['latest_build_id'] = buildID;
    updateJson['stable']['latest_version_full'] = '$version+$buildID';
  }

  void updateDev() {
    updateJson['dev']['latest_version'] = version;
    updateJson['dev']['latest_build_id'] = buildID;
    updateJson['dev']['latest_version_full'] = '$version+$buildID';
  }
  
  // 由於目前啟動器還不穩定，暫時兩個更新通道都一併更新
  // if (type == 'stable') {
    updateStable();
    updateDev();
  // } else if (type == 'dev') {
  //   updateDev();
  // }

  updateJsonFile.writeAsStringSync(json.encode(updateJson));
}

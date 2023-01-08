import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rpmlauncher/model/game/version/mc_version_manifest.dart';
import 'package:rpmlauncher/model/game/version/mc_version_type.dart';

import '../../../../helper/test_data.dart';

void main() {
  group('Serialization Minecraft version manifest', () {
    final jsonFile = TestData.versionManifestV2.getFile();
    final map = json.decode(jsonFile.readAsStringSync());

    test('Deserialize', () {
      final manifest = MCVersionManifest.fromJson(map);
      expect(manifest.latest.release, '1.19.3');
      expect(manifest.latest.snapshot, '1.19.3');

      expect(manifest.versions.length, 666);

      final firstVersion = manifest.versions.first;
      expect(firstVersion.id, '1.19.3');
      expect(firstVersion.type, MCVersionType.release);
      expect(firstVersion.url,
          'https://piston-meta.mojang.com/v1/packages/6607feafdb2f96baad9314f207277730421a8e76/1.19.3.json');
      expect(firstVersion.time, DateTime.parse('2022-12-07T08:58:43+00:00'));
      expect(firstVersion.releaseTime,
          DateTime.parse('2022-12-07T08:17:18+00:00'));
      expect(firstVersion.sha1, '6607feafdb2f96baad9314f207277730421a8e76');
      expect(firstVersion.complianceLevel, 1);

      final lastVersion = manifest.versions.last;
      expect(lastVersion.id, 'rd-132211');
      expect(lastVersion.type, MCVersionType.oldAlpha);
      expect(lastVersion.url,
          'https://launchermeta.mojang.com/v1/packages/d090f5d3766a28425316473d9ab6c37234d48b02/rd-132211.json');
      expect(lastVersion.time, DateTime.parse('2022-03-10T09:51:38+00:00'));
      expect(
          lastVersion.releaseTime, DateTime.parse('2009-05-13T20:11:00+00:00'));
      expect(lastVersion.sha1, 'd090f5d3766a28425316473d9ab6c37234d48b02');
      expect(lastVersion.complianceLevel, 0);
    });
  });
}

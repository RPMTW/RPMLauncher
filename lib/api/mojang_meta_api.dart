import 'package:rpmlauncher/model/game/version/mc_version_manifest.dart';
import 'package:rpmlauncher/util/rpml_http_client.dart';

class MojangMetaAPI {
  static const String _versionManifestUrl =
      'https://piston-meta.mojang.com/mc/game/version_manifest_v2.json';

  static Future<MCVersionManifest> getVersionManifest() async {
    final response = await httpClient.get(_versionManifestUrl);

    if (response.statusCode == 200) {
      return MCVersionManifest.fromJson(response.data);
    } else {
      throw Exception('Failed to load version manifest');
    }
  }
}

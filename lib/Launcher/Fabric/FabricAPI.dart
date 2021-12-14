import 'package:dio/dio.dart';
import 'package:rpmlauncher/Launcher/APIs.dart';
import 'package:rpmlauncher/Model/Game/FabricInstallerVersion.dart';
import 'package:rpmlauncher/Utility/RPMHttpClient.dart';

class FabricAPI {
  static Future<List> getLoaderVersions(versionID) async {
    Response response =
        await RPMHttpClient().get("$fabricApi/versions/loader/$versionID");
    return RPMHttpClient.json(response.data);
  }

  static Future<String> getProfileJson(versionID, loaderVersion) async {
    Response response = await RPMHttpClient().get(
        "$fabricApi/versions/loader/$versionID/$loaderVersion/profile/json");
    return RPMHttpClient.json(response.data);
  }

  static Future<FabricInstallerVersions> getInstallerVersion() async {
    Response response =
        await RPMHttpClient().get("$fabricApi/versions/installer");
    return FabricInstallerVersions.fromList(RPMHttpClient.json(response.data).cast<Map<String, dynamic>>());
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:rpmlauncher/MCLauncher/Fabric/FabricAPI.dart';

import '../MinecraftClient.dart';

class FabricClient implements MinecraftClient {
  Directory InstanceDir;

  String VersionMetaUrl;

  MinecraftClientHandler handler;

  var SetState;

  FabricClient._init({required this.InstanceDir,
    required this.VersionMetaUrl,
    required this.handler,
    required String VersionID,
    required SetState}) {}

  static Future<FabricClient> createClient({required Directory InstanceDir,
    required String VersionMetaUrl,
    required String VersionID,
    required setState}) async {

    Map<String, dynamic> body = json.decode(FabricAPI().GetProfileJson(VersionID).toString());
    print(body);

    return await new FabricClient._init(
        handler: await new MinecraftClientHandler(),
        SetState: setState,
        InstanceDir: InstanceDir,
        VersionMetaUrl: VersionMetaUrl,
        VersionID: VersionID)
        ._Ready(VersionMetaUrl, VersionID, setState);
  }

  Future<FabricClient> _Ready(VersionMetaUrl, VersionID, SetState) async {

    // await handler.Install(VersionMetaUrl, VersionID, SetState);
    return this;
  }

}
import 'dart:io';

import 'MinecraftClient.dart';

class VanillaClient implements MinecraftClient {
  Directory InstanceDir;

  String VersionMetaUrl;

  MinecraftClientHandler handler;

  var SetState;

  VanillaClient._init(
      {required this.InstanceDir,
      required this.VersionMetaUrl,
      required this.handler,
      required String VersionID,
      required SetState}) {}

  static Future<VanillaClient> createClient(
      {required Directory InstanceDir,
      required String VersionMetaUrl,
      required String VersionID,
      required setState}) async {
    return await new VanillaClient._init(
            handler: await new MinecraftClientHandler(),
            SetState: setState,
            InstanceDir: InstanceDir,
            VersionMetaUrl: VersionMetaUrl,
            VersionID: VersionID)
        ._Ready(VersionMetaUrl, VersionID, setState);
  }

  Future<VanillaClient> _Ready(VersionMetaUrl, VersionID, SetState) async {
    await handler.Install(VersionMetaUrl, VersionID, SetState);
    return this;
  }
}

import 'dart:io';

import 'MinecraftClient.dart';

class VanillaClient implements MinecraftClient {
  Directory InstanceDir;

  Map Meta;

  MinecraftClientHandler handler;

  var SetState;

  VanillaClient._init(
      {required this.InstanceDir,
      required this.Meta,
      required this.handler,
      required String VersionID,
      required SetState}) {}

  static Future<VanillaClient> createClient(
      {required Directory InstanceDir,
      required Map Meta,
      required String VersionID,
      required setState}) async {
    return await new VanillaClient._init(
            handler: await new MinecraftClientHandler(),
            SetState: setState,
            InstanceDir: InstanceDir,
            Meta: Meta,
            VersionID: VersionID)
        ._Ready(Meta, VersionID, InstanceDir, setState);
  }

  Future<VanillaClient> _Ready(
      VersionMetaUrl, VersionID, InstanceDir, SetState) async {
    await handler.Install(VersionMetaUrl, VersionID, InstanceDir, SetState);
    return this;
  }
}

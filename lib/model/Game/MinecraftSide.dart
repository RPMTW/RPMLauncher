import 'package:rpmlauncher/util/i18n.dart';

enum MinecraftSide { client, server }

extension MinecraftSideExtension on MinecraftSide {
  String get i18nName {
    switch (this) {
      case MinecraftSide.client:
        return I18n.format('version.side.client');
      case MinecraftSide.server:
        return I18n.format('version.side.server');
    }
  }

  bool get isClient => this == MinecraftSide.client;

  bool get isServer => this == MinecraftSide.server;
}

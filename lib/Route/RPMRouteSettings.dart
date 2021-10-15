import 'package:flutter/widgets.dart';

class RPMRouteSettings extends RouteSettings {
  String? routeName;
  final String? name;
  final Object? arguments;

  RPMRouteSettings({
    this.routeName,
    this.name,
    this.arguments,
  });

  factory RPMRouteSettings.fromRouteSettings(RouteSettings settings) {
    try {
      return settings as RPMRouteSettings;
    } catch (e) {
      return RPMRouteSettings(
          name: settings.name, arguments: settings.arguments);
    }
  }
}

import 'package:flutter/widgets.dart';

class RPMRouteSettings extends RouteSettings {
  String? routeName;

  RPMRouteSettings({
    this.routeName,
    String? name,
    Object? arguments,
  }) : super(name: name, arguments: arguments);

  factory RPMRouteSettings.fromRouteSettings(RouteSettings settings) {
    try {
      return settings as RPMRouteSettings;
    } catch (e) {
      return RPMRouteSettings(
          name: settings.name, arguments: settings.arguments);
    }
  }
}

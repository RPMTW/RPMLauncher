import 'package:flutter/widgets.dart';

class RPMRouteSettings extends RouteSettings {
  String? routeName;
  final bool newWindow;

  RPMRouteSettings({
    this.routeName,
    this.newWindow = false,
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

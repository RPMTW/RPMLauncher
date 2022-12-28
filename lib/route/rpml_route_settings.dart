import 'package:flutter/widgets.dart';

class RPMLRouteSettings extends RouteSettings {
  String? routeName;

  RPMLRouteSettings({
    this.routeName,
    String? name,
    Object? arguments,
  }) : super(name: name, arguments: arguments);

  factory RPMLRouteSettings.fromRouteSettings(RouteSettings settings) {
    try {
      return settings as RPMLRouteSettings;
    } catch (e) {
      return RPMLRouteSettings(
          name: settings.name, arguments: settings.arguments);
    }
  }
}

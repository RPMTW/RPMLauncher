import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:rpmlauncher/ui/theme/launcher_theme.dart';
import 'package:rpmlauncher/ui/theme/rpml_theme_data.dart';
import 'package:rpmlauncher/ui/theme/rpml_theme_type.dart';

class ThemeProvider extends StatefulWidget {
  final Widget Function(BuildContext context, RPMLThemeData themeData) builder;

  const ThemeProvider({Key? key, required this.builder}) : super(key: key);

  @override
  State<ThemeProvider> createState() => _ThemeProviderState();
}

class _ThemeProviderState extends State<ThemeProvider> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ThemeChangeNotifier>(
        create: (_) => ThemeChangeNotifier(
            RPMLThemeData.byType(LauncherTheme.getTypeByConfig())),
        child:
            Consumer<ThemeChangeNotifier>(builder: (context, notifier, child) {
          return widget.builder(context, notifier._themeData);
        }));
  }
}

class ThemeChangeNotifier extends ChangeNotifier implements ReassembleHandler {
  RPMLThemeData _themeData;

  RPMLThemeData get themeData => _themeData;

  ThemeChangeNotifier(this._themeData);

  void setTheme(RPMLThemeType type) {
    _themeData = RPMLThemeData.byType(type);
    notifyListeners();
  }

  /// Handle hot reload
  @override
  void reassemble() {
    setTheme(LauncherTheme.getTypeByConfig());
  }
}

//
//  Generated file. Do not edit.
//

import FlutterMacOS
import Foundation

import flutter_window_close
import package_info_plus_macos
import path_provider_macos
import rpmlauncher_plugin
import screen_retriever
import sentry_flutter
import shared_preferences_foundation
import url_launcher_macos
import window_manager
import window_size

func RegisterGeneratedPlugins(registry: FlutterPluginRegistry) {
  FlutterWindowClosePlugin.register(with: registry.registrar(forPlugin: "FlutterWindowClosePlugin"))
  FLTPackageInfoPlusPlugin.register(with: registry.registrar(forPlugin: "FLTPackageInfoPlusPlugin"))
  PathProviderPlugin.register(with: registry.registrar(forPlugin: "PathProviderPlugin"))
  RpmlauncherPlugin.register(with: registry.registrar(forPlugin: "RpmlauncherPlugin"))
  ScreenRetrieverPlugin.register(with: registry.registrar(forPlugin: "ScreenRetrieverPlugin"))
  SentryFlutterPlugin.register(with: registry.registrar(forPlugin: "SentryFlutterPlugin"))
  SharedPreferencesPlugin.register(with: registry.registrar(forPlugin: "SharedPreferencesPlugin"))
  UrlLauncherPlugin.register(with: registry.registrar(forPlugin: "UrlLauncherPlugin"))
  WindowManagerPlugin.register(with: registry.registrar(forPlugin: "WindowManagerPlugin"))
  WindowSizePlugin.register(with: registry.registrar(forPlugin: "WindowSizePlugin"))
}

import Cocoa
import FlutterMacOS
import desktop_multi_window
import package_info_plus_macos
import path_provider_macos
import rpmlauncher_plugin
import sentry_flutter
import shared_preferences_macos
import url_launcher_macos
import window_manager
import window_size

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController.init()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
       
    FlutterMultiWindowPlugin.setOnWindowCreatedCallback { controller in
    FLTPackageInfoPlusPlugin.register(with: controller.registrar(forPlugin: "FLTPackageInfoPlusPlugin"))
    PathProviderPlugin.register(with: controller.registrar(forPlugin: "PathProviderPlugin"))
    RpmlauncherPlugin.register(with: controller.registrar(forPlugin: "RpmlauncherPlugin"))
    SentryFlutterPlugin.register(with: controller.registrar(forPlugin: "SentryFlutterPlugin"))
    SharedPreferencesPlugin.register(with: controller.registrar(forPlugin: "SharedPreferencesPlugin"))
    UrlLauncherPlugin.register(with: controller.registrar(forPlugin: "UrlLauncherPlugin"))
    WindowManagerPlugin.register(with: controller.registrar(forPlugin: "WindowManagerPlugin"))
    WindowSizePlugin.register(with: controller.registrar(forPlugin: "WindowSizePlugin"))
    }

    super.awakeFromNib()
  }
}

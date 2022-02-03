import Cocoa
import FlutterMacOS
import Foundation

public class RpmlauncherPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "rpmlauncher_plugin", binaryMessenger: registrar.messenger)
    let instance = RpmlauncherPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("macOS " + ProcessInfo.processInfo.operatingSystemVersionString)
    case "getTotalPhysicalMemory":
      result(ProcessInfo.processInfo.physicalMemory)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

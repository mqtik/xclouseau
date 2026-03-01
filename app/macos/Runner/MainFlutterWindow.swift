import Cocoa
import FlutterMacOS
import window_manager
import bitsdojo_window_macos  // used to make custom window bars on macOS (or any desktop operating system for that matter)

class MainFlutterWindow: BitsdojoWindow {
  override func bitsdojo_window_configure() -> UInt {
    return BDW_CUSTOM_FRAME | BDW_HIDE_ON_STARTUP
  }
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController.init()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    hiddenWindowAtLaunch()

    super.awakeFromNib()
  }

  override func performClose(_ sender: Any?) {
    if let controller = contentViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(name: "main-delegate-channel", binaryMessenger: controller.engine.binaryMessenger)
      channel.invokeMethod("closeTab", arguments: nil)
    }
  }
}

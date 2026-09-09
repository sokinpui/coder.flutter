import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    let channel = FlutterMethodChannel(
      name: "coder_flutter/clipboard",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    channel.setMethodCallHandler { (call, result) in
      switch call.method {
      case "getClipboardImage":
        let pb = NSPasteboard.general
        if let pngData = pb.data(forType: .png) ?? pb.data(forType: NSPasteboard.PasteboardType("public.png")) {
          result(FlutterStandardTypedData(bytes: pngData))
          return
        }
        if let tiffData = pb.data(forType: .tiff) ?? pb.data(forType: NSPasteboard.PasteboardType("public.tiff")),
           let bitmap = NSBitmapImageRep(data: tiffData),
           let pngData = bitmap.representation(using: .png, properties: [:]) {
          result(FlutterStandardTypedData(bytes: pngData))
          return
        }
        if let image = NSImage(pasteboard: pb),
           let tiff = image.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiff),
           let pngData = bitmap.representation(using: .png, properties: [:]) {
          result(FlutterStandardTypedData(bytes: pngData))
          return
        }
        if let urls = pb.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] {
          for url in urls {
            let ext = url.pathExtension.lowercased()
            if ["png", "jpg", "jpeg", "gif", "webp", "bmp", "tiff"].contains(ext),
               let fileData = try? Data(contentsOf: url) {
              result(FlutterStandardTypedData(bytes: fileData))
              return
            }
          }
        }
        result(nil)

      case "pickImage":
        NSApp.activate(ignoringOtherApps: true)
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedFileTypes = ["png", "jpg", "jpeg", "gif", "webp", "bmp"]
        if panel.runModal() == .OK, let url = panel.url, let data = try? Data(contentsOf: url) {
          result(FlutterStandardTypedData(bytes: data))
          return
        }
        result(nil)

      case "pickFile":
        NSApp.activate(ignoringOtherApps: true)
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
          result(url.path)
          return
        }
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    super.awakeFromNib()
  }
}

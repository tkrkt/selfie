import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSUserNotificationCenterDelegate, CameraViewDelegate {    
    @IBOutlet weak var window: NSWindow!

    let menu = NSMenu()
    let preference = Preference()

    var settingController: SettingWindowController?
    var cameraController: CameraViewController?

    let statusItem = NSStatusBar.system().statusItem(withLength: NSVariableStatusItemLength)
    let popover = NSPopover()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // menu
        if let button = statusItem.button {
            button.image = NSImage(imageLiteralResourceName: "StatusBarIconTemplate")
            button.action = #selector(self.statusItemClicked)
            button.sendAction(on: NSEventMask.leftMouseUp.union(NSEventMask.rightMouseUp))
        }
        self.menu.addItem(withTitle: "Preferences...",
                          action: #selector(self.showPreferenceWindow),
                          keyEquivalent: "")
        self.menu.addItem(NSMenuItem.separator())
        self.menu.addItem(withTitle: "Quit",
                          action: #selector(self.quit),
                          keyEquivalent: "")

        // camera view
        self.cameraController = CameraViewController(nibName: "CameraViewController",
                                                     bundle: nil)
        self.cameraController!.preference = self.preference
        self.popover.contentViewController = self.cameraController

        // setting view
        self.settingController = SettingWindowController(windowNibName: "SettingWindowController")
        self.settingController!.preference = self.preference

        // delegate / nortification
        NSUserNotificationCenter.default.delegate = self
        self.cameraController!.cameraEventDelegate = self
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self,
                                       selector: #selector(appMovedToBackground),
                                       name: .NSApplicationWillResignActive,
                                       object: nil)
    }
    
    func appMovedToBackground() {
        if self.popover.isShown {
            self.popover.performClose(nil)
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
    }
    
    func statusItemClicked(sender: NSButton) {
        if (NSApp.currentEvent!.type == NSEventType.rightMouseUp) {
            self.statusItem.popUpMenu(self.menu)
        } else {
            if self.popover.isShown {
                self.popover.performClose(nil)
            } else if let w = self.settingController?.window, w.isVisible {
                NSApp.activate(ignoringOtherApps: true)
            } else {
                self.popover.show(relativeTo: sender.bounds,
                                  of: sender,
                                  preferredEdge: NSRectEdge.minY)
            }
        }
    }
    
    func showPreferenceWindow() {
        if self.popover.isShown {
            self.popover.performClose(nil)
        }
        if (!(self.settingController?.window?.isVisible)!) {
            self.settingController!.window?.center()
            self.settingController!.showWindow(nil)
        }
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func onFailedToConnectCamera() {
        if self.popover.isShown {
            self.popover.performClose(nil)
        }
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Failed to connect to camera service."
            alert.alertStyle = NSAlertStyle.critical
            alert.runModal()
        }
    }
    
    func onCaptureSizeDetected(size: NSSize) {
        self.popover.contentSize = size

        self.preference.width = self.preference.width.clamp(min: Preference.minWidth,
                                                            max: Int(size.width))
        self.preference.height = self.preference.height.clamp(min: Preference.minHeight,
                                                              max: Int(size.height))
        self.preference.synchronize()
        
        let scale = Double(self.preference.width) / Double(self.preference.height)
        self.popover.contentSize.width = CGFloat(Double(Preference.viewHeight) * scale)
        self.popover.contentSize.height = CGFloat(Preference.viewHeight)
    }

    func onCaptured(image: Data, type: FileType) {
        if self.popover.isShown {
            self.popover.performClose(nil)
        }
        if (self.preference.askForSavePath) {
            DispatchQueue.main.async {
                let dialog = NSSavePanel()
                dialog.directoryURL = self.preference.getSaveFolderURL()
                dialog.allowedFileTypes = [self.preference.fileType.toString()]
                dialog.title = "selfie: Save Image"
                dialog.nameFieldStringValue = self.preference.getFileName()
                dialog.runModal()
                if let url = dialog.url {
                    assert(type == self.preference.fileType)
                    self.saveImage(image: image, type: type, url: url)
                }
            }
        } else {
            assert(type == self.preference.fileType)
            self.saveImage(image: image, type: type, url: self.preference.getSaveFileURL())
        }
    }
    
    func saveImage(image: Data, type: FileType, url: URL) {
        try! image.write(to: url)

        switch self.preference.copyStyle {
        case .nop:
            break
        case .img:
            let board = NSPasteboard.general()
            board.clearContents()
            board.setData(image, forType: type.typeString)
        case .file:
            let board = NSPasteboard.general()
            board.clearContents()
            board.setString(url.absoluteString, forType: "public.file-url")
        case .path:
            let board = NSPasteboard.general()
            board.clearContents()

            var copyText: String
            switch self.preference.copyPathStyle {
            case .plain:
                copyText = url.path
            case .img:
                copyText = String(format: "<img alt=\"%@\" src=\"%@\">",
                                  arguments: [
                                    url.path.deletingPathExtension,
                                    self.preference.getRelativeFilePath(fileUrl: url)])
            case .markdown:
                copyText = String(format: "![%@](%@)",
                                  arguments: [
                                    url.path.deletingPathExtension,
                                    self.preference.getRelativeFilePath(fileUrl: url)])
            }
            board.setString(copyText, forType: NSPasteboardTypeString)
        }
    }
    
    func quit() {
        exit(0)
    }
}

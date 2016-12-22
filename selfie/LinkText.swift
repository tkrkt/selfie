import Cocoa

class LinkText: NSTextField {
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        NSWorkspace.shared().open(URL(string: self.stringValue)!)
    }
}

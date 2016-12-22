import Cocoa

extension String {
    private var ns: NSString {
        return self as NSString
    }
    
    public var expandingTildeInPath: String {
        return self.ns.expandingTildeInPath
    }
    
    public var lastPathComponent: String {
        return self.ns.lastPathComponent
    }

    public var deletingPathExtension: String {
        return self.ns.deletingPathExtension.lastPathComponent
    }
}

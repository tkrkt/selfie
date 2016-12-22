import Cocoa

extension Bool {
    public func toNSState() -> Int {
        return self ? NSOnState : NSOffState
    }
}

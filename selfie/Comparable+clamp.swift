import Cocoa

extension Comparable {
    func clamp(min: Self, max: Self) -> Self {
        if (self < min) {
            return min
        } else if (max < self) {
            return max
        } else {
            return self
        }
    }
}

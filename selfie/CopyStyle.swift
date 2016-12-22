enum CopyStyle: Int {
    case nop = 0
    case img = 1
    case file = 2
    case path = 3
    
    static func fromRaw(value: Int) -> CopyStyle {
        if let copyStyle = CopyStyle(rawValue: value) {
            return copyStyle
        } else {
            return .nop
        }
    }
}

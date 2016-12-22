enum CopyPathStyle: Int {
    case plain = 0
    case img = 1
    case markdown = 2
    
    static func fromRaw(value: Int) -> CopyPathStyle {
        if let copyStyle = CopyPathStyle(rawValue: value) {
            return copyStyle
        } else {
            return .plain
        }
    }
}

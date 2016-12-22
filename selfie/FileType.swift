import AppKit

enum FileType: Int {
    case jpg = 0
    case png = 1
    case gif = 2
    
    static func fromRaw(value: Int) -> FileType {
        if let fileType = FileType(rawValue: value) {
            return fileType
        } else {
            return FileType.jpg
        }
    }
    
    func toString() -> String {
        switch self {
        case .jpg:
            return "jpg"
        case .png:
            return "png"
        case .gif:
            return "gif"
        }
    }

    var representation: NSBitmapImageFileType {
        switch self {
        case .jpg:
            return NSJPEGFileType
        case .png:
            return NSPNGFileType
        case .gif:
            return NSGIFFileType
        }
    }
    
    var typeString: String {
        switch self {
        case .jpg:
            return kUTTypeJPEG as String
        case .png:
            return kUTTypePNG as String
        case .gif:
            return kUTTypeGIF as String
        }
    }
}

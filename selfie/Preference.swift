import Foundation

class Preference {
    static let viewHeight: Int = 250
    static let minWidth: Int = 100
    static let minHeight: Int = 100

    enum PreferenceKey: String {
        case width
        case height
        case flipX
        case fileName
        case fileType
        case saveFolder
        case askForSavePath
        case copyStyle
        case copyPathStyle
        case pathRoot
    }
    
    var width: Int {
        get {
            return load(forKey: .width, or: 250)
        }
        set(value) {
            save(forKey: .width, value: max(value, Preference.minWidth))
        }
    }
    
    var height: Int {
        get {
            return load(forKey: .height, or: 250)
        }
        set(value) {
            save(forKey: .height, value: max(value, Preference.minHeight))
        }
    }
    
    var fileName: String {
        get {
            return load(forKey: .fileName, or: "yyyyMMdd-HHmmss")
        }
        set(value) {
            save(forKey: .fileName, value: value.trim())
        }
    }
    
    var fileType: FileType {
        get {
            return FileType.fromRaw(value: load(forKey: .fileType,
                                                or: FileType.jpg.rawValue))
        }
        set(value) {
            save(forKey: .fileType, value: value.rawValue)
        }
    }
    
    var saveFolder: String {
        get {
            return load(forKey: .saveFolder, or: "~/Downloads")
        }
        set(value) {
            save(forKey: .saveFolder, value: value.trim())
        }
    }

    var askForSavePath: Bool {
        get {
            return load(forKey: .askForSavePath, or: true)
        }
        set(value) {
            save(forKey: .askForSavePath, value: value)
        }
    }
    
    var copyStyle: CopyStyle {
        get {
            return CopyStyle.fromRaw(value: load(forKey: .copyStyle,
                                                 or: CopyStyle.file.rawValue))
        }
        set(value) {
            save(forKey: .copyStyle, value: value.rawValue)
        }
    }
    
    var copyPathStyle: CopyPathStyle {
        get {
            return CopyPathStyle.fromRaw(value: load(forKey: .copyPathStyle,
                                                     or: CopyPathStyle.plain.rawValue))
        }
        set(value) {
            save(forKey: .copyPathStyle, value: value.rawValue)
        }
    }
    
    var pathRoot: String {
        get {
            return load(forKey: .pathRoot, or: "~/Downloads")
        }
        set(value) {
            save(forKey: .pathRoot, value: value.trim())
        }
    }
    
    var flipX: Bool {
        get {
            return load(forKey: .flipX, or: false)
        }
        set(value) {
            save(forKey: .flipX, value: value)
        }
    }
    
    private func load<T>(forKey: PreferenceKey, or: T) -> T {
        if let value = UserDefaults.standard.object(forKey: forKey.rawValue) as? T {
            return value
        } else {
            return or
        }
    }
    
    private func save(forKey: PreferenceKey, value: Any) {
        UserDefaults.standard.set(value, forKey: forKey.rawValue)
    }
    
    func synchronize() {
        UserDefaults.standard.synchronize()
    }
    
    func getFileName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = self.fileName
        let file = formatter.string(from: Date())
        return file + "." + self.fileType.toString()
    }
    
    func getSaveFolderURL() -> URL {
        return URL(fileURLWithPath: self.saveFolder.expandingTildeInPath,
                   isDirectory: true)
    }

    func getSaveFileURL() -> URL {
        return getSaveFolderURL()
            .appendingPathComponent(self.getFileName())
    }
    
    func getRelativeFilePath(fileUrl: URL) -> String {
        if (self.pathRoot == "") {
            return fileUrl.path
        } else {
            let root = URL(fileURLWithPath: self.pathRoot.expandingTildeInPath,
                           isDirectory: true).pathComponents
            let saveFolder = fileUrl.pathComponents
            
            var path: [String] = []
            
            for i in (0 ..< max(root.count, saveFolder.count)) {
                if (i >= root.count) {
                    path.append(saveFolder[i])
                } else if (i >= saveFolder.count) {
                    path.insert("..", at: 0)
                } else if (root[i] != saveFolder[i]) {
                    path.insert("..", at: 0)
                    path.append(saveFolder[i])
                }
            }
            return path.joined(separator: "/")
        }
    }
}

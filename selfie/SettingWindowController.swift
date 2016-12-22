import Cocoa

class SettingWindowController: NSWindowController, NSWindowDelegate {
    @IBOutlet var widthField: NSTextField!
    @IBOutlet var heightField: NSTextField!
    @IBOutlet var flipXCheckBox: NSButton!
    
    @IBOutlet var fileNameField: NSTextField!
    @IBOutlet var fileTypePopup: NSPopUpButton!
    
    @IBOutlet var saveFolderField: NSTextField!
    @IBOutlet var askForSavePathCheckbox: NSButton!
    
    @IBOutlet var copyStyleMatrix: NSMatrix!
    @IBOutlet var copyPathStylePopup: NSPopUpButton!
    
    @IBOutlet var pathRootLabel: NSTextField!
    @IBOutlet var pathRootField: NSTextField!
    @IBOutlet var pathRootButton: NSButton!

    var preference: Preference!

    override func windowDidLoad() {
        super.windowDidLoad()
        self.window?.delegate = self
    }
    
    
    func windowDidChangeOcclusionState(_ notification: Notification) {
        if (self.window!.occlusionState.contains(.visible)) {
            // View did appear
            self.widthField.stringValue = String(self.preference.width)
            self.heightField.stringValue = String(self.preference.height)
            self.flipXCheckBox.state = self.preference.flipX.toNSState()
            
            self.fileNameField.stringValue = self.preference.fileName
            self.fileTypePopup.selectItem(at: self.preference.fileType.rawValue)
            
            self.saveFolderField.stringValue = self.preference.saveFolder
            self.askForSavePathCheckbox.state = self.preference.askForSavePath.toNSState()
            
            self.copyStyleMatrix.selectCell(atRow: self.preference.copyStyle.rawValue, column: 0)
            self.copyPathStylePopup.selectItem(at: self.preference.copyPathStyle.rawValue)
            self.pathRootField.stringValue = self.preference.pathRoot

            refreshEnables()
        }
    }
    
    func windowWillClose(_ notification: Notification) {
        if let width = Int(self.widthField.stringValue.trim()) {
            self.preference.width = width
        }
        if let height = Int(self.heightField.stringValue.trim()) {
            self.preference.height = height
        }
        self.preference.flipX = self.flipXCheckBox.state.isOnState()

        self.preference.fileName = self.fileNameField.stringValue
        self.preference.fileType = FileType(rawValue: self.fileTypePopup.indexOfSelectedItem)!

        self.preference.saveFolder = self.saveFolderField.stringValue
        self.preference.askForSavePath = self.askForSavePathCheckbox.state.isOnState()

        self.preference.copyStyle = CopyStyle.fromRaw(value: self.copyStyleMatrix.selectedRow)
        self.preference.copyPathStyle = CopyPathStyle.fromRaw(value: self.copyPathStylePopup.indexOfSelectedItem)
        self.preference.pathRoot = self.pathRootField.stringValue

        self.preference.synchronize()
    }
    
    func refreshEnables() {
        let copyPathSelected: Bool = self.copyStyleMatrix.selectedRow == CopyStyle.path.rawValue

        self.window?.makeFirstResponder(nil)
        
        self.copyPathStylePopup.isEnabled = copyPathSelected
        self.pathRootField.isEnabled = copyPathSelected
        self.pathRootButton.isEnabled = copyPathSelected
        if (copyPathSelected) {
            self.pathRootLabel.textColor = NSColor.controlTextColor
        } else {
            self.pathRootLabel.textColor = NSColor.disabledControlTextColor
        }
    }
    
    @IBAction func copyStyleMatrixClicked(sender: NSMatrix) {
        refreshEnables()
    }
    
    @IBAction func saveFolderButtonClicked(sender: NSButton) {
        if let path = showFolderChooser() {
            self.saveFolderField.stringValue = path
        }
    }
    
    @IBAction func rendererPathButtonClicked(sender: NSButton) {
        if let path = showFolderChooser() {
            self.pathRootField.stringValue = path
        }
    }
    
    func showFolderChooser() -> String? {
        let dialog = NSOpenPanel()
        dialog.canChooseFiles = false
        dialog.canChooseDirectories = true
        dialog.resolvesAliases = true
        dialog.allowsMultipleSelection = false
        dialog.runModal()
        
        return dialog.url?.path
    }
}

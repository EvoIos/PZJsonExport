//
//  ViewController.swift
//  PZJsonExport
//
//  Created by z on 2018/4/12.
//  Copyright © 2018年 z. All rights reserved.
//

import Cocoa
import SwiftyJSON
import AddressBook

class ViewController: NSViewController, NSTextViewDelegate, NSUserNotificationCenterDelegate {

    @IBOutlet weak var inputScrollView: NSScrollView!
    @IBOutlet var inputTextView: NSTextView!
    @IBOutlet weak var headerScrollView: NSScrollView!
    @IBOutlet var headerTextView: NSTextView!
    @IBOutlet weak var messagesScrollView: NSScrollView!
    @IBOutlet var messagesTextView: NSTextView!
    @IBOutlet weak var validJsonTipsTF: NSTextField!
    @IBOutlet weak var tipsTextField: NSTextField!
    
    @IBAction func saveFiles(_ sender: NSButton) {
        self.saveFiles()
    }
    
    @IBAction func rootClassChanged(_ sender: NSTextField) {
        PZJsonInfo.shared.rootClassName = sender.stringValue.count > 0 ? sender.stringValue : "RootClass"
        parse()
    }
    
    @IBAction func classPrefixChanged(_ sender: NSTextField) {
        PZJsonInfo.shared.classPrefix = sender.stringValue
        parse()
    }
    
    let parser = PZParse()
    var statementString: String = ""
    var classes = [String]()
    var classInfo: [String: String] = [:]
    var mapTable: [String: String] = [:]
    
    var validJson: Bool? {
        didSet {
            if  validJson == true {
                self.tipsTextField.textColor = NSColor.green
                self.tipsTextField.stringValue = "Valid Json Data"
            } else {
                self.tipsTextField.textColor = NSColor.red
                self.tipsTextField.stringValue = "Invalid Json Data"
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        [inputScrollView,headerScrollView,messagesScrollView].forEach { (scrollView) in
            let lineNumberView = NoodleLineNumberView(scrollView: scrollView)
            scrollView?.hasHorizontalRuler = false
            scrollView?.hasVerticalRuler = true
            scrollView?.verticalRulerView = lineNumberView
            scrollView?.rulersVisible = true
        }
        
        [headerTextView,messagesTextView].forEach { (textView) in
            textView?.font = NSFont.systemFont(ofSize: 14)
            textView?.isAutomaticQuoteSubstitutionEnabled = false
        }

        inputTextView.isAutomaticQuoteSubstitutionEnabled = false
        inputTextView.delegate = self
        inputTextView.becomeFirstResponder()
        
        var tmp = ["abc","efg","hid"]
        var tmpArray = tmp.map { $0 + "," }.reduce("", +)
        print(tmpArray)
        
    }
    
    func textDidChange(_ notification: Notification) {
        parse()
    }
    
    func parse() {
        guard inputTextView.string.count > 0 else { return }
        parser.parse(inputTextView.string) { (result, error) in
            if let dictionary = result {
                self.validJson = true
                self.headerTextView.string = dictionary[self.parser.headerKey]!
                self.messagesTextView.string = dictionary[self.parser.messagesKey]!
            } else {
                self.validJson = false
            }
        }
    }
}

// MARK: - From JSONExport: https://github.com/Ahmed-Ali/JSONExport
extension ViewController {
    
    func saveFiles() {
        
        guard self.headerTextView.string.count > 0 && self.messagesTextView.string.count > 0 else {
            return
        }
        
        let openPanel = NSOpenPanel()
        openPanel.allowsOtherFileTypes = false
        openPanel.treatsFilePackagesAsDirectories = false
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = true
        openPanel.prompt = "Choose"
        openPanel.beginSheetModal(for: self.view.window!) { (response) -> Void in
            if  response.rawValue == NSFileHandlingPanelOKButton {
                self.saveToPath(openPanel.url!.path)
                self.showDoneSuccessfully()
            }
        }
    }
    
    /**
     Saves all the generated files in the specified path
     
     - parameter path: in which to save the files
     */
    func saveToPath(_ path : String) {
        
        var error : NSError?
        
        for (idx,content) in [self.headerTextView.string,self.messagesTextView.string].enumerated() {
            let fileContent = content
            
            let fileExtension = [PZJsonInfo.shared.fileName(header: true),PZJsonInfo.shared.fileName(header: false)][idx]
            
            let filePath = "\(path)/\(fileExtension)"
            
            do {
                try fileContent.write(toFile: filePath, atomically: false, encoding: String.Encoding.utf8)
            } catch let error1 as NSError {
                error = error1
            }
            if error != nil{
                showError(error!)
                break
            }
        }
    }
    
    //MARK: - Messages
    /**
     Shows the top right notification. Call it after saving the files successfully
     */
    func showDoneSuccessfully()
    {
        let notification = NSUserNotification()
        notification.title = "Success!"
        notification.informativeText = "Your model files have been generated successfully."
        notification.deliveryDate = Date()
        
        let center = NSUserNotificationCenter.default
        center.delegate = self
        center.deliver(notification)
    }
    
    //MARK: - NSUserNotificationCenterDelegate
    func userNotificationCenter(_ center: NSUserNotificationCenter,
                                shouldPresent notification: NSUserNotification) -> Bool {
        return true
    }
    
    /**
     Shows an NSAlert for the passed error
     */
    func showError(_ error: NSError!)
    {
        if error == nil{
            return;
        }
        let alert = NSAlert(error: error)
        alert.runModal()
    }
}



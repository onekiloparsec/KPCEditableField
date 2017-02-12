//
//  KPCEditableField.swift
//  KPCEditableField
//
//  Created by Cédric Foellmi on 10/02/2017.
//  Copyright © 2017 onekiloparsec. All rights reserved.
//

import AppKit

public extension NSPoint {
    public func offsetBy(dx: CGFloat, dy: CGFloat) -> NSPoint {
        return NSPoint(x: self.x + dx, y: self.y + dy)
    }
}

public extension NSSize {
    public func extendedBy(dw: CGFloat, dh: CGFloat) -> NSSize {
        return NSSize(width: self.width + dw, height: self.height + dh)
    }
}

public typealias EditableTextSource = () -> String
public typealias EditableOptionsSource = () -> (selectedIndex: Int, options: [String])

public enum EditableSource {
    case text(EditableTextSource)
    case options(EditableOptionsSource)
    
    public var stringValue: String {
        get {
            switch self {
            case .text(let source):
                return source()
            case .options(let source):
                let (selectedIndex, titles) = source()
                if selectedIndex >= 0 && selectedIndex < titles.count {
                    return titles[selectedIndex]
                }
                return ""
            }
        }
    }
}

enum EditableButtonType {
    case pencil
    case check
    case cancel
    
    var image: NSImage { get {
        let bundle = Bundle(for: EditableField.self)
        switch self {
            case .pencil:
                return NSImage(contentsOfFile: bundle.pathForImageResource("pencil")!)!.imageWithTint(NSColor.darkGray)
            case .check:
                return NSImage(contentsOfFile: bundle.pathForImageResource("check")!)!.imageWithTint(NSColor.darkGray)
            case .cancel:
                return NSImage(contentsOfFile: bundle.pathForImageResource("cancel")!)!.imageWithTint(NSColor.darkGray)
        }
    }}
}

extension NSButton {
    static func editableButton(type: EditableButtonType, target: Any?, action: Selector?) -> NSButton {
        let button = NSButton(image: type.image, target: target, action: action)
        button.frame = CGRect(x: 0.0, y: 0.0, width: 20.0, height: 20.0)
        button.isBordered = true
        button.bezelStyle = .smallSquare
        button.setButtonType(.momentaryPushIn)
//        button.showsBorderOnlyWhileMouseInside = true
        button.image = type.image
        button.focusRingType = .none
        button.isHidden = true
        let buttonCell = button.cell as! NSButtonCell
        buttonCell.backgroundColor = NSColor.clear
        buttonCell.imageScaling = .scaleProportionallyDown
        return button
    }
}


open class EditableField: NSTextField, NSTextDelegate {
    private weak var auxiliaryView: NSView?

    private var okButton: NSButton?
    private var cancelButton: NSButton?
    private var editButton: NSButton?
    private var editableTrackingArea: NSTrackingArea?
    
    private var originalFrame: NSRect?

    public var showValidationButtons: Bool = true
    public var editable_source: EditableSource? {
        didSet { self.stringValue = self.editable_source?.stringValue ?? "" }
    }
    public private(set) var isEditing: Bool = false

    var reallyAcceptsFirstResponder: Bool = false
    override open var acceptsFirstResponder: Bool {
        get { return self.reallyAcceptsFirstResponder }
    }

//    override open var isEditable: Bool {
//        get { return self.editable_source != nil }
//        set {}
//    }

    open var bezeledFrame: NSRect {
        get { return self.originalFrame!.offsetBy(dx: -2.0, dy: -1.0).insetBy(dx: 0.0, dy: -4.0) }
    }

//    open var bezeledOrigin: NSPoint {
//        get { return self.originalFrame!.origin.offsetBy(dx: -2.0, dy: -2.0) }
//    }
//
//    open var bezeledSize: NSSize {
//        get { return self.originalFrame!.size.extendedBy(dw: 0.0, dh: 5.0) }
//    }
    
    override open func viewDidMoveToWindow() {
        self.originalFrame = self.frame
        self.setupAsLabel()
        
//        self.okButton = NSButton.editableButton(type: .check, target: self, action: nil)
//        self.okButton?.frame.origin = CGPoint(x: NSMaxX(self.titleFrame)+2.0, y: NSMinY(self.titleFrame)-2.0)
//        
//        self.cancelButton = NSButton.editableButton(type: .cancel, target: self, action: #selector(EditableField.cancelEditingField))
//        self.cancelButton?.frame.origin = CGPoint(x: NSMaxX(self.okButton!.frame)+2.0, y: NSMinY(self.okButton!.frame))
//        
//        self.editButton = NSButton.editableButton(type: .pencil, target: self, action: #selector(EditableField.editField))
//        self.editButton?.frame = self.okButton!.frame
//        
//        self.superview?.addSubview(self.okButton!)
//        self.superview?.addSubview(self.cancelButton!)
//        self.superview?.addSubview(self.editButton!)
    }
    
    override open func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        if self.editableTrackingArea != nil {
            self.removeTrackingArea(self.editableTrackingArea!)
        }
                
        self.editableTrackingArea = NSTrackingArea(rect: self.titleBounds,
                                                   options: [.mouseEnteredAndExited, .activeInActiveApp, .inVisibleRect],
                                                   owner: self,
                                                   userInfo: nil)
        
        self.addTrackingArea(self.editableTrackingArea!)
        
        if let w = self.window, let e = NSApp.currentEvent {
            let mouseLocation = w.mouseLocationOutsideOfEventStream
            let convertedMouseLocation = self.convert(mouseLocation, from: nil)
            
            if NSPointInRect(convertedMouseLocation, self.bounds) {
                self.mouseEntered(with: e)
            }
            else {
                self.mouseExited(with: e)
            }
        }
    }
    
    open override func mouseEntered(with theEvent: NSEvent) {
        super.mouseEntered(with: theEvent)
        if self.editable_source != nil {
            self.editButton?.isHidden = self.isEditing
            self.startEditing()
        }
    }
    
    open override func mouseExited(with theEvent: NSEvent) {
        super.mouseExited(with: theEvent)
        if self.editable_source != nil {
            self.editButton?.isHidden = true
            if case .text = self.editable_source! {} // Do not cancel editing when .text case
            else { self.stopEditing() }
        }
    }

    override open func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        if self.editable_source != nil {
            self.startEditing()
        }
    }
    
    func setupAsLabel() {
        self.frame = self.originalFrame!
        self.drawsBackground = false
        self.isBezeled = false
        
        self.reallyAcceptsFirstResponder = false
        self.window?.resignFirstResponder()
        
        guard let fieldEditor = self.window?.fieldEditor(true, for: self) else { return }
        self.endEditing(fieldEditor)
    }

    func setupAsTextField() {
        guard let fieldEditor = self.window?.fieldEditor(true, for: self) else { return }

        self.reallyAcceptsFirstResponder = true
        self.window?.makeFirstResponder(self)

        self.frame = self.bezeledFrame
        self.drawsBackground = true
        self.isBezeled = true
        
        self.cell?.select(withFrame: self.bounds,
                          in: self,
                          editor: fieldEditor,
                          delegate: nil,
                          start: 0,
                          length: 0)
        
        fieldEditor.drawsBackground = false
        fieldEditor.isHorizontallyResizable = true
        fieldEditor.isEditable = true
        
//        let editorSettings = self.style.titleEditorSettings()
//        fieldEditor.font = editorSettings.font
//        fieldEditor.alignment = editorSettings.alignment
//        fieldEditor.textColor = editorSettings.textColor
        
        // Replace content so that resizing is triggered
        fieldEditor.string = ""
        fieldEditor.insertText(self.editable_source!.stringValue)
        fieldEditor.selectAll(self)
    }

    
    @objc func startEditing() {
        guard let source = self.editable_source else {
            return
        }
        
        switch source {
        case .text(_):
            self.setupAsTextField()
            
        case .options(let options_source):
            let (selectedIndex, titles) = options_source()
            let popup = NSPopUpButton(frame: self.titleFrame.insetBy(dx: -20.0, dy: -4.0).offsetBy(dx: 10.0, dy: -2.0))
            popup.addItems(withTitles: titles)
            if selectedIndex >= 0 && selectedIndex < titles.count {
                popup.title = titles[selectedIndex]
                popup.selectItem(withTitle: titles[selectedIndex])
            }
            self.auxiliaryView = popup
            self.superview?.addSubview(popup)
//            let popcell = popup.cell as! NSPopUpButtonCell
//            popcell.performClick(withFrame: popup.frame, in: self.superview!)
        }
        
        self.editButton?.isHidden = true
        self.okButton?.isHidden = false
        self.cancelButton?.isHidden = false
        
        self.isEditing = true
    }

    @objc func stopEditing() {
        guard let source = self.editable_source else {
            return
        }
        
        if case .text = source {
            self.setupAsLabel()
        }

        self.auxiliaryView?.removeFromSuperview()
        self.isEditing = false
    }

    
    private var titleBounds: CGRect {
        get {
            guard let attrString = self.editableAttributedStringValue else { return CGRect.zero }
            var rect = self.bounds
            rect.size = attrString.size()
            return rect
        }
    }

    private var titleFrame: CGRect {
        get {
            guard let attrString = self.editableAttributedStringValue else { return CGRect.zero }
            var rect = self.frame
            rect.size = attrString.size()
            return rect
        }
    }

    public var editableAttributedStringValue: NSAttributedString? {
        get {
            guard let source = self.editable_source else { return nil }
            let attributes = self.attributedStringValue.attributes(at: 0, effectiveRange: nil)
            return NSAttributedString(string: source.stringValue, attributes: attributes)
        }
    }
    
    // MARK : - NSTextDelegate
    
    open override func textDidEndEditing(_ notification: Notification) {
        guard let fieldEditor = notification.object as? NSText else {
            assertionFailure("Expected field editor.")
            return
        }
        
        let newValue = fieldEditor.string ?? ""
        // TODO: Send new Value...
        
        self.stopEditing()
        self.window?.resignFirstResponder()
    }

}


internal extension NSImage {
    internal func imageWithTint(_ tint: NSColor) -> NSImage {
        var imageRect = NSZeroRect;
        imageRect.size = self.size;
        
        let highlightImage = NSImage(size: imageRect.size)
        
        highlightImage.lockFocus()
        
        self.draw(in: imageRect, from: NSZeroRect, operation: .sourceOver, fraction: 1.0)
        
        tint.set()
        NSRectFillUsingOperation(imageRect, .sourceAtop);
        
        highlightImage.unlockFocus()
        
        return highlightImage;
    }
}

//
//  KPCEditableField.swift
//  KPCEditableField
//
//  Created by Cédric Foellmi on 10/02/2017.
//  Copyright © 2017 onekiloparsec. All rights reserved.
//

import AppKit

public extension CGPoint {
    public func offsetBy(dx: CGFloat, dy: CGFloat) -> CGPoint {
        return CGPoint(x: self.x + dx, y: self.y + dy)
    }
}

public extension CGSize {
    public func extendedBy(dw: CGFloat, dh: CGFloat) -> CGSize {
        return CGSize(width: self.width + dw, height: self.height + dh)
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


open class EditableField: NSTextField {
    private var okButton: NSButton?
    private var cancelButton: NSButton?
    private var editButton: NSButton?
    private var editableTrackingArea: NSTrackingArea?

    public var showValidationButtons: Bool = true
    public var editable_source: EditableSource? 
    public private(set) var isEditing: Bool = false

    var reallyAcceptsFirstResponder: Bool = false
    override open var acceptsFirstResponder: Bool {
        get { return self.reallyAcceptsFirstResponder }
    }

    override open var isEditable: Bool {
        get { return self.editable_source != nil }
        set {}
    }
    
    open var bezeledOrigin: CGPoint {
        get { return self.frame.origin.offsetBy(dx: 3.0, dy: 0.0) }
    }

    open var bezeledSize: CGSize {
        get { return self.frame.size.extendedBy(dw: 0.0, dh: 4.0) }
    }
    
    override open func viewDidMoveToWindow() {
        self.backgroundColor = NSColor.white
        self.isBezeled = false
        self.drawsBackground = false
        
        self.okButton = NSButton.editableButton(type: .check, target: self, action: nil)
        self.okButton?.frame.origin = CGPoint(x: NSMaxX(self.titleFrame)+2.0, y: NSMinY(self.titleFrame)-2.0)
        
        self.cancelButton = NSButton.editableButton(type: .cancel, target: self, action: #selector(EditableField.cancelEditingField))
        self.cancelButton?.frame.origin = CGPoint(x: NSMaxX(self.okButton!.frame)+2.0, y: NSMinY(self.okButton!.frame))
        
        self.editButton = NSButton.editableButton(type: .pencil, target: self, action: #selector(EditableField.editField))
        self.editButton?.frame = self.okButton!.frame
        
        self.superview?.addSubview(self.okButton!)
        self.superview?.addSubview(self.cancelButton!)
        self.superview?.addSubview(self.editButton!)
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
        self.editButton?.isHidden = self.isEditing
    }
    
    open override func mouseExited(with theEvent: NSEvent) {
        super.mouseExited(with: theEvent)
        self.editButton?.isHidden = true
    }

    override open func mouseDown(with event: NSEvent) {
        if self.isEditable {
            self.reallyAcceptsFirstResponder = true
            super.mouseDown(with: event)
        }
    }
    
    override open func becomeFirstResponder() -> Bool {
        guard let source = self.editable_source else {
            return super.becomeFirstResponder()
        }
        
        switch source {
        case .text(_):
            self.setFrameOrigin(self.bezeledOrigin)
            self.setFrameSize(self.bezeledSize)
            self.drawsBackground = true
            self.isBezeled = true
            self.display()
            
        case .options(let options_source):
            let (selectedIndex, titles) = options_source()
            let popup = NSPopUpButton(frame: self.titleFrame.insetBy(dx: -20.0, dy: -4.0).offsetBy(dx: 15.0, dy: 0.0))
            popup.addItems(withTitles: titles)
            if selectedIndex >= 0 && selectedIndex < titles.count {
                popup.title = titles[selectedIndex]
                popup.selectItem(withTitle: titles[selectedIndex])
            }
            self.superview?.addSubview(popup)
            let popcell = popup.cell as! NSPopUpButtonCell
            popcell.performClick(withFrame: popup.frame, in: self.superview!)
        }
        
        self.editButton?.isHidden = true
        self.okButton?.isHidden = false
        self.cancelButton?.isHidden = false
        
        self.isEditing = true
        return true
    }
    
    override open func resignFirstResponder() -> Bool {
        guard self.editable_source != nil else {
            return super.resignFirstResponder()
        }

        self.isEditing = false
        return true
    }
    
    @objc func editField() {
        self.window?.makeFirstResponder(self)
    }

    @objc func cancelEditingField() {
        self.window?.makeFirstResponder(self.nextResponder)
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

    open override func draw(_ dirtyRect: NSRect) {
        guard let attrString = self.editableAttributedStringValue else {
            super.draw(dirtyRect)
            return
        }

        attrString.draw(in: self.titleBounds)
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

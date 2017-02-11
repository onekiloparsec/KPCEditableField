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


open class EditableField: NSTextField {
    public var showValidationButtons: Bool = true
    private var okButton: NSButton?
    private var cancelButton: NSButton?
    
    public var editable_source: EditableSource? 

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
        
        return true
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

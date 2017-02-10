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

public typealias EditableSource = () -> String

open class EditableField: NSTextField {
    public var editable_text: EditableSource?

    var reallyAcceptsFirstResponder: Bool = false
    override open var acceptsFirstResponder: Bool {
        get { return self.reallyAcceptsFirstResponder }
    }

    override open var isEditable: Bool {
        get { return self.editable_text != nil }
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
        // NSNotification...
        
        self.setFrameOrigin(self.bezeledOrigin)
        self.setFrameSize(self.bezeledSize)
        
        self.drawsBackground = true
        self.isBezeled = true
        self.display()
        
        return true
    }

    open override func draw(_ dirtyRect: NSRect) {
        if let string = self.editable_text?() {
            let nsstring = string as NSString
            let attributes = self.attributedStringValue.attributes(at: 0, effectiveRange: nil)
            nsstring.draw(in: self.bounds, withAttributes: attributes)
        }
    }
}

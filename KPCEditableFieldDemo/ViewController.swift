//
//  ViewController.swift
//  KPCEditableFieldDemo
//
//  Created by Cédric Foellmi on 10/02/2017.
//  Copyright © 2017 onekiloparsec. All rights reserved.
//

import Cocoa
import KPCEditableField

class ViewController: NSViewController {

    @IBOutlet weak var editableTextField: EditableField!
    @IBOutlet weak var editableOptions: EditableField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.editableTextField.editable_text = { return "model.name" }
        self.editableOptions.editable_options = {
            return ("title1", ["title0", "title1", "title2"])
        }
    }


}

